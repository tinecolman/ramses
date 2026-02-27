!################################################################
!################################################################
!################################################################ 
!################################################################
subroutine make_boundary_diffusion(ilevel,igroup)
  use amr_commons
  use hydro_commons
  use radiation_parameters
  use units_commons
  implicit none
  ! -------------------------------------------------------------------
  ! This routine set up boundary conditions for fine levels.
  ! -------------------------------------------------------------------
  integer,intent(IN)::ilevel,igroup
  integer::ibound,boundary_dir,idim,inbor
  integer::i,ncache,ivar,igrid,ngrid,ind,ht
  integer::iskip,iskip_ref,nx_loc,ix,iy,iz,igrp
  
#if NDUST>0  
  integer::idust
#endif
  real(dp)::sum_dust
  
  integer,dimension(1:8)::ind_ref
  integer,dimension(1:nvector),save::ind_grid,ind_grid_ref
  integer,dimension(1:nvector),save::ind_cell,ind_cell_ref

  real(dp)::dx,dx_loc,scale
  real(dp)::rosseland_ana
  real(dp),dimension(1:3)::skip_loc
  real(dp),dimension(1:twotondim,1:3)::xc
  real(dp),dimension(1:nvector,1:ndim),save::xx
  real(dp),dimension(1:nvector,1:nvar+3),save::uu
  real(dp)::dd,t2,t2r,cal_Teg,usquare,emag,erad_loc,eps,ekin,Cv,rho

#if USE_FLD==1
  real(dp)::scale_nH,scale_T2,scale_t,scale_v,scale_d,scale_l,scale_kappa
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
  scale_kappa=1/scale_l
#endif

  if(.not. simple_boundary)return

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
     ! Compute direction of reference neighbors
     boundary_dir=boundary_type(ibound)-10*(boundary_type(ibound)/10)
     if(boundary_dir==1)inbor=2

     if(boundary_dir==2)inbor=1
     if(boundary_dir==3)inbor=4
     if(boundary_dir==4)inbor=3
     if(boundary_dir==5)inbor=6
     if(boundary_dir==6)inbor=5

     ! Compute index of reference cells
     ! Zero flux
     if(boundary_type(ibound)== 1)ind_ref(1:8)=(/2,1,4,3,6,5,8,7/)
     if(boundary_type(ibound)== 2)ind_ref(1:8)=(/2,1,4,3,6,5,8,7/)
     if(boundary_type(ibound)== 3)ind_ref(1:8)=(/3,4,1,2,7,8,5,6/)
     if(boundary_type(ibound)== 4)ind_ref(1:8)=(/3,4,1,2,7,8,5,6/)
     if(boundary_type(ibound)== 5)ind_ref(1:8)=(/5,6,7,8,1,2,3,4/)
     if(boundary_type(ibound)== 6)ind_ref(1:8)=(/5,6,7,8,1,2,3,4/)
     ! Zero flux
     if(boundary_type(ibound)==11)ind_ref(1:8)=(/1,1,3,3,5,5,7,7/)
     if(boundary_type(ibound)==12)ind_ref(1:8)=(/2,2,4,4,6,6,8,8/)
     if(boundary_type(ibound)==13)ind_ref(1:8)=(/1,2,1,2,5,6,5,6/)
     if(boundary_type(ibound)==14)ind_ref(1:8)=(/3,4,3,4,7,8,7,8/)
     if(boundary_type(ibound)==15)ind_ref(1:8)=(/1,2,3,4,1,2,3,4/)
     if(boundary_type(ibound)==16)ind_ref(1:8)=(/5,6,7,8,5,6,7,8/)
     ! Imposed boundary
     if(boundary_type(ibound)==21)ind_ref(1:8)=(/1,1,3,3,5,5,7,7/)
     if(boundary_type(ibound)==22)ind_ref(1:8)=(/2,2,4,4,6,6,8,8/)
     if(boundary_type(ibound)==23)ind_ref(1:8)=(/1,2,1,2,5,6,5,6/)
     if(boundary_type(ibound)==24)ind_ref(1:8)=(/3,4,3,4,7,8,7,8/)
     if(boundary_type(ibound)==25)ind_ref(1:8)=(/1,2,3,4,1,2,3,4/)
     if(boundary_type(ibound)==26)ind_ref(1:8)=(/5,6,7,8,5,6,7,8/)

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

              ! Gather reference variables and  scatter to boundary region
              do i=1,ngrid
                 if(son(ind_cell(i)) == 0)then
                    uold(ind_cell(i),8+igroup)  = uold(ind_cell_ref(i),8+igroup)
                    unew(ind_cell(i),8+igroup)  = unew(ind_cell_ref(i),8+igroup)
                    unew(ind_cell(i),5)     = unew(ind_cell_ref(i),5)
                    unew(ind_cell(i),nvar+3)= unew(ind_cell_ref(i),5)
                    enew(ind_cell(i))       = unew(ind_cell_ref(i),8+igroup)
                    divu(ind_cell(i))       = divu(ind_cell_ref(i))
                    unew(ind_cell(i),2)     = unew(ind_cell_ref(i),2)
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
                    dd=max(uu(i,1),smallr)
                    
                    usquare=0.0_dp
                    do idim=1,ndim
                       usquare=usquare+(uu(i,idim+1)/uu(i,1))**2
                    end do
                    ! Compute total magnetic energy
                    emag = 0.0_dp
                    do ivar=1,3
                       emag = emag + 0.125_dp*(uu(i,5+ivar) + uu(i,nvar+ivar))**2
                    end do
                    ! Compute total non-thermal+radiative energy
                    erad_loc=0.0_dp
                    do igrp=1,nener
                       erad_loc=erad_loc+uu(i,8+igrp)
                    enddo

                    rho   = uu(i,1)
                    ekin  = rho*usquare*0.5_dp
                    eps   = (uu(i,5)-ekin-emag-erad_loc)
                    sum_dust =0.0d0
