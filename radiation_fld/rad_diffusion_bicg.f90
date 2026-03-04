subroutine rad_diffusion_bicg (ilevel,Nsub)
  use amr_commons,    only: myid,numbtot,active,son,ncpu,reception,dtnew,ncoarse,nstep
  use amr_parameters, only: dp,verbose,ndim
  use hydro_commons
  use fld_parameters
  use fld_commons
  use const
  use constants, only: eV2erg,c_cgs
  use mpi_mod
  implicit none
  !=========================================================
  ! Iterative solver with Stabilised Bi-Conjugate Gradient method
  ! to solve A x = b
  !  i   : cell index
  !  irad: radiative variable index (from 1 to ngrp if FLD, from 1 to (1+ndim)*ngrp if M1)
  !
  !   r         : stored in var_bicg(i,irad,1)
  !   p         : stored in var_bicg(i,irad,2)
  !   v         : stored in var_bicg(i,irad,3)
  !   K^{-1}    : stored in var_bicg(i,irad,4)
  !   y         : stored in var_bicg(i,irad,5)
  !   z         : stored in var_bicg(i,irad,6)
  !   s         : stored in var_bicg(i,irad,7)
  !   t         : stored in var_bicg(i,irad,8) 
  !   rbar_0    : stored in var_bicg(i,irad,9)
  !   K^{-1}*t  : stored in var_bicg(i,irad,10)
  !
  !  radflux (cell_left ,idim=1)   : stored in var_bicg(i,irad,11)
  !  radflux (cell_right,idim=1)   : stored in var_bicg(i,irad,12)
  !  radflux (cell_left ,idim=2)   : stored in var_bicg(i,irad,13)
  !  radflux (cell_right,idim=2)   : stored in var_bicg(i,irad,14)
  !  radflux (cell_left ,idim=3)   : stored in var_bicg(i,irad,15)
  !  radflux (cell_right,idim=3)   : stored in var_bicg(i,irad,16)
  !
  !  new radiative energy at time n+1 : stored in unew(i,irad)
  !      radiative energy at time n   : stored in uold(i,irad)
  !
  !=========================================================
  integer,intent(IN)::ilevel,Nsub
  complex*16 :: final_sum
  real(dp)::error,error_ini
  real(dp)::Cv,told,rho,wdtB,wdtE,Tr,Trold,cal_Teg
  real(dp)::r2,rhs_norm1,r3
  real(dp)::temp,density,planck_ana,rosseland_ana
  integer::i,ind,iter,iskip,itermax,icpu,igroup,igrp,irad,jrad,ivar
  integer::this,nleaf_tot,icell
  real(dp)::radiation_source,deriv_radiation_source,rhs,lhs

  real(dp)::rho_bicg_new,rho_bicg_old,alpha_bicg,omega_bicg,beta_bicg,e_diff

  real(dp)::max_loc
#ifndef WITHOUTMPI
  integer::info,nleaf_all
  real(dp)::max_loc_all
#endif

  logical::exist_leaf_cell=.true.,debug_energy=.false.
  integer::nx_loc
  real(dp)::scale,dx,dx_loc
   real(dp)::scale_nH,scale_T2,scale_t,scale_v,scale_d,scale_l,scale_kappa,C_cal
   call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
   scale_kappa=1d0/scale_l
   C_cal = c_cgs/scale_v

  if(myid==1 .and. (mod(nstep,ncontrol)==0)) write(*,*) 'entering radiative transfer for level ',ilevel

  if(verbose)write(*,111)
  if(numbtot(1,ilevel)==0)return

  ! Rescaling factors
  ! Mesh size at level ilevel
  dx=half**ilevel
  nx_loc=(icoarse_max-icoarse_min+1)
  scale=boxlen/dble(nx_loc)
  dx_loc=dx*scale

  allocate(liste_ind (1:twotondim*active(ilevel)%ngrid))

  nb_ind = 0

  do ind=1,twotondim
     iskip=ncoarse+(ind-1)*ngridmax
     do i=1,active(ilevel)%ngrid
        if(son(active(ilevel)%igrid(i)+iskip) == 0)then
           nb_ind = nb_ind+1 
           liste_ind(nb_ind) = active(ilevel)%igrid(i)+iskip
        end if
     end do
  end do

  !===================================================================
  ! Begin of subcycles....
  !===================================================================
  dt_imp = dtnew(ilevel)

  if (nb_ind == 0)then
     !print*,'No leaf-cell - myid=',myid
     exist_leaf_cell=.false.
  end if

  nleaf_tot=nb_ind
#ifndef WITHOUTMPI
  call MPI_ALLREDUCE(nb_ind,nleaf_all,1,MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,info)
  nleaf_tot=nleaf_all
