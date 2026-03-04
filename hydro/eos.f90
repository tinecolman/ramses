subroutine barotropic_eos_temperature(density, temperature)
   use amr_parameters
   !--------------------------------------------------------------
   ! This routine selects the chosen EOS and calculates the
   ! temperature T[in Kelvin]/mu from the density[in H/cc]
   !--------------------------------------------------------------
   real(dp), intent(in) ::density
   real(dp), intent(out)::temperature
   real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v

   call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

   SELECT CASE (barotropic_eos_form)
   CASE ('isothermal')
      temperature = T2_eos
   CASE ('polytrope')
      temperature = T2_eos*((density/scale_nH)/polytrope_rho_cu)**(polytrope_index-1.0d0)
   CASE ('double_polytrope')
      ! to convert n to rho: rho = density/scale_nH*scale_d
      temperature = T2_eos * (1 + ((density/scale_nH)/polytrope_rho_cu)**(polytrope_index-1.0d0))
   CASE ('custom')
      ! WRITE YOUR FAVORITE EOS HERE
      if((density/scale_nH)<polytrope_rho_cu)then
         temperature = T2_eos
      else
         temperature = T2_eos * ((density/scale_nH)/polytrope_rho_cu)**(polytrope_index-1.0d0)
      endif
   CASE DEFAULT
     write(*,*)'unknown barotropic eos form'
     call clean_stop
   END SELECT

end subroutine barotropic_eos_temperature
!#####################################################################
!#####################################################################
!#####################################################################
!#####################################################################
subroutine internal_energy_to_temperature(rho_temp,Enint_temp,Teos)
  use amr_parameters      ,only:dp,mu_gas
  use hydro_commons       ,only:gamma
  use constants           ,only:kB,mH
  implicit none
  !-------------------------------------------------------------------
  ! This routine computes the temperature in Kelvin from the density 
  ! and internal volumic energy in code units.
  !-------------------------------------------------------------------
  real(dp), intent(in) :: Enint_temp,rho_temp
  real(dp), intent(out):: Teos
  real(dp)::rho,Enint
  real(dp)::scale_nH,scale_T2,scale_t,scale_v,scale_d,scale_l

  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

  rho   = rho_temp*scale_d
  Enint = Enint_temp*scale_d*scale_v**2 

  Teos = Enint/(rho*kB/(mu_gas*mH*(gamma-1.0d0)))

end subroutine internal_energy_to_temperature
!#####################################################################
!#####################################################################
!#####################################################################
!#####################################################################
subroutine compute_internal_energy(uu,eps)
   use hydro_commons, only:uold
   ! conservative hydro variables in the cell
   real(dp),dimension(1:nvar_all),intent(in):: uu
   ! volumetric internal energy
   real(dp),intent(out)::eps
   !-----------------------------------------------------------
   ! Compute internal energy from conservative hydro variables
   !-----------------------------------------------------------
   real(dp)::d

   d = uu(1)
   eps = uu(neul)
   eps = eps - 0.5d0*uu(2)**2/d
#if NDIM>1 || SOLVERmhd
   eps = eps - 0.5d0*uu(3)**2/d
#endif
#if NDIM>2 || SOLVERmhd
   eps = eps - 0.5d0*uu(4)**2/d
#endif
#ifdef SOLVERmhd
   eps = eps - 0.125d0*(uu(6)+uu(nvar+1))**2
   eps = eps - 0.125d0*(uu(7)+uu(nvar+2))**2
   eps = eps - 0.125d0*(uu(8)+uu(nvar+3))**2
#endif
#if NENER>0
   do igroup=1,nener
      eps = eps - uu(nhydro+igroup)
   end do
#endif

end subroutine internal_energy_from_uold