#if NDUST>0
                    do idust = 1, ndust
                       sum_dust = sum_dust + uu(i,firstindex_ndust+idust)/rho
                    end do
#endif           
                    call temperature_eos((1.0d0-sum_dust)*rho,eps,t2,ht)                    
!                     t2    = Tr_floor ! comment this for radiative shock

                    unew(ind_cell(i),nvar+3) = t2
                    unew(ind_cell(i),5)      = t2
                    
                    uold(ind_cell(i),firstindex_er+igroup)= uu(i,firstindex_er+igroup)*scale_d*scale_v**2/(scale_E0)
                    unew(ind_cell(i),firstindex_er+igroup)= uold(ind_cell(i),firstindex_er+igroup)
                    enew(ind_cell(i)         )= uold(ind_cell(i),firstindex_er+igroup)
                    unew(ind_cell(i),2       )= 0.0_dp
                    
                    ! Compute Rosseland opacity
                    t2r = cal_Teg(unew(ind_cell(i),firstindex_er+igroup)*scale_E0,igroup)
                    divu(ind_cell(i))= rosseland_ana(dd*scale_d,t2,t2r,igroup,.false.)/scale_kappa
                    if(divu(ind_cell(i))*dx_loc .lt. min_optical_depth) divu(ind_cell(i))=min_optical_depth/dx_loc
                    
                 end if
              end do
           end if
              
        end do
        ! End loop over cells
           
     end do
     ! End loop over grids

  end do
  ! End loop over boundaries


111 format('   Entering make_boundary_diffusion for level ',I2)

end subroutine make_boundary_diffusion

!################################################################
!################################################################
!################################################################ 
!################################################################

subroutine make_boundary_diffusion_tot(ilevel)
  use amr_commons,only:boundary,son,ncoarse,nbor,xg
  use hydro_commons
  use radiation_parameters
  use const
  use units_commons
  implicit none
  ! -------------------------------------------------------------------
  ! This routine set up boundary conditions for fine levels.
  ! -------------------------------------------------------------------
  integer,intent(IN)::ilevel
  integer::ibound,boundary_dir,idim,inbor,igroup,ht
  integer::i,ncache,ivar,igrid,ngrid,ind
  integer::iskip,iskip_ref,gdim,nx_loc,ix,iy,iz,igrp,irad
  integer,dimension(1:8)::ind_ref
  integer,dimension(1:nvector),save::ind_grid,ind_grid_ref
  integer,dimension(1:nvector),save::ind_cell,ind_cell_ref

  real(dp)::dx,dx_loc,scale
  real(dp)::rosseland_ana
  real(dp),dimension(1:3)::skip_loc
  real(dp),dimension(1:twotondim,1:3)::xc
  real(dp),dimension(1:nvector,1:ndim),save::xx
  real(dp),dimension(1:nvector,1:nvar+3),save::uu
  real(dp),dimension(1:nvector)::cond,relax
  real(dp)::dd,t2,t2r,cal_Teg,usquare,emag,erad_loc,eps,ekin,Cv,rho