#endif
     
  if(nleaf_tot .eq. 0)then
     !write(*,*)'No leaf cells at level',ilevel,'. Exiting BiCG'
     deallocate(liste_ind)
     return
  end if

  ! TC: Set stuff to 0
  do i=1,nb_ind
     this = liste_ind(i)

     var_bicg(this,:,:)=0
     if(block_diagonal_precond_bicg)then
        precond_bicg(this,:,:)=0
     endif

     do irad=1,ngrp
        unew(this,nhydro+irad)=0
     enddo
     kappaR_bicg(this,:)=0
  end do

  !===================================================================
  ! Compute gas temperature stored in uold(i,nvar) and in unew(i,nvar)
  !===================================================================
  ! TC: update uold and unew
  !call cmp_energy(1)
   do i=1,nb_ind
      icell = liste_ind(i)
      do irad=1,ngrp
         uold(icell,nhydro+irad)=uold(icell,nhydro+irad)/P_cal
         uold(icell,nhydro+irad)=max(uold(icell,nhydro+irad),eray_min/scale_E0)
         unew(icell,nhydro+irad)=uold(icell,nhydro+irad)
      enddo
   end do


  do i=1,nb_ind
     this = liste_ind(i)

     density = scale_d * max(uold(this,1),smallr)
     temp = uold(this,nvar)*Tr_floor

     ! Compute Rosseland opacity (Compute kappa*rho)
     do igroup=1,ngrp
        kappaR_bicg(this,igroup)= rosseland_ana(density,temp,igroup) / scale_kappa
        if(kappaR_bicg(this,igroup)*dx_loc .lt. min_optical_depth) then
          kappaR_bicg(this,igroup)=min_optical_depth/dx_loc
        endif
     enddo
  end do

  ! Update boundaries
  call make_virtual_fine_dp(uold(1,nvar),ilevel)
  call make_virtual_fine_dp(unew(1,nvar),ilevel)
  do igrp=1,ngrp
     call make_virtual_fine_dp(kappaR_bicg(1,igrp),ilevel)
  enddo

  call make_virtual_fine_dp(uold(1,5),ilevel)
  call make_virtual_fine_dp(unew(1,5),ilevel)
  do irad=1,ngrp
     call make_virtual_fine_dp(uold(1,nhydro+irad),ilevel)
     call make_virtual_fine_dp(unew(1,nhydro+irad),ilevel)

     do ivar=1,10+2*ndim
        call make_virtual_fine_dp(var_bicg(:,irad,ivar),ilevel)
     enddo

     if(block_diagonal_precond_bicg) then
        do ivar=1,ngrp
           call make_virtual_fine_dp(precond_bicg(:,irad,ivar),ilevel)
        enddo
     endif
  enddo

  call make_boundary_diffusion_tot(ilevel)

  !===========================================
  ! Compute the matrix and vector coefficients
  !===========================================
  call cmp_matrix_and_vector_coeff_fld(ilevel)

  !==============================================
  ! Update preconditionner M=1/diag(A) boundaries
  !==============================================
  do irad=1,ngrp
     if(block_diagonal_precond_bicg) then
        do i=1,ngrp
           call make_virtual_fine_dp(precond_bicg(:,irad,i),ilevel)
        enddo
     else
        call make_virtual_fine_dp(var_bicg(:,irad,4),ilevel)
     endif
  enddo

  !==================================================================
  ! Compute r1 = b1 - A1x1 and store it into var_bicg(1:ncell,irad,1)
  !==================================================================
  call cmp_matrix_vector_product(ilevel,1)
  if(bicg_to_cg)then
     do irad=1,ngrp
        do i=1,nb_ind
           this = liste_ind(i)
           var_bicg(this,irad,2) = var_bicg(this,irad,1)
        enddo
     enddo
  endif
  do irad=1,ngrp
     call make_virtual_fine_dp(var_bicg(:,irad,1),ilevel)
     call make_virtual_fine_dp(var_bicg(:,irad,2),ilevel)
  enddo

  if(.not.bicg_to_cg) then
     !=========================================================================
     ! BiCGSTAB: Compute rbar_0 = r1 and store it into var_bicg(1:ncell,irad,9)
     !=========================================================================
     do irad=1,ngrp
        do i=1,nb_ind
           this = liste_ind(i)
           var_bicg(this,irad,9) = var_bicg(this,irad,1)
        enddo
     enddo
  endif

    rho_bicg_old = one
    rho_bicg_new = one
  alpha_bicg     = one
  omega_bicg     = one
  if(bicg_to_cg) omega_bicg=zero

  !================================================================
  ! All     : Set v0 = 0 and store it into var_bicg(1:ncell,irad,3)
  ! BiCGSTAB: Set p0 = 0 and store it into var_bicg(1:ncell,irad,2)
  !================================================================
  do irad=1,ngrp
     do i=1,nb_ind
        this = liste_ind(i)
        if(.not.bicg_to_cg) then 
         var_bicg(this,irad,2) = zero
        endif
        var_bicg(this,irad,3) = zero
     enddo
  enddo

  !=============================
  ! Compute right-hand side norm
  !=============================
  call dot_product_tot(var_bicg(:,:,1),var_bicg(:,:,1),rhs_norm1,final_sum)
 
  !============================================================
  ! Compute z_0 = K^{-1} r and store it into var_bicg(i,irad,6)
  !============================================================
  if(bicg_to_cg)then!neilneil
     do irad=1,ngrp
        do i=1,nb_ind
           this = liste_ind(i)
           if(block_diagonal_precond_bicg) then
              var_bicg(this,irad,6)=zero
              do jrad=1,ngrp
                 var_bicg(this,irad,6) = var_bicg(this,irad,6) + precond_bicg(this,irad,jrad) * var_bicg(this,jrad,1)
              enddo
           else
              var_bicg(this,irad,6) = var_bicg(this,irad,4) * var_bicg(this,irad,1)
           endif
        end do
     enddo
  endif !neilneil

  !====================
  ! MAIN ITERATION LOOP
  !====================   

  iter=0; itermax=5000

  error_ini=sqrt(rhs_norm1)
  error=error_ini

  max_loc=2.*epsilon_diff

  do while((max_loc>epsilon_diff .or. error/error_ini>epsilon_diff).and.iter<itermax)

     iter=iter+1

     !=========================================
     ! BiCGSTAB: Compute rho_bicg_new = rbar0.r
     ! BiCG2CG : Compute rho_bicg_new = r.z
     !=========================================
     call dot_product_tot(var_bicg(:,:,i_rho),var_bicg(:,:,1),r2,final_sum)
     rho_bicg_new = r2 ! real(final_sum)

     !================================================================================
     ! BiCGSTAB: Compute beta_bicg = rho_bicg_new/rho_bicg_old * alpha_bicg/omega_bicg
     ! BiCG2CG : Compute beta_bicg = rho_bicg_new/rho_bicg_old = (r.z)/(rold.zold)
     !================================================================================
     if(bicg_to_cg) then
        if(iter==1) then
           beta_bicg = zero
        else
           beta_bicg = rho_bicg_new/rho_bicg_old
        endif
     else
        beta_bicg = rho_bicg_new/rho_bicg_old * alpha_bicg/omega_bicg
     endif

     !=====================================================================
     ! BiCGSTAB: Recurrence on p = r + beta_bicg*p - omega_bicg*beta_bicg*v 
     ! BiCG2CG : Recurrence on p = z + beta_bicg*p 
     !=====================================================================
     call cX_plus_Y_to_Z_tot (beta_bicg,var_bicg(:,:,2),var_bicg(:,:,i_beta),var_bicg(:,:,2))
     if(.not.bicg_to_cg)then
        call cX_plus_Y_to_Z_tot (-omega_bicg*beta_bicg,var_bicg(:,:,3),var_bicg(:,:,2),var_bicg(:,:,2))
     endif

     call make_boundary_diffusion_tot(ilevel)
     do irad=1,ngrp
        call make_virtual_fine_dp(var_bicg(:,irad,2),ilevel)
     enddo

     if(.not.bicg_to_cg)then
        !====================================================================
        ! BiCGSTAB: Compute y = K^{-1} p and store it into var_bicg(i,irad,5)
        !====================================================================
        do irad=1,ngrp
           do i=1,nb_ind
              this = liste_ind(i)
              
              if(block_diagonal_precond_bicg) then
                 var_bicg(this,irad,5)=zero
                 do jrad=1,ngrp
                    var_bicg(this,irad,5) = var_bicg(this,irad,5) + precond_bicg(this,irad,jrad) * var_bicg(this,jrad,2)
                 enddo
              else
                 var_bicg(this,irad,5) = var_bicg(this,irad,4) * var_bicg(this,irad,2)
              endif
           end do
        enddo
        ! Update boundaries
        call make_boundary_diffusion_tot(ilevel)
        do irad=1,ngrp
           call make_virtual_fine_dp(var_bicg(:,irad,5),ilevel)
        enddo
     endif

     !===============================================================
     ! BiCGSTAB: Compute v = A y and store it into var_bicg(i,irad,3)
     ! BiCG2CG : Compute v = A p and store it into var_bicg(i,irad,3)
     !===============================================================
     call cmp_matrix_vector_product(ilevel,2)

     do irad=1,ngrp
        call make_virtual_fine_dp(var_bicg(:,irad,3),ilevel)
     enddo

     !==========================
     ! BiCGSTAB: Compute rbar0.v
     ! BiCG2CG : Compute p.Ap
     !==========================
     call dot_product_tot(var_bicg(:,:,i_pAp),var_bicg(:,:,3),r2,final_sum)

     !===========================================================================
     ! BiCGSTAB: Compute scalar alpha_bicg = rho_bicg_new (=rbar0.r) / (rbar_0,v)
     ! BiCG2CG : Compute scalar alpha_bicg = rho_bicg_new (=r.z) / p.Ap
     !===========================================================================
     if(r2.eq.zero) then
        alpha_bicg = zero
     else
        alpha_bicg = rho_bicg_new / r2  ! real(final_sum)
     endif

     !===============================================================================
     ! BiCGSTAB: Recurrence on s = r - alpha_bicg*v   and store it in var_bicg(:,:,7)
     ! BiCG2CG : Recurrence on r = r - alpha_bicg*A.p and store it in var_bicg(:,:,1)
     !===============================================================================
     call cX_plus_Y_to_Z_tot (-alpha_bicg,var_bicg(:,:,3),var_bicg(:,:,1),var_bicg(:,:,i_s))

     !====================================================================
     ! BiCGSTAB: Compute z = K^{-1} s and store it into var_bicg(i,irad,6)
     ! BiCG2CG : Compute z = K^{-1} r and store it into var_bicg(i,irad,6)
     !====================================================================
     do irad=1,ngrp
        do i=1,nb_ind
           this = liste_ind(i)

           if(block_diagonal_precond_bicg) then
              var_bicg(this,irad,6)=zero
              do jrad=1,ngrp
                 var_bicg(this,irad,6) = var_bicg(this,irad,6) + precond_bicg(this,irad,jrad) * var_bicg(this,jrad,i_s)
              enddo
           else
              var_bicg(this,irad,6) = var_bicg(this,irad,4) * var_bicg(this,irad,i_s)
           endif
        end do
     enddo

     if(.not.bicg_to_cg)then

        ! Update boundaries
        call make_boundary_diffusion_tot(ilevel)
        do irad=1,ngrp
           call make_virtual_fine_dp(var_bicg(:,irad,6),ilevel)
        enddo

        !===============================================================
        ! BiCGSTAB: Compute t = A z and store it into var_bicg(i,irad,8)
        !===============================================================
        call cmp_matrix_vector_product(ilevel,6)

        !=====================================================================================
        ! BiCGSTAB: Compute K^{-1} t to compute omega_bicg and store it in var_bicg(i,irad,10)
        !=====================================================================================
        do irad=1,ngrp
           do i=1,nb_ind
              this = liste_ind(i)

              if(block_diagonal_precond_bicg) then
                 var_bicg(this,irad,10)=zero
                 do jrad=1,ngrp
                    var_bicg(this,irad,10) = var_bicg(this,irad,10) + precond_bicg(this,irad,jrad) * var_bicg(this,jrad,8)
                 enddo
              else
                 var_bicg(this,irad,10) = var_bicg(this,irad,4) * var_bicg(this,irad,8)
              endif
           end do
        enddo

        !=============================================================================
        ! BiCGSTAB: Compute omega_bicg = (K^{-1} t , K^{-1} s) / (K^{-1} t , K^{-1} t)
        !=============================================================================
        call dot_product_tot(var_bicg(:,:,10),var_bicg(:,:, 6),r2,final_sum)
        call dot_product_tot(var_bicg(:,:,10),var_bicg(:,:,10),r3,final_sum)

        if(r3.eq.zero) then
           omega_bicg = zero
        else
           omega_bicg = r2 / r3
        endif

     else

        omega_bicg = zero

     endif
     
     !===========================
     ! Compute maximum variations
     !===========================
     max_loc=zero
     do irad=1,ngrp
        do i=1,nb_ind
           this = liste_ind(i)
           if(uold(this,nhydro+irad).ne.zero)then
              max_loc=max(max_loc,abs((alpha_bicg*var_bicg(this,irad,i_y)+&
                      omega_bicg*var_bicg(this,irad,6))/uold(this,nhydro+irad)))
           endif
        enddo
     enddo
