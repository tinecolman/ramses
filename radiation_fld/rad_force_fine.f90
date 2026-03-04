subroutine rad_force_fine(ilevel)
   use amr_commons
   use hydro_commons
   use constants,      only: c_cgs,kB,mH
   use fld_parameters, only: eray_min
   use fld_commons,    only:frad
   use mpi_mod
   implicit none
   integer::ilevel
   !--------------------------------------------------------------------------
   ! Calculate the radiative force
   !--------------------------------------------------------------------------
   integer::i,j,k,ivar,ind,iskip,nx_loc
   real(dp)::scale,d,u
   real(dp)::dx

   integer ,dimension(1:nvector),save::ind_grid,ind_cell
   integer ,dimension(1:nvector,0:twondim),save::igridn
   integer ,dimension(1:nvector,1:ndim),save::ind_left,ind_right
   real(dp),dimension(1:nvector,1:ndim,1:ngrp),save::Erg,Erd
   real(dp),dimension(1:nvector,1:ndim)::dx_g,dx_d
   real(dp)::rosseland_ana
   real(dp)::Tp_loc,Tr_loc,cal_Teg,eray_min_cu

   integer::ncache,igrid,ngrid,idim,id1,ig1,ih1,id2,ig2,ih2,igroup
   integer  ,dimension(1:3,1:2,1:8)::iii,jjj
   real(dp)::dx_loc,usquare,emag,erad_loc,ekin,eps
   real(dp)::kappa_R,gradEr_norm,gradEr_norm2,R,lambda,lambda_fld,chi
   real(dp) ,dimension(1:ndim,1:ngrp)::gradEr

   real(dp)::scale_nH,scale_T2,scale_t,scale_v,scale_d,scale_l,scale_kappa
   call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
   scale_kappa=1d0/scale_l
   eray_min_cu = eray_min/(scale_d*scale_v**2)

   if(numbtot(1,ilevel)==0)return
   if(verbose)write(*,111)ilevel

   dx=0.5d0**ilevel
   nx_loc=icoarse_max-icoarse_min+1
   scale=boxlen/dble(nx_loc)
   dx_loc=dx*scale

   iii(1,1,1:8)=(/1,0,1,0,1,0,1,0/); jjj(1,1,1:8)=(/2,1,4,3,6,5,8,7/)
   iii(1,2,1:8)=(/0,2,0,2,0,2,0,2/); jjj(1,2,1:8)=(/2,1,4,3,6,5,8,7/)
   iii(2,1,1:8)=(/3,3,0,0,3,3,0,0/); jjj(2,1,1:8)=(/3,4,1,2,7,8,5,6/)
   iii(2,2,1:8)=(/0,0,4,4,0,0,4,4/); jjj(2,2,1:8)=(/3,4,1,2,7,8,5,6/)
   iii(3,1,1:8)=(/5,5,5,5,0,0,0,0/); jjj(3,1,1:8)=(/5,6,7,8,1,2,3,4/)
   iii(3,2,1:8)=(/0,0,0,0,6,6,6,6/); jjj(3,2,1:8)=(/5,6,7,8,1,2,3,4/)

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

         ! Gather values of energy in neighboring cells (for gradient computation)
         do idim=1,ndim
            id1=jjj(idim,1,ind); ig1=iii(idim,1,ind)
            ih1=ncoarse+(id1-1)*ngridmax
            do i=1,ngrid
               if(igridn(i,ig1)>0)then
                  do igroup=1,ngrp
                     Erg(i,idim,igroup) = max(uold(igridn(i,ig1)+ih1,nhydro+igroup),eray_min_cu)
                  end do
                  dx_g(i,idim) = dx_loc
               else
                  do igroup=1,ngrp
                     Erg(i,idim,igroup) = max(uold(ind_left(i,idim),nhydro+igroup),eray_min_cu)
                  end do
                  dx_g(i,idim) = dx_loc*1.5_dp
               end if
            enddo
            id2=jjj(idim,2,ind); ig2=iii(idim,2,ind)
            ih2=ncoarse+(id2-1)*ngridmax
            do i=1,ngrid
               if(igridn(i,ig2)>0)then
                  do igroup=1,ngrp
                     Erd(i,idim,igroup) = max(uold(igridn(i,ig2)+ih2,nhydro+igroup),eray_min_cu)
                  end do
                  dx_d(i,idim)=dx_loc
               else 
                  do igroup=1,ngrp
                     Erd(i,idim,igroup) = max(uold(ind_right(i,idim),nhydro+igroup),eray_min_cu)
                  end do
                  dx_d(i,idim)=dx_loc*1.5_dp
               end if
            enddo
         end do
         ! End loop over dimensions

         do i=1,ngrid
            ! calculate gradient for current cell in each direction
            do j=1,ndim
               do igroup=1,ngrp
                  gradEr(j,igroup) = (Erd(i,j,igroup)-Erg(i,j,igroup))/(dx_g(i,j)+dx_d(i,j))
               enddo
            enddo
           
            d = uold(ind_cell(i),1)

            ! Compute internal energy from total energy
            call internal_energy_from_uold(uold(ind_cell(i),1:nvar_all),eps)

            ! Compute gas temperature in Kelvin
            call internal_energy_to_temperature(d,eps,Tp_loc)
           
            ! Compute radiative pressure in all groups
            frad(ind_cell(i),1:ndim)=0.0d0
            do igroup=1,ngrp
               kappa_R = rosseland_ana(d*scale_d,Tp_loc,igroup)/scale_kappa
               gradEr_norm2 = (sum(gradEr(1:ndim,igroup)**2))
               gradEr_norm  = (gradEr_norm2)**0.5
               R =   max(1.d-10,gradEr_norm/(max(uold(ind_cell(i),nhydro+igroup),eray_min_cu)*kappa_R))
               lambda = lambda_fld(R)
               chi = lambda + (lambda*R)**2
               
               frad(ind_cell(i),1:ndim) =  frad(ind_cell(i),1:ndim) + lambda*gradEr(1:ndim,igroup)/d
            end do !end loop over rad groups

         end do
      end do
     ! End loop over cells
  end do
  ! End loop over grids
  
111 format('   Entering rad_force_fine for level ',i2)

end subroutine rad_force_fine
!###########################################################
!###########################################################
!###########################################################
!###########################################################
function lambda_fld(R)
  use fld_parameters
  use const
  implicit none
  real(dp)::R,lambda_fld

  lambda_fld = one/three
  if(i_fld_limiter==i_fld_limiter_levermore) lambda_fld =(2.0d0+r)/(6.0d0+2.0d0*R+R**2)! (one/tanh(R)-one/R) / R
  if(i_fld_limiter==i_fld_limiter_minerbo) then 
     if(R .le. three/two) then
        lambda_fld = two/(three+sqrt(9d0+12.0_dp*R*R))
     else
        lambda_fld = one/(one + R + sqrt(one+two*R))
     end if
  end if
  return 
end function lambda_fld