#if NDUST>0
  integer::idust
#endif
  real(dp)::sum_dust
  
#if USE_FLD==1
  real(dp)::scale_nH,scale_T2,scale_t,scale_v,scale_d,scale_l,scale_kappa
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
  scale_kappa=1/scale_l
#endif

  If(.not. simple_boundary)return

  ! Mesh size at level ilevel
  dx=half**ilevel

  ! Rescaling factors
  nx_loc=(icoarse_max-icoarse_min+1)
  skip_loc=(/zero,zero,zero/)
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
     if(ndim>0)xc(ind,1)=(dble(ix)-half)*dx
     if(ndim>1)xc(ind,2)=(dble(iy)-half)*dx
     if(ndim>2)xc(ind,3)=(dble(iz)-half)*dx
  end do

  ! Loop over boundaries
  do ibound=1,nboundary
     ! Compute direction of reference neighbors
     boundary_dir=boundary_type(ibound)-10*(boundary_type(ibound)/10)
     if(boundary_dir==1)inbor=2

     if(boundary_dir==2)inbor=1
     if(boundary_dir==3)inbor=4
     if(boundary_dir==4)inbor=3
     if(boundary_dir==5)inbor=6
     if(boundary_dir==6)inbor=5

     ! Compute index of reference cells
     ! Zero flux
     if(boundary_type(ibound)== 1)ind_ref(1:8)=(/2,1,4,3,6,5,8,7/)
     if(boundary_type(ibound)== 2)ind_ref(1:8)=(/2,1,4,3,6,5,8,7/)
     if(boundary_type(ibound)== 3)ind_ref(1:8)=(/3,4,1,2,7,8,5,6/)
     if(boundary_type(ibound)== 4)ind_ref(1:8)=(/3,4,1,2,7,8,5,6/)
     if(boundary_type(ibound)== 5)ind_ref(1:8)=(/5,6,7,8,1,2,3,4/)
     if(boundary_type(ibound)== 6)ind_ref(1:8)=(/5,6,7,8,1,2,3,4/)
     ! Zero flux
     if(boundary_type(ibound)==11)ind_ref(1:8)=(/1,1,3,3,5,5,7,7/)
     if(boundary_type(ibound)==12)ind_ref(1:8)=(/2,2,4,4,6,6,8,8/)
     if(boundary_type(ibound)==13)ind_ref(1:8)=(/1,2,1,2,5,6,5,6/)
     if(boundary_type(ibound)==14)ind_ref(1:8)=(/3,4,3,4,7,8,7,8/)
     if(boundary_type(ibound)==15)ind_ref(1:8)=(/1,2,3,4,1,2,3,4/)
     if(boundary_type(ibound)==16)ind_ref(1:8)=(/5,6,7,8,5,6,7,8/)
     ! Imposed boundary
     if(boundary_type(ibound)==21)ind_ref(1:8)=(/1,1,3,3,5,5,7,7/)
     if(boundary_type(ibound)==22)ind_ref(1:8)=(/2,2,4,4,6,6,8,8/)
     if(boundary_type(ibound)==23)ind_ref(1:8)=(/1,2,1,2,5,6,5,6/)
     if(boundary_type(ibound)==24)ind_ref(1:8)=(/3,4,3,4,7,8,7,8/)
     if(boundary_type(ibound)==25)ind_ref(1:8)=(/1,2,3,4,1,2,3,4/)
     if(boundary_type(ibound)==26)ind_ref(1:8)=(/5,6,7,8,5,6,7,8/)

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

              ! Gather reference variables and  scatter to boundary region
              do i=1,ngrid
                 if(son(ind_cell(i)) == 0)then