#ifndef WITHOUTMPI
     call MPI_ALLREDUCE(max_loc,max_loc_all,1,MPI_DOUBLE_PRECISION,MPI_MAX,MPI_COMM_WORLD,info)
     max_loc = max_loc_all
#endif

     !=======================================================
     ! BiCGSTAB: Recurrence on x = x + alpha*y + omega_bicg*z
     ! BiCG2CG : Recurrence on x = x + alpha*p
     !=======================================================
     do irad=1,ngrp
        call cX_plus_Y_to_Z (alpha_bicg,var_bicg(:,irad,i_y),unew(:,nhydro+irad),unew(:,nhydro+irad))
        if(.not.bicg_to_cg) call cX_plus_Y_to_Z (omega_bicg,var_bicg(:,irad,6),unew(:,nhydro+irad),unew(:,nhydro+irad))
     enddo

     !=============================================
     ! BiCGSTAB: Recurrence on r = s - omega_bicg*t
     !=============================================
     if(.not.bicg_to_cg)then
        call cX_plus_Y_to_Z_tot (-omega_bicg,var_bicg(:,:,8),var_bicg(:,:,i_s),var_bicg(:,:,1))
     endif

     !===================================
     ! Update rho_bicg_old = rho_bicg_new
     !===================================
     rho_bicg_old = rho_bicg_new

     !===================================
     ! Compute right-hand side norm
     !===================================
     call dot_product_tot(var_bicg(:,:,1),var_bicg(:,:,1),rhs_norm1,final_sum)

     error=SQRT(rhs_norm1)

     if(verbose) then
        if (error_ini.ne.zero) then
           write(*,112)iter,error,error/error_ini,max_loc,error_ini
        else
           write(*,112)iter,error
        endif
     endif

  end do
  ! End main iteration loop

  if(iter >= itermax)then
     if(myid==1)write(*,*)'Radiative transfer failed to converge after ',iter,' iterations'
     call clean_stop
  end if

  !====================================
  ! Update gas temperature
  !====================================
  do i=1,nb_ind

     rho = uold(liste_ind(i),1)
     Told= uold(liste_ind(i),nvar) * Tr_floor
     !Cv = unew(liste_ind(i),nvar+1)
     
     rhs=zero
     lhs=zero
     do igrp=1,ngrp
        wdtB = C_cal*dt_imp*planck_ana(rho*scale_d,Told,igrp)/scale_kappa
        wdtE = C_cal*dt_imp*planck_ana(rho*scale_d,Told,igrp)/scale_kappa

        rhs=rhs-P_cal*wdtB*(radiation_source(Told,igrp)/scale_E0-Told*deriv_radiation_source(Told,igrp)/scale_E0) &
             & + P_cal*wdtE*unew(liste_ind(i),nhydro+igrp)

        lhs=lhs+P_cal*wdtB*deriv_radiation_source(Told,igrp)/scale_E0
     enddo

     unew(liste_ind(i),nvar) = (cv*Told+rhs)/(cv+lhs) / Tr_floor

  end do

  if(myid==1) then
     if(bicg_to_cg) then 
        if(error_ini.ne.zero) then
           write(*,117)ilevel,iter,error/error_ini,max_loc
        else
           write(*,*)' CG :',iter, 'error_ini=',error_ini
        endif
     else
        if(error_ini.ne.zero) then
           write(*,118)ilevel,iter,error/error_ini,max_loc
        else
           write(*,*)' BiCGSTAB :',iter, 'error_ini=',error_ini
        endif
     endif
     if(error_ini.ne.zero) then
        write(*,115)ilevel,iter,error,error/error_ini
     else
        write(*,115)ilevel,iter,error
     endif
  endif

  call make_boundary_diffusion_tot(ilevel)

  !====================
  ! Update energy value
  !====================
  if(static) then
     do i=1,nb_ind
        do irad = 1,ngrp
           uold(liste_ind(i),nhydro+irad) = unew(liste_ind(i),nhydro+irad)*P_cal
        enddo
     enddo
  else
     !call cmp_energy(2)
      do i=1,nb_ind
         icell = liste_ind(i)
         e_diff = 0
         do irad=1,ngrp
            unew(icell,nhydro+irad) = max(unew(icell,nhydro+irad),eray_min/scale_E0)
            unew(icell,nhydro+irad) = unew(icell,nhydro+irad) * P_cal
            e_diff = e_diff + (unew(icell,nhydro+irad) - uold(icell,nhydro+irad)) ! gather energy diff
            uold(icell,nhydro+irad) = unew(icell,nhydro+irad)
         enddo
         uold(icell,neul) = uold(icell,neul) + e_diff !update total energy with new radiative energy
      end do
  end if

  ! Update boundaries
  do irad=1,ngrp
     call make_virtual_fine_dp(uold(1,nhydro+irad),ilevel)
  enddo
  call make_virtual_fine_dp(uold(1,5),ilevel)

