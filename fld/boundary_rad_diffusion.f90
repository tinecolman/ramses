subroutine make_boundary_diffusion_tot(ilevel)
   use amr_commons
   use hydro_parameters, only:nhydro,nvar_all,smallr
   use hydro_commons,    only:uold,unew
   use fld_parameters
   use fld_commons
   implicit none
   integer,intent(IN)::ilevel
   ! -------------------------------------------------------------------
   ! This routine set up boundary conditions for fine levels.
   ! -------------------------------------------------------------------
   integer::ibound,boundary_dir,idim,inbor=1
   integer::i,ncache,igroup,igrid,ngrid,ind
   integer::iskip,iskip_ref,nx_loc,ix,iy,iz
   integer,dimension(1:8)::ind_ref
   integer,dimension(1:nvector),save::ind_grid,ind_grid_ref
   integer,dimension(1:nvector),save::ind_cell,ind_cell_ref

   real(dp)::dx,dx_loc,scale
   real(dp)::rosseland_ana
   real(dp),dimension(1:3)::skip_loc
   real(dp),dimension(1:twotondim,1:3)::xc
   real(dp),dimension(1:nvector,1:ndim),save::xx
   real(dp),dimension(1:nvector,1:nvar_all),save::uu
   real(dp)::dd,t2,eps
   real(dp)::scale_nH,scale_T2,scale_t,scale_v,scale_d,scale_l,scale_kappa

   If(.not. simple_boundary)return
   if(verbose)write(*,111)ilevel

   call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
   scale_kappa=1d0/scale_l

   ! Mesh size at level ilevel
   dx=0.5D0**ilevel

   ! Rescaling factors
   nx_loc=(icoarse_max-icoarse_min+1)
   skip_loc=(/0.0d0,0.0d0,0.0d0/)
   if(ndim>0)skip_loc(1)=dble(icoarse_min)
   if(ndim>1)skip_loc(2)=dble(jcoarse_min)
   if(ndim>2)skip_loc(3)=dble(kcoarse_min)
   scale=boxlen/dble(nx_loc)
   dx_loc=dx*scale

   ! Set position of cell centers relative to grid center
   do ind=1,twotondim
      iz=(ind-1)/4
      iy=(ind-1-4*iz)/2
      ix=(ind-1-2*iy-4*iz)
      if(ndim>0)xc(ind,1)=(dble(ix)-0.5D0)*dx
      if(ndim>1)xc(ind,2)=(dble(iy)-0.5D0)*dx
      if(ndim>2)xc(ind,3)=(dble(iz)-0.5D0)*dx
   end do

   ! Loop over boundaries
   do ibound=1,nboundary

      call set_boundary_references(ibound,ind_ref,boundary_dir,inbor)

      ! TC: sign switch for reflexive boundaries missing?

      ! Loop over grids by vector sweeps
      ncache=boundary(ibound,ilevel)%ngrid
      do igrid=1,ncache,nvector
         ngrid=MIN(nvector,ncache-igrid+1)
         do i=1,ngrid
            ind_grid(i)=boundary(ibound,ilevel)%igrid(igrid+i-1)
         end do

         ! Gather neighboring reference grid
         do i=1,ngrid
            ind_grid_ref(i)=son(nbor(ind_grid(i),inbor))
         end do

         ! Loop over cells
         do ind=1,twotondim
            iskip=ncoarse+(ind-1)*ngridmax
            do i=1,ngrid
               ind_cell(i)=iskip+ind_grid(i)
            end do

            ! Gather neighboring reference cell
            iskip_ref=ncoarse+(ind_ref(ind)-1)*ngridmax
            do i=1,ngrid
               ind_cell_ref(i)=iskip_ref+ind_grid_ref(i)
            end do

            ! Zero flux boundary conditions
            if((boundary_type(ibound)/10).ne.2)then

               ! scatter reference variables to boundary region
               do i=1,ngrid
                  if(son(ind_cell(i)) == 0)then !TC: why only for son? In boundary_potential this check isn't there

                     do igroup=1,ngrp
                        kappaR_bicg(ind_cell(i),igroup) = kappaR_bicg(ind_cell_ref(i),igroup)
                     enddo

                     temperature_array_new(ind_cell(i)) = temperature_array_new(ind_cell_ref(i)) !TC: this is probably not up to date?
                     temperature_array_old(ind_cell(i)) = temperature_array_old(ind_cell_ref(i)) !TC: this is probably not up to date?
                     ! TC: why needed? Shouldn't this be handled by hydro boundary?
                     do igroup=1,ngrp
                        unew(ind_cell(i),nhydro+igroup) = unew(ind_cell_ref(i),nhydro+igroup)
                        uold(ind_cell(i),nhydro+igroup) = uold(ind_cell_ref(i),nhydro+igroup)
                     enddo

                     do igroup = 1,ngrp
                        if(bicg_to_cg)then
                           var_bicg(ind_cell(i),igroup, 2) = var_bicg(ind_cell_ref(i),igroup, 2)
                        else
                           var_bicg(ind_cell(i),igroup, 6) = var_bicg(ind_cell_ref(i),igroup, 6)
                        endif
                        var_bicg(ind_cell(i),igroup, 5) = var_bicg(ind_cell_ref(i),igroup, 5)
                     enddo

                  end if
               end do

               ! Imposed boundary conditions
            else

               ! Compute cell center in code units and rescale position from code units to user units
               do idim=1,ndim
                  do i=1,ngrid
                     if(son(ind_cell(i)) == 0)then
                        xx(i,idim)=(xg(ind_grid(i),idim)+xc(ind,idim)-skip_loc(idim))*scale
                     end if
                  end do
               end do

               call boundana(xx,uu,dx_loc,ibound,ngrid)

               ! Scatter variables
               do i=1,ngrid 
                  if(son(ind_cell(i)) == 0)then

                     ! Compute internal energy from total energy
                     call compute_internal_energy(uu(i,1:nvar_all),eps)

                     ! Compute gas temperature in Kelvin
                     call internal_energy_to_temperature(uu(i,1),eps,t2)

                     ! Compute Rosseland opacity
                     dd=max(uu(i,1),smallr)
                     do igroup=1,ngrp
                        kappaR_bicg(ind_cell(i),igroup)= rosseland_ana(dd*scale_d,t2,igroup)/scale_kappa
                        if( kappaR_bicg(ind_cell(i),igroup)*dx_loc .lt. min_optical_depth)  kappaR_bicg(ind_cell(i),igroup)=min_optical_depth/dx_loc
                     enddo

                     temperature_array_old(ind_cell(i)) = t2 / Tr_floor
                     temperature_array_new(ind_cell(i)) = temperature_array_old(ind_cell(i))
                     do igroup=1,ngrp
                        uold(ind_cell(i),nhydro+igroup) = uu(i,nhydro+igroup) / P_cal
                        unew(ind_cell(i),nhydro+igroup) = uold(ind_cell(i),nhydro+igroup)
                     enddo

                     ! TC: why set to 0?
                     do igroup=1,ngrp
                        if(bicg_to_cg)then
                           var_bicg(ind_cell(i),igroup, 2) = 0
                        else
                           var_bicg(ind_cell(i),igroup, 6) = 0
                        endif
                        var_bicg(ind_cell(i),igroup, 5) = 0
                     enddo

                  end if
               end do

            end if

         end do
         ! End loop over cells
      end do
      ! End loop over grids
   end do
   ! End loop over boundaries

111 format('   Entering make_boundary_diffusion_tot for level ',I2)

end subroutine make_boundary_diffusion_tot