#if USE_FLD==1
                    do igroup=1,ngrp
                       kappaR_bicg(ind_cell(i),igroup)       = kappaR_bicg(ind_cell_ref(i),igroup)
                    enddo
#endif
                    do irad=1,nvar_trad
                       unew    (ind_cell(i),ind_trad(irad)) = unew    (ind_cell_ref(i),ind_trad(irad))
                       uold    (ind_cell(i),ind_trad(irad)) = uold    (ind_cell_ref(i),ind_trad(irad))
                    enddo
                    do irad = 1,nvar_bicg
                       if(bicg_to_cg) var_bicg(ind_cell(i),irad, 2) = var_bicg(ind_cell_ref(i),irad, 2)
                       var_bicg(ind_cell(i),irad, 5) = var_bicg(ind_cell_ref(i),irad, 5)
                       if(.not.bicg_to_cg) var_bicg(ind_cell(i),irad, 6) = var_bicg(ind_cell_ref(i),irad, 6)
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
                    dd=max(uu(i,1),smallr)

                    usquare=zero
                    do idim=1,ndim
                       usquare=usquare+(uu(i,idim+1)/uu(i,1))**2
                    end do
                    ! Compute total magnetic energy
                    emag = zero
                    do ivar=1,3
                       emag = emag + 0.125_dp*(uu(i,5+ivar) + uu(i,nvar+ivar))**2
                    end do
                    ! Compute total non-thermal+radiative energy
                    erad_loc=zero
                    do igrp=1,nener
                       erad_loc=erad_loc+uu(i,8+igrp)
                    enddo

                    rho   = uu(i,1)
                    ekin  = rho*usquare*half
                    eps   = (uu(i,5)-ekin-emag-erad_loc)

                    sum_dust =0.0d0
#if NDUST>0
                    do idust = 1, ndust
                       sum_dust = sum_dust + uu(i,firstindex_ndust+idust)/rho
                    end do
#endif       
                    call temperature_eos((1.0_dp-sum_dust)*rho,eps,t2,ht)
                    
#if NGRP>0
                    uu(i,ind_trad(1)) = t2
!                    uu(i,ind_trad(1)) = Tr_floor ! comment this for radiative shock
#endif

#if USE_FLD==1
                    ! Compute Rosseland opacity
                    do igroup=1,ngrp
                       t2r = cal_Teg(uu(i,firstindex_er+igroup)*scale_d*scale_v**2,igroup)
                       kappaR_bicg(ind_cell(i),igroup)= rosseland_ana(dd*scale_d,uu(i,ind_trad(1)),t2r,igroup,.false.)/scale_kappa
                       if( kappaR_bicg(ind_cell(i),igroup)*dx_loc .lt. min_optical_depth)  kappaR_bicg(ind_cell(i),igroup)=min_optical_depth/dx_loc
                    enddo
#endif
                    do irad=1,nvar_trad
                       uold(ind_cell(i),ind_trad(irad)) = uu(i,ind_trad(irad)) / norm_trad(irad)
                       unew(ind_cell(i),ind_trad(irad)) = uold(ind_cell(i),ind_trad(irad))
                    enddo

                   do irad = 1,nvar_bicg
                      if(bicg_to_cg) var_bicg(ind_cell(i),irad, 2) = zero
                      var_bicg(ind_cell(i),irad, 5) = zero
                      if(.not.bicg_to_cg) var_bicg(ind_cell(i),irad, 6) = zero
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


111 format('   Entering make_boundary_diffusion for level ',I2)

end subroutine make_boundary_diffusion_tot
!#############################################################################
!#############################################################################
!#############################################################################
#if USE_FLD==1
subroutine rad_force_fine(ilevel)
  use amr_commons
  use hydro_commons
  use cooling_module,ONLY:kB,mH
  use constants, only : c_cgs
  use radiation_parameters,ONLY:Tr_floor,eray_min,nu_min_hz,nu_max_hz,frad
  use const
  use units_commons
  implicit none
#ifndef WITHOUTMPI
  include 'mpif.h'