111 format('   Entering diffusion_cg')
112 format('   ==> Step=',i5,' Error=',2(1pe10.3,1x),e23.15,es18.5)
115 format('   ==> Level=',i5,' Step=',i5,' Error=',2(1pe10.3,1x))
117 format('   ==> Level=',i5,' Iteration CG=',i5,' Error L2=',(1pe10.3,1x),' Error Linf=',(1pe10.3,1x))
118 format('   ==> Level=',i5,' Iteration BiCGSTAB=',i5,' Error L2=',(1pe10.3,1x),' Error Linf=',(1pe10.3,1x))

  deallocate(liste_ind)

contains

  !###########################################################
  !###########################################################

  subroutine cX_plus_Y_to_Z (cste,vectX,vectY,vectZ) ! vectZ = cste*vectX+vectY
    implicit none
    real(dp),dimension(1:ncoarse+twotondim*ngridmax),intent(IN)::vectX,vectY
    real(dp),intent(IN)::cste
    real(dp),dimension(1:ncoarse+twotondim*ngridmax),intent(OUT)::vectZ


    do i=1,nb_ind
       vectZ(liste_ind(i)) = vectY(liste_ind(i)) + cste*vectX(liste_ind(i)) 
    end do

  end subroutine cX_plus_Y_to_Z

  !###########################################################
  !###########################################################

  subroutine dot_product_tot(fact1,fact2,dot_pdt,local_sum) ! dot_pdt = sum(fact1*fact2)
    implicit none
    real(dp),dimension(1:ncoarse+twotondim*ngridmax,1:ngrp),intent(IN)::fact1,fact2
    real(dp),intent(OUT)::dot_pdt
    complex*16,intent(OUT)::local_sum

#ifndef WITHOUTMPI
    real(dp)::dot_pdt_all
#endif
    complex*16 ::global_sum
    integer::this

    dot_pdt=zero
    local_sum = cmplx(zero,zero)
    global_sum = cmplx(zero,zero)

    do irad=1,ngrp
       do i=1,nb_ind
          this = liste_ind(i)
          !call DDPDD (cmplx(fact1(this,irad)*fact2(this,irad), zero,dp), local_sum, 1, itype)
          dot_pdt = dot_pdt + fact1(this,irad)*fact2(this,irad)
       end do
    enddo

    ! Compute global norms
#ifndef WITHOUTMPI
    call MPI_ALLREDUCE(dot_pdt,dot_pdt_all,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,info)
    dot_pdt   = dot_pdt_all
!!$  	call MPI_ALLREDUCE(local_sum,global_sum,1,MPI_COMPLEX,MPI_SUMDD,MPI_COMM_WORLD,info)
!!$	local_sum = global_sum
#endif

  end subroutine dot_product_tot

  !###########################################################
  !###########################################################

  subroutine cX_plus_Y_to_Z_tot (cste,vectX,vectY,vectZ) ! vectZ = cste*vectX+vectY
    implicit none
    real(dp),dimension(1:ncoarse+twotondim*ngridmax,1:ngrp),intent(IN)::vectX,vectY
    real(dp),intent(IN)::cste
    real(dp),dimension(1:ncoarse+twotondim*ngridmax,1:ngrp),intent(OUT)::vectZ

    do irad=1,ngrp
       do i=1,nb_ind
          vectZ(liste_ind(i),irad) = vectY(liste_ind(i),irad) + cste*vectX(liste_ind(i),irad) 
       end do
    enddo

  end subroutine cX_plus_Y_to_Z_tot


end subroutine rad_diffusion_bicg

!###########################################################
!###########################################################
!###########################################################
!###########################################################

subroutine cmp_matrix_and_vector_coeff_fld(ilevel)
  !------------------------------------------------
  ! This routine computes the matrix A and vector b
  !------------------------------------------------

  use amr_commons,only:active,ncoarse,nbor,son,myid
  use amr_parameters, only : ndim
  use hydro_commons
  use fld_parameters
  use fld_commons
  use const
  implicit none

  integer,intent(IN)::ilevel
  integer :: igroup,irad

  integer , dimension(1:nvector,1:2*ndim),save:: nbor_ilevel
  integer , dimension(1:nvector,1:ndim),save::   cell_left , cell_right , big_left, big_right
  integer ,dimension(1:nvector,0:2*ndim),save::  igridn
  integer ,dimension(1:nvector),save ::          ind_cell , ind_grid

!!$  real(dp),dimension(1:nvector  ,1:  ngrp),save:: C_g,C_d

  integer :: i,idim,ind,igrid,ngrid,ncache,iskip,igrp,nx_loc
  integer :: supG,sub,supD

  real(dp)::dx,dx_loc,surf_loc,vol_loc,scale

#if NGRP>1
  ! variables used by the LAPACK inversion routines
  integer, parameter                        :: nwork = 256
  integer                                   :: info2
  integer                                   :: lda,lwork
  integer, dimension(      ngrp)       :: ipiv
  integer, dimension(nwork*ngrp)       :: work
  real(dp),dimension(1:ngrp,1:ngrp) ::inv
#endif

  real(dp),dimension(ngrp,ngrp)::coeff_left,coeff_right,mat_residual
  real(dp),dimension(ngrp          )::residual
  
  ! Mesh size at level ilevel
  dx=half**ilevel

  ! Rescaling factors
  nx_loc=(icoarse_max-icoarse_min+1)
  scale=boxlen/dble(nx_loc)
  dx_loc=dx*scale
  surf_loc = dx_loc**(ndim-1)
  vol_loc  = dx_loc**ndim

  ! **************************** LOOP OVER CELLS ********************************** !

  ! Loop over myid grids by vector sweeps
  ncache = active(ilevel)%ngrid
  do igrid=1,ncache,nvector

     ! Gather nvector grids
     ngrid=MIN(nvector,ncache-igrid+1)
     do i=1,ngrid
        ind_grid(i) = active(ilevel)%igrid(igrid+i-1)
        igridn(i,0) = ind_grid(i)
     end do

     do idim=1,ndim
        do i=1,ngrid
           big_left (i,idim)  = nbor(ind_grid(i),2*idim-1)
           big_right(i,idim)  = nbor(ind_grid(i),2*idim  )
           igridn(i,2*idim-1) = son(big_left (i,idim))
           igridn(i,2*idim  ) = son(big_right(i,idim))
        end do
     end do

     ! Loop over cells
     do ind=1,twotondim
        iskip=ncoarse+(ind-1)*ngridmax
        do i=1,ngrid
           ind_cell(i)=iskip+ind_grid(i)
        end do

        ! Determine the two2ndim and the direction of the grid of neighboors (-1,0,1)
        do idim = 1,ndim

           if (modulo((ind-1)/2**(idim-1),2)==0)then
              supG = (idim-1)*2+1               !direction of left nbor grid
              supD = 0                          !direction of right nbor grid
              sub = ind + 2**(idim-1)           ! position of nbor in its own grid
           else
              supG = 0                          !direction of left nbor grid
              supD = (idim-1)*2+2               !direction of right nbor grid
              sub = ind - 2**(idim-1)           !position of nbor in its own grid
           end if

           sub = ncoarse + (sub-1)*ngridmax     !nbor index offset from its own grid

           do i=1,ngrid

              ! Getting neighboors relative level (-1,0,1)

              if(son(ind_cell(i)) == 0 )then

                 if(igridn(i,supG)>0)then

                    cell_left(i,idim) = igridn(i,supG)+ sub
                    if(son(cell_left(i,idim))>0)then ! Left nbor more refined than me
                       nbor_ilevel(i,2*idim-1) = 1
                    else                             ! Left nbor as refined as me
                       nbor_ilevel(i,2*idim-1) = 0
                    end if

                 else                                ! Left nbor less refined than me

                    nbor_ilevel(i,2*idim-1) = -1
                    cell_left(i,idim)    = big_left(i,idim)
                 end if

                 if(igridn(i,supD)>0)then

                    cell_right(i,idim) = igridn(i,supD)+ sub
                    if(son(cell_right(i,idim))>0)then ! Right nbor more refined than me
                       nbor_ilevel(i,2*idim) = 1
                    else                              ! Right nbor as refined as me
                       nbor_ilevel(i,2*idim) = 0
                    end if

                 else                                 ! Right nbor less refined than me

                    nbor_ilevel(i,2*idim) = -1
                    cell_right(i,idim) = big_right(i,idim)
                 end if

              end if
           end do

        end do !ndim
        
        do i=1,ngrid
           if(son(ind_cell(i)) == 0 )then

              call compute_residual_in_cell(ind_cell(i),vol_loc,residual,mat_residual)

              do igroup=1,ngrp
                 do igrp=1,ngrp
                    if(store_matrix) then
                     mat_residual_glob(ind_cell(i),igroup,igrp) = mat_residual(igroup,igrp)
                    endif
                    if(block_diagonal_precond_bicg.or.igroup==igrp) then
                       precond_bicg(ind_cell(i),igroup,igrp) = mat_residual(igroup,igrp)
                    endif
                 enddo
                 if(store_matrix) residual_glob(ind_cell(i),igroup) = residual(igroup)
              enddo

           endif
        enddo

        ! Compute off-diagonal terms
        do idim = 1,ndim

           do i=1,ngrid
              if(son(ind_cell(i)) == 0 )then

                 call compute_coeff_left_right_in_cell(ind_cell(i),idim,cell_left(i,idim),cell_right(i,idim),nbor_ilevel(i,1:2*ndim),dx_loc,coeff_left,coeff_right)

                 do igroup=1,ngrp

                    if(store_matrix)then
                       coeff_glob_left (ind_cell(i),igroup,igroup,idim)=coeff_left(igroup,igroup)
                       coeff_glob_right(ind_cell(i),igroup,igroup,idim)=coeff_right(igroup,igroup)
                    endif

                    precond_bicg(ind_cell(i),igroup,igroup) = precond_bicg(ind_cell(i),igroup,igroup) + (coeff_left(igroup,igroup) + coeff_right(igroup,igroup))*alpha_imp

                 enddo

              end if
           end do

        enddo !ndim

        ! Compute preconditionning matrix                                                               
        do i=1,ngrid
           if(son(ind_cell(i)) == 0 )then
#if NGRP>1
              if(block_diagonal_precond_bicg) then
                 inv = precond_bicg(ind_cell(i),1:ngrp,1:ngrp)
                 lda = ngrp ; lwork = nwork*ngrp
                 
                 ! Invert the (ngrp x ngrp) matrix using LAPACK routines                      
                 !
                 ! DGETRF computes an LU factorization of a general M-by-N matrix A                     
                 ! using partial pivoting with row interchanges                                         
                 call dgetrf(ngrp,ngrp,inv,lda,ipiv,info2)
                 
                 ! DGETRI computes the inverse of a matrix using the LU factorization                   
                 ! computed by DGETRF                                                                   
                 call dgetri(ngrp,inv,lda,ipiv,work,lwork,info2)
                 
                 precond_bicg(ind_cell(i),1:ngrp,1:ngrp)=inv
              else
#endif
                 do irad=1,ngrp
                    var_bicg(ind_cell(i),irad,4) = one/precond_bicg(ind_cell(i),irad,irad)
                 enddo
#if NGRP>1
              endif
#endif
           end if
        end do !ngrid
        
     end do ! twotodim
  end do ! ncache

  return