#endif
  integer::ilevel
  !--------------------------------------------------------------------------
  ! This routine sets array uold to its new value unew after the
  ! hydro step.
  !--------------------------------------------------------------------------
  integer::i,j,k,ivar,ind,iskip,nx_loc,info
  real(dp)::scale,d,u,v,w,A,B,C,d_old
  real(dp)::e_mag,e_kin,e_cons,e_prim,e_trunc,div,dx,fact,e_r

  integer ,dimension(1:nvector),save::ind_grid,ind_cell
  integer ,dimension(1:nvector,0:twondim),save::igridn
  integer ,dimension(1:nvector,1:ndim),save::ind_left,ind_right
  real(dp),dimension(1:nvector,1:ndim,1:ngrp),save::Erg,Erd
  real(dp),dimension(1:nvector,1:ndim,1:ndim),save::velg,veld
  real(dp),dimension(1:nvector,1:ndim)::dx_g,dx_d
  real(dp)::rosseland_ana
  real(dp)::Pgdivu,u_square,d_loc,Tp_loc,Tr_loc,cal_Teg

  integer::ncache,igrid,ngrid,idim,id1,ig1,ih1,id2,ig2,ih2,igroup
  integer  ,dimension(1:3,1:2,1:8)::iii,jjj
  real(dp)::dx_loc,surf_loc,vol_loc,usquare,emag,erad_loc,ekin,eps,cv,pp_eos
  real(dp)::kappa_R,gradEr_norm,gradEr_norm2,R,lambda,lambda_fld,chi,PgmErdivu,gradEru
  real(dp) ,dimension(1:3)::skip_loc
  real(dp) ,dimension(1:ndim,1:ngrp)::gradEr
  real(dp) ,dimension(1:ndim,1:ndim)::divu_loc
  real(dp) ,dimension(1:ndim,1:ndim,1:ngrp)::Pg
  real(dp) ,dimension(1:ndim       )::u_loc
  real(dp) :: nuPrDivu,nuPr,nuPl,Pr_nu
  real(dp), dimension(1:5) :: Pr_temp

  !  EOS
  real(dp) :: dd,ee,cmp_Cv_eos
  integer  :: ht 

#if USE_FLD==1
  real(dp)::scale_nH,scale_T2,scale_t,scale_v,scale_d,scale_l,scale_kappa
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
  scale_kappa=1/scale_l
#endif

  if(numbtot(1,ilevel)==0)return
  if(verbose)write(*,111)ilevel

  nx_loc=icoarse_max-icoarse_min+1
  scale=boxlen/dble(nx_loc)
  dx=0.5d0**ilevel

  skip_loc=(/0.0d0,0.0d0,0.0d0/)
  if(ndim>0)skip_loc(1)=dble(icoarse_min)
  if(ndim>1)skip_loc(2)=dble(jcoarse_min)
  if(ndim>2)skip_loc(3)=dble(kcoarse_min)
  scale=boxlen/dble(nx_loc)
  dx_loc=dx*scale ! Warning: scale factor already done in dx
  vol_loc=dx_loc**ndim
  surf_loc=dx_loc**(ndim-1)

  iii(1,1,1:8)=(/1,0,1,0,1,0,1,0/); jjj(1,1,1:8)=(/2,1,4,3,6,5,8,7/)
  iii(1,2,1:8)=(/0,2,0,2,0,2,0,2/); jjj(1,2,1:8)=(/2,1,4,3,6,5,8,7/)
  iii(2,1,1:8)=(/3,3,0,0,3,3,0,0/); jjj(2,1,1:8)=(/3,4,1,2,7,8,5,6/)
  iii(2,2,1:8)=(/0,0,4,4,0,0,4,4/); jjj(2,2,1:8)=(/3,4,1,2,7,8,5,6/)
  iii(3,1,1:8)=(/5,5,5,5,0,0,0,0/); jjj(3,1,1:8)=(/5,6,7,8,1,2,3,4/)
  iii(3,2,1:8)=(/0,0,0,0,6,6,6,6/); jjj(3,2,1:8)=(/5,6,7,8,1,2,3,4/)