end subroutine cmp_matrix_and_vector_coeff_fld
!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine cmp_matrix_vector_product(ilevel,compute)
  !------------------------------------------------------------------
  ! This routine computes 
  ! compute = 1 : residual           	  return B - Ax
  ! compute = 2 : Product                 return  A.p
  ! compute = 3 : Preconditionner         return diag(A) or block_diag(A)
  !
  ! For BICG
  ! compute = 6 : product                 return  A.p
  !------------------------------------------------------------------

  use amr_commons,only:active,ncoarse,nbor,son,myid
  use amr_parameters, only : ndim
  use hydro_commons
  use fld_parameters
  use fld_commons
  use hydro_parameters,only:ngrp
  use const
  implicit none

  integer,intent(IN)::compute,ilevel
  integer :: irad,jrad

  integer , dimension(1:nvector,1:2*ndim),save:: nbor_ilevel
  integer , dimension(1:nvector,1:ndim),save::   cell_left , cell_right , big_left, big_right
  integer ,dimension(1:nvector,0:2*ndim),save::  igridn
  integer ,dimension(1:nvector),save ::          ind_cell , ind_grid

  real(dp),dimension(1:nvector  ,1:  ngrp),save:: residu
  real(dp),dimension(1:nvector  ,1:  ngrp),save:: phi_g,phi_c,phi_d,val_g,val_d

  integer :: i,idim,ind,igrid,ngrid,ncache,iskip,nx_loc
  integer :: supG,sub,supD

  real(dp)::dx,dx_loc,surf_loc,vol_loc,scale

  integer :: ind_res

  ! Mesh size at level ilevel
  dx=half**ilevel

  ! Rescaling factors
  nx_loc=(icoarse_max-icoarse_min+1)
  scale=boxlen/dble(nx_loc)
  dx_loc=dx*scale
  surf_loc = dx_loc**(ndim-1)
  vol_loc  = dx_loc**ndim

  ! **************************** LOOP OVER CELLS ********************************** !

  residu = zero

  ! Loop over myid grids by vector sweeps
  ncache = active(ilevel)%ngrid
  do igrid=1,ncache,nvector
  
     ! Gather nvector grids
     ngrid=MIN(nvector,ncache-igrid+1)
     do i=1,ngrid
        ind_grid(i) = active(ilevel)%igrid(igrid+i-1)
        igridn(i,0) = ind_grid(i)
     end do

     do idim=1,ndim
        do i=1,ngrid
           big_left (i,idim)  = nbor(ind_grid(i),2*idim-1)
           big_right(i,idim)  = nbor(ind_grid(i),2*idim  )
           igridn(i,2*idim-1) = son(big_left (i,idim))
           igridn(i,2*idim  ) = son(big_right(i,idim))
        end do
     end do

     ! Loop over cells
     do ind=1,twotondim
        iskip=ncoarse+(ind-1)*ngridmax
        do i=1,ngrid
           ind_cell(i)=iskip+ind_grid(i)
        end do

        ! Determine the two2ndim and the direction of the grid of neighboors (-1,0,1)
        do idim = 1,ndim

           if (modulo((ind-1)/2**(idim-1),2)==0)then
              supG = (idim-1)*2+1     !direction of left nbor grid
              supD = 0                !direction of right nbor grid
              sub = ind + 2**(idim-1) !position of nbor in its own grid
           else
              supG = 0                !direction of left nbor grid
              supD = (idim-1)*2+2     !direction of right nbor grid
              sub = ind - 2**(idim-1) !position of nbor in its own grid
           end if

           sub = ncoarse + (sub-1)*ngridmax !nbor index offset from its own grid

           do i=1,ngrid

              ! Getting neighboors relative level (-1,0,1)

              if(son(ind_cell(i)) == 0 )then

                 if(igridn(i,supG)>0)then

                    cell_left(i,idim) = igridn(i,supG)+ sub
                    if(son(cell_left(i,idim))>0)then ! Left nbor more refined than me
                       nbor_ilevel(i,2*idim-1) = 1
                    else                             ! Left nbor as refined as me
                       nbor_ilevel(i,2*idim-1) = 0
                    end if

                 else                                ! Left nbor less refined than me

                    nbor_ilevel(i,2*idim-1) = -1
                    cell_left(i,idim)    = big_left(i,idim)
                 end if

                 if(igridn(i,supD)>0)then

                    cell_right(i,idim) = igridn(i,supD)+ sub
                    if(son(cell_right(i,idim))>0)then ! Right nbor more refined than me
                       nbor_ilevel(i,2*idim) = 1
                    else                              ! Right nbor as refined as me
                       nbor_ilevel(i,2*idim) = 0
                    end if

                 else                                 ! Right nbor less refined than me

                    nbor_ilevel(i,2*idim) = -1
                    cell_right(i,idim) = big_right(i,idim)
                 end if

              end if
           end do

        end do !ndim
        
        do i=1,ngrid
           if(son(ind_cell(i)) == 0 )then

              if(.not.store_matrix)then
                 call compute_residual_in_cell(ind_cell(i),vol_loc,residual_glob(1,:),mat_residual_glob(1,:,:))
                 ind_res = 1
              else
                 ind_res = ind_cell(i)
              endif

              select case (compute)

              case (1) ! residu = b - Ix
                 
                 do irad = 1,ngrp
                    residu(i,irad) = residual_glob(ind_res,irad)
                    do jrad = 1,ngrp
                       residu(i,irad) = residu(i,irad) - mat_residual_glob(ind_res,irad,jrad)*uold(ind_cell(i),nhydro+jrad)
                    enddo
                 enddo

              case (2) ! residu = Ix

                 residu(i,1:ngrp)=zero
                 do irad=1,ngrp
                    do jrad=1,ngrp
                       residu(i,irad)=residu(i,irad)+mat_residual_glob(ind_res,irad,jrad)*var_bicg(ind_cell(i),jrad,i_y)
                    enddo
                 enddo