if(fld)then    
  ! Loop over myid grids by vector sweeps
  ncache=active(ilevel)%ngrid
  do igrid=1,ncache,nvector   
     ! Gather nvector grids
     ngrid=MIN(nvector,ncache-igrid+1)
     do i=1,ngrid
        ind_grid(i)=active(ilevel)%igrid(igrid+i-1)
     end do
     
     ! Gather neighboring grids
     do i=1,ngrid
        igridn(i,0)=ind_grid(i)
     end do
     do idim=1,ndim
        do i=1,ngrid
           ind_left (i,idim)=nbor(ind_grid(i),2*idim-1)
           ind_right(i,idim)=nbor(ind_grid(i),2*idim  )
           igridn(i,2*idim-1)=son(ind_left (i,idim))
           igridn(i,2*idim  )=son(ind_right(i,idim))
        end do
     end do

     
     ! Loop over cells
     do ind=1,twotondim
        
        ! Compute central cell index
        iskip=ncoarse+(ind-1)*ngridmax
        do i=1,ngrid
           ind_cell(i)=iskip+ind_grid(i)
        end do
        
#if USE_FLD==1        
        ! Gather neighboring temperature
        do idim=1,ndim
           id1=jjj(idim,1,ind); ig1=iii(idim,1,ind)
           ih1=ncoarse+(id1-1)*ngridmax
           do i=1,ngrid
              if(igridn(i,ig1)>0)then
                 do igroup=1,ngrp
                    Erg(i,idim,igroup) = max(uold(igridn(i,ig1)+ih1,firstindex_er+igroup),eray_min/(scale_d*scale_v**2))
                 end do
                 velg(i,idim,1:ndim) = uold(igridn(i,ig1)+ih1,2:ndim+1)/uold(igridn(i,ig1)+ih1,1)
                 dx_g(i,idim) = dx_loc
              else
                 do igroup=1,ngrp
                    Erg(i,idim,igroup) = max(uold(ind_left(i,idim),firstindex_er+igroup),eray_min/(scale_d*scale_v**2))
                 end do
                 velg(i,idim,1:ndim) = uold(ind_left(i,idim),2:ndim+1)/uold(ind_left(i,idim),1)
                 dx_g(i,idim) = dx_loc*1.5_dp
              end if
           enddo
           id2=jjj(idim,2,ind); ig2=iii(idim,2,ind)
           ih2=ncoarse+(id2-1)*ngridmax
           do i=1,ngrid
              if(igridn(i,ig2)>0)then
                 do igroup=1,ngrp
                    Erd(i,idim,igroup) = max(uold(igridn(i,ig2)+ih2,firstindex_er+igroup),eray_min/(scale_d*scale_v**2))
                 end do
                 veld(i,idim,1:ndim)= uold(igridn(i,ig2)+ih2,2:ndim+1)/uold(igridn(i,ig2)+ih2,1)
                 dx_d(i,idim)=dx_loc
              else 
                 do igroup=1,ngrp
                    Erd(i,idim,igroup) = max(uold(ind_right(i,idim),firstindex_er+igroup),eray_min/(scale_d*scale_v**2))
                 end do
                 veld(i,idim,1:ndim)= uold(ind_right(i,idim),2:ndim+1)/uold(ind_right(i,idim),1)
                 dx_d(i,idim)=dx_loc*1.5_dp
              end if
           enddo
        end do
       ! End loop over dimensions
  
        do i=1,ngrid
           !compute divu
           do j=1,ndim
              do k=1,ndim
                 divu_loc(j,k) = (veld(i,j,k)-velg(i,j,k))/(dx_g(i,j)+dx_d(i,j))
              enddo
              do igroup=1,ngrp
                 gradEr(j,igroup) = (Erd(i,j,igroup)-Erg(i,j,igroup))/(dx_g(i,j)+dx_d(i,j))
              enddo
           enddo

           d_loc = uold(ind_cell(i),1)*scale_d
           u_loc(1:ndim) = uold(ind_cell(i),2:ndim+1)/uold(ind_cell(i),1)
           
           usquare=0.0
           do idim=1,ndim
              usquare=usquare+(uold(ind_cell(i),idim+1)/uold(ind_cell(i),1))**2
           end do
           
           ! Compute total magnetic energy
           emag = 0.0d0
           do ivar=1,3
              emag = emag + 0.125d0*(uold(ind_cell(i),5+ivar) &
                   &  +uold(ind_cell(i),nvar+ivar))**2
           end do
           erad_loc=0.0D0