!neil
!!$                 do idim=1,ndim
!!$                    do irad = 1,ngrp
!!$                       var_bicg(ind_cell(i),irad,11+(idim-1)*2) = var_rad_subset(1,idim,nrad+2+irad)
!!$                       var_bicg(ind_cell(i),irad,12+(idim-1)*2) = var_rad_subset(3,idim,nrad+2+irad)
!!$                    enddo
!!$                 enddo
!neil

              case (6) ! residu = Ix

                 residu(i,1:ngrp)=zero
                 do irad=1,ngrp
                    do jrad=1,ngrp
                       residu(i,irad)=residu(i,irad)+mat_residual_glob(ind_res,irad,jrad)*var_bicg(ind_cell(i),jrad,6)
                    enddo
                 enddo

              end select

           endif
        enddo

        do idim = 1,ndim

           select case (compute)! Getting val_g and val_d
           case(1)
              do i=1,ngrid
                 if(son(ind_cell(i)) == 0 )then
                    do irad=1,ngrp
                       val_g(i,irad) = uold(cell_left (i,idim),nhydro+irad)
                       val_d(i,irad) = uold(cell_right(i,idim),nhydro+irad)
                    enddo
                 end if
              end do

           case(2)
              do i=1,ngrid
                 if(son(ind_cell(i)) == 0 )then
                    do irad=1,ngrp
                       val_g(i,irad) = var_bicg(cell_left (i,idim),irad,i_y)
                       val_d(i,irad) = var_bicg(cell_right(i,idim),irad,i_y)
                    enddo
                 end if
              end do

           case(4)
              do i=1,ngrid
                 if(son(ind_cell(i)) == 0 )then
                    do irad=1,ngrp
                       val_g(i,irad) = unew(cell_left (i,idim),nhydro+irad)
                       val_d(i,irad) = unew(cell_right(i,idim),nhydro+irad)
                    enddo
                 end if
              end do

           case(6)
              do i=1,ngrid
                 if(son(ind_cell(i)) == 0 )then
                    do irad=1,ngrp
                       val_g(i,irad) = var_bicg(cell_left (i,idim),irad,6)
                       val_d(i,irad) = var_bicg(cell_right(i,idim),irad,6)
                    enddo
                 end if
              end do

           end select

           do i=1,ngrid
              if(son(ind_cell(i)) == 0 )then

                 select case (nbor_ilevel(i,2*idim-1)) ! Gather main characteristics of left neighbour

                 case (1)
                    do irad=1,ngrp
                       if (compute==2  .or. compute==6) then
                          val_g(i,irad) = zero
                       else
                          val_g(i,irad) = uold(cell_left(i,idim),nhydro+irad)/P_cal
                       endif
                       phi_g (i,irad) = uold(cell_left(i,idim),nhydro+irad)/P_cal
                    enddo
                 case (0)
                    do irad=1,ngrp
                       phi_g (i,irad)       = uold(cell_left(i,idim),nhydro+irad)
                    enddo
                 case (-1)
                    do irad=1,ngrp
                       if (compute==2  .or. compute==6) then
                          val_g(i,irad) = zero
                       else
                          val_g(i,irad) = uold(cell_left(i,idim),nhydro+irad)/P_cal
                       endif
                       phi_g (i,irad) = uold(cell_left(i,idim),nhydro+irad)/P_cal
                    enddo
                 end select

                 select case (nbor_ilevel(i,2*idim)) ! Gather main characteristics of right neighbour
                 case (1)
                    do irad=1,ngrp
                       if (compute==2  .or. compute==6) then
                          val_d(i,irad) = zero
                       else
                          val_d(i,irad) = uold(cell_right(i,idim),nhydro+irad)/P_cal
                       endif
                       phi_d (i,irad) = uold(cell_right(i,idim),nhydro+irad)/P_cal
                    enddo
                 case (0)
                    do irad=1,ngrp
                       phi_d (i,irad)  = uold(cell_right(i,idim),nhydro+irad)
                    enddo
                 case (-1)
                    do irad=1,ngrp
                       if (compute==2  .or. compute==6) then
                          val_d(i,irad) = zero
                       else
                          val_d(i,irad) = uold(cell_right(i,idim),nhydro+irad)/P_cal
                       endif
                       phi_d (i,irad) = uold(cell_right(i,idim),nhydro+irad)/P_cal
                    enddo
                 end select
              end if
           end do

           if (compute ==4)then ! Computing and saving flux to the coarser ilevel

              do i=1,ngrid
                 if(son(ind_cell(i)) == 0)then

                    if(.not.store_matrix)then
                       call compute_coeff_left_right_in_cell(ind_cell(i),idim,cell_left(i,idim),cell_right(i,idim),nbor_ilevel(i,1:2*ndim),dx_loc,coeff_glob_left(1,:,:,idim),coeff_glob_right(1,:,:,idim))
                       ind_res=1
                    else
                       ind_res=ind_cell(i)
                    endif

                    if( nbor_ilevel(i,2*idim-1) == -1)then
                       do irad=1,ngrp
                          phi_c(i,irad) = uold(ind_cell(i),nhydro+irad)
                       enddo
                    end if

                    if( nbor_ilevel(i,2*idim)   == -1 )then
                       do irad=1,ngrp
                          phi_c(i,irad) = uold(ind_cell(i),nhydro+irad)
                       enddo
                    end if

                 end if
              end do
           end if


           do i=1,ngrid
              if(son(ind_cell(i)) == 0 )then

                 if(.not.store_matrix)then
                    call compute_coeff_left_right_in_cell(ind_cell(i),idim,cell_left(i,idim),cell_right(i,idim),nbor_ilevel(i,1:2*ndim),dx_loc,coeff_glob_left(1,:,:,idim),coeff_glob_right(1,:,:,idim))
                    ind_res=1
                 else
                    ind_res=ind_cell(i)
                 endif
                 
                 select case (compute)
                    
                 case (1) ! compute b-Ax from b-Ix by adding intern flux

                    do irad=1,ngrp
                       do jrad=1,ngrp
                          residu(i,irad) = residu(i,irad) + coeff_glob_left(ind_res,irad,jrad,idim)*val_g(i,jrad) + coeff_glob_right(ind_res,irad,jrad,idim)*val_d(i,jrad)
                       enddo
                       residu(i,irad) = residu(i,irad) - (coeff_glob_left(ind_res,irad,irad,idim)+coeff_glob_right(ind_res,irad,irad,idim))* uold(ind_cell(i),nhydro+irad)
                    enddo

                 case (2) ! compute Ap from Ip by adding intern flux

                    do irad=1,ngrp
                       do jrad=1,ngrp
                          residu(i,irad) = residu(i,irad) - (coeff_glob_left(ind_res,irad,jrad,idim)*val_g(i,jrad) + coeff_glob_right(ind_res,irad,jrad,idim)*val_d(i,jrad))*alpha_imp
                       enddo
                       residu(i,irad) = residu(i,irad) + (coeff_glob_left(ind_res,irad,irad,idim)+coeff_glob_right(ind_res,irad,irad,idim))* var_bicg(ind_cell(i),irad,i_y)*alpha_imp
                    enddo

                 case (6) ! compute Ap* from Ip by adding intern flux

                    do irad=1,ngrp
                       do jrad=1,ngrp
                          residu(i,irad) = residu(i,irad) - (coeff_glob_left(ind_res,irad,jrad,idim)*val_g(i,jrad) + coeff_glob_right(ind_res,irad,jrad,idim)*val_d(i,jrad))*alpha_imp
                       enddo
                       residu(i,irad) = residu(i,irad) + (coeff_glob_left(ind_res,irad,irad,idim)+coeff_glob_right(ind_res,irad,irad,idim))* var_bicg(ind_cell(i),irad,6)*alpha_imp
                    enddo

                 end select
              end if
           end do


        end do !ndim


        select case (compute)
           ! get the result out

        case (1)
           do i=1,ngrid
              if(son(ind_cell(i)) == 0 )then
                 do irad=1,ngrp
                    var_bicg(ind_cell(i),irad,1) = residu(i,irad)
                 enddo
              end if
           end do

        case (2)
           do i=1,ngrid
              if(son(ind_cell(i)) == 0 )then
                 do irad=1,ngrp
                    var_bicg(ind_cell(i),irad,3) = residu(i,irad)
                 enddo
              end if
           end do

        case (6)
           do i=1,ngrid
              if(son(ind_cell(i)) == 0 )then
                 do irad=1,ngrp
                    var_bicg(ind_cell(i),irad,8) = residu(i,irad)
                 enddo
              end if
           end do

        end select

     end do ! twotodim
  end do ! ncache

  return

end subroutine cmp_matrix_vector_product
!################################################################
!################################################################
!################################################################ 
!################################################################
function cmp_temp(icell)
   use hydro_commons
   implicit none
   integer,intent(in) ::icell
   real(dp)::cmp_temp,eps,rho

   rho   = uold(icell,1)

   ! Compute internal energy from total energy
   call compute_internal_energy(uold(icell,:),eps)

   ! Compute gas temperature in Kelvin
   call internal_energy_to_temperature(rho,eps,cmp_temp)

end function cmp_temp
!################################################################
!################################################################
!################################################################ 
!################################################################
function nu_surf(Er1,Er2,dx)
  use hydro_commons
  use const
  implicit none
  real(dp),intent(in)::Er2,Er1,dx
  real(dp)::nu_surf,nu_harmo,nu_ari

  nu_ari=(Er2+Er1)*half
  nu_harmo=max(Er2*Er1/nu_ari,four/(three*dx))
  nu_surf = nu_ari
  nu_surf=min(nu_harmo,nu_ari)

end function nu_surf
!###########################################################
!###########################################################
!###########################################################
!###########################################################

subroutine compute_residual_in_cell(i,vol_loc,residual,mat_residual)

  use hydro_parameters,only:nvar
  use hydro_commons
  use fld_parameters
  use fld_commons
  use const
  use constants, only: eV2erg,c_cgs

  implicit none
  integer,intent(in)::i
  real(dp),intent(in)::vol_loc
  real(dp),dimension(ngrp,ngrp),intent(out)::mat_residual
  real(dp),dimension(ngrp          ),intent(out)::residual

  real(dp)::rho,Told_norm,Told,cv,lhs,rhs,rosseland_ana,planck_ana,radiation_source,deriv_radiation_source,cal_Teg,eps
  integer::igrp,igroup
  real(dp),dimension(ngrp)::wdtB,wdtE,source,deriv

   real(dp)::scale_nH,scale_T2,scale_t,scale_v,scale_d,scale_l,scale_kappa,C_cal
   call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
   scale_kappa=1d0/scale_l
   C_cal = c_cgs/scale_v


   rho = uold(i,1)

   ! Compute internal energy from total energy
   call compute_internal_energy(uold(i,1:nvar_all),eps)

   ! Compute gas temperature in Kelvin
   call internal_energy_to_temperature(rho,eps,Told_norm)

   Told      = Told_norm * Tr_floor
   Cv        = eps

  lhs=zero
  rhs=zero
  do igrp=1,ngrp
     ! Store radiation_source, deriv_radiation_source and planck opacity to save cpu time
     source(igrp)=radiation_source(Told,igrp)
     deriv(igrp)=deriv_radiation_source(Told,igrp)
     wdtB(igrp) = C_cal*dt_imp*planck_ana(rho*scale_d,Told,igrp)/scale_kappa
     wdtE(igrp) = C_cal*dt_imp*planck_ana(rho*scale_d,Told,igrp)/scale_kappa
     lhs=lhs+P_cal*wdtB(igrp)*deriv(igrp)/scale_E0
     rhs=rhs-P_cal*wdtB(igrp)*(source(igrp)/scale_E0-Told*deriv(igrp)/scale_E0)
  enddo

  mat_residual(:,:) = zero
  residual    (:  ) = zero
  do igroup=1,ngrp
     mat_residual(igroup,igroup) =  (one+wdtE(igroup))*vol_loc

     ! Terms of coupling radiative groups
     do igrp=1,ngrp
        mat_residual(igroup,igrp) = mat_residual(igroup,igrp) - wdtB(igroup)*(deriv(igroup)*P_cal*wdtE(igrp)/scale_E0/(cv+lhs))*vol_loc
     enddo

     residual(igroup) = uold(i,nhydro+igroup)*vol_loc  &
          & + vol_loc*wdtB(igroup)*(source(igroup)/scale_E0-Told*deriv(igroup)/scale_E0) &
          & + vol_loc*wdtB(igroup)*deriv(igroup)/scale_E0*(cv*Told+rhs)/(cv+lhs)
  enddo

  return

end subroutine compute_residual_in_cell

!###########################################################
!###########################################################
!###########################################################
!###########################################################

subroutine compute_coeff_left_right_in_cell(i,idim,cell_left,cell_right,nbor_ilevel,dx_loc,coeff_left,coeff_right)

  use hydro_parameters,only:nvar
  use hydro_commons
  use fld_parameters
  use fld_commons
  use const
  use constants, only:c_cgs
  
  implicit none
  integer,intent(in)::i,idim,cell_left,cell_right
  integer,dimension(2*ndim),intent(in)::nbor_ilevel
  real(dp),intent(in)::dx_loc
  real(dp),dimension(ngrp,ngrp),intent(out)::coeff_left,coeff_right

  real(dp)::rho,Told,cal_Teg,cmp_temp,rosseland_ana,lambda,lambda_fld,R,nu_surf,surf_loc
  integer::igroup,irad
  real(dp),dimension(ngrp)::C_g,C_d,phi_g,phi_c,phi_d,nu_g,nu_c,nu_d

   real(dp)::scale_nH,scale_T2,scale_t,scale_v,scale_d,scale_l,scale_kappa,C_cal
   call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
   scale_kappa=1d0/scale_l
   C_cal = c_cgs/scale_v

  surf_loc = dx_loc**(ndim-1)

  select case (nbor_ilevel(2*idim-1)) ! Gather main characteristics of left neighbour

  case (1)

     if (robin  > zero) then
        C_g(:) = one/robin
     else
        C_g(:) = zero
     endif

     do irad=1,ngrp
        phi_g (irad) = uold(cell_left,nhydro+irad)/P_cal
     enddo

     Told = cmp_temp(cell_left)
     rho  = scale_d * max(uold(cell_left,1),smallr)
     do igroup=1,ngrp
        nu_g(igroup) = rosseland_ana(rho,Told,igroup) / scale_kappa
        if(nu_g(igroup)*dx_loc .lt. min_optical_depth) nu_g(igroup)=min_optical_depth/dx_loc
     enddo

  case (0)

     do irad=1,ngrp
        phi_g (irad)       = uold(cell_left,nhydro+irad)
        C_g   (irad)       = one
     enddo
     do igroup=1,ngrp
        nu_g  (igroup)       = kappaR_bicg(cell_left,igroup)
     enddo

  case (-1)

     C_g(:) = 1.5_dp
     do irad=1,ngrp
        phi_g (irad) = uold(cell_left,nhydro+irad)/P_cal
     enddo

     Told = cmp_temp(cell_left)
     rho  = scale_d * max(uold(cell_left,1),smallr)
     do igroup=1,ngrp
        nu_g  (igroup) = rosseland_ana(rho,Told,igroup) / scale_kappa
        if(nu_g(igroup)*2.0d0*dx_loc .lt. min_optical_depth) nu_g(igroup)=min_optical_depth/(2.0d0*dx_loc)
     enddo

  end select

  select case (nbor_ilevel(2*idim)) ! Gather main characteristics of right neighbour

  case (1)

     if (robin  > zero) then
        C_d(:) = one/robin
     else
        C_d(:) = zero
     endif

     do irad=1,ngrp
        phi_d (irad) = uold(cell_right,nhydro+irad)/P_cal
     enddo

     Told = cmp_temp(cell_right)
     rho  = scale_d * max(uold(cell_right,1),smallr)
     do igroup=1,ngrp
        nu_d  (igroup) = rosseland_ana(rho,Told,igroup) / scale_kappa
        if(nu_d(igroup)*dx_loc .lt. min_optical_depth) nu_d(igroup)=min_optical_depth/dx_loc
     enddo

  case (0)

     do irad=1,ngrp
        phi_d (irad)  = uold(cell_right,nhydro+irad)
        C_d   (irad)  = one
     enddo
     do igroup=1,ngrp
        nu_d  (igroup)  = kappaR_bicg(cell_right,igroup)
     enddo

  case (-1)

     C_d(:) = 1.5_dp
     do irad=1,ngrp
        phi_d (irad) = uold(cell_right,nhydro+irad)/P_cal
     enddo

     Told = cmp_temp(cell_right)
     rho  = scale_d * max(uold(cell_right,1),smallr)
     do igroup=1,ngrp
        nu_d  (igroup) = rosseland_ana(rho,Told,igroup) / scale_kappa
        if(nu_d(igroup)*2.0d0*dx_loc .lt. min_optical_depth) nu_d(igroup)=min_optical_depth/(2.0d0*dx_loc)
     enddo

  end select

  do igroup=1,ngrp
     nu_c (igroup) = kappaR_bicg(i,igroup)
     C_g(igroup) = C_g(igroup) * nu_surf(nu_g(igroup),nu_c(igroup),dx_loc)
     C_d(igroup) = C_d(igroup) * nu_surf(nu_d(igroup),nu_c(igroup),dx_loc)

     phi_c(igroup) = uold(i,nhydro+igroup)

     if(C_g(igroup) > zero)then
        R = max(1.0e-10_dp,abs (phi_c(igroup)-phi_g(igroup)) /(half*(phi_c(igroup)+phi_g(igroup))))
        R = R / ( C_g(igroup) * dx_loc )

        lambda=lambda_fld(R)
        C_g(igroup) = C_cal*lambda *dt_imp*surf_loc/(dx_loc*C_g(igroup))
     end if

     if(C_d(igroup) > zero)then
        R = max(1.0e-10_dp,abs (phi_c(igroup)-phi_d(igroup)) /(half*(phi_c(igroup)+phi_d(igroup))))
        R = R / ( C_d(igroup) * dx_loc )

        lambda=lambda_fld(R)
        C_d(igroup) = C_cal*lambda *dt_imp*surf_loc/(dx_loc*C_d(igroup))

     end if

     ! TC: what is the point of only filling the dialogal?
     coeff_left (igroup,igroup)=C_g(igroup)
     coeff_right(igroup,igroup)=C_d(igroup)

  enddo

end subroutine compute_coeff_left_right_in_cell