#if NENER>0
           do igroup=1,nener
              erad_loc = erad_loc + uold(ind_cell(i),8+igroup)
           end do
#endif
           d     = uold(ind_cell(i),1)
           ekin  = d*usquare/2.0
           ! Compute gas temperature in cgs
           eps   = uold(ind_cell(i),5)-ekin-emag-erad_loc
           !if(energy_fix)eps   = uold(ind_cell(i),nvar) ! comment this for radiative shock
           ! Compute gas temperature in cgs
           call temperature_eos(d,eps,Tp_loc,ht)

           frad(ind_cell(i),1:ndim)=0.0d0
           
           ! Compute radiative pressure in all groups
           do igroup=1,ngrp
              
              ! Compute radiative pressure
              Tr_loc = cal_Teg(uold(ind_cell(i),firstindex_er+igroup)*scale_d*scale_v**2,igroup)              
              kappa_R = rosseland_ana(d_loc,Tp_loc,Tr_loc,igroup,in_sink(ind_cell(i)))/scale_kappa
              gradEr_norm2 = (sum(gradEr(1:ndim,igroup)**2))
              gradEr_norm  = (gradEr_norm2)**0.5
              R =   max(1.d-10,gradEr_norm/(max(uold(ind_cell(i),firstindex_er+igroup),eray_min/(scale_d*scale_v**2))*kappa_R))
              lambda = lambda_fld(R)
              chi = lambda + (lambda*R)**2
              
              frad(ind_cell(i),1:ndim) =  frad(ind_cell(i),1:ndim) + lambda*gradEr(1:ndim,igroup)/d
           enddo !end loop over rad groups

        end do
#endif
#if USE_M_1==1
        do i=1,ngrid
           ! Compute density and temperature for opacity
           d_loc = uold(ind_cell(i),1)*scale_d
           
           usquare=zero
           do idim=1,ndim
              usquare=usquare+(uold(ind_cell(i),idim+1)/uold(ind_cell(i),1))**2
           end do

           emag = zero
           do ivar=1,3
              emag = emag + 0.125d0*(uold(ind_cell(i),5+ivar) &
                   &  +uold(ind_cell(i),nvar+ivar))**2
           end do
           erad_loc=zero
#if NENER>0
           do igroup=1,nener
              erad_loc = erad_loc + uold(ind_cell(i),8+igroup)
           end do
#endif
           d     = uold(ind_cell(i),1)
           ekin  = d*usquare/2.0
           ! Compute gas temperature in cgs
           eps   = uold(ind_cell(i),5)-ekin-emag-erad_loc
           call temperature_eos(d,eps,Tp_loc,ht)

           frad(ind_cell(i),1:ndim)=zero

           do igroup=1,ngrp

              Tr_loc = cal_Teg(uold(ind_cell(i),firstindex_er+igroup)*scale_d*scale_v**2,igroup)
              kappa_R = rosseland_ana(d_loc,Tp_loc,Tr_loc,igroup,in_sink(ind_cell(i)))/scale_kappa

              ! divide by d because equation over u and not d*u
              frad(ind_cell(i),1) =  frad(ind_cell(i),1) + kappa_R*uold(ind_cell(i),firstindex_fr+igroup)/(c_cgs/scale_v)/d
              frad(ind_cell(i),2) =  frad(ind_cell(i),2) + kappa_R*uold(ind_cell(i),firstindex_fr+igroup+ngrp)/(c_cgs/scale_v)/d
              frad(ind_cell(i),3) =  frad(ind_cell(i),3) + kappa_R*uold(ind_cell(i),firstindex_fr+igroup+2*ngrp)/(c_cgs/scale_v)/d

           enddo !end loop over rad groups
        enddo
#endif

     enddo
     ! End loop over cells
  end do
  ! End loop over grids
endif
  
111 format('   Entering rad_force_fine for level ',i2)

end subroutine rad_force_fine
#endif