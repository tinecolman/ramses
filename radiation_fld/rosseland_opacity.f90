function rosseland_ana(dens,Tp,igroup)
  use amr_commons
  use fld_parameters
  use constants, only:pi
  implicit none
  integer ,intent(in)    :: igroup  ! fld radiation group
  real(dp),intent(in)    :: dens    ! gas density in cgs
  real(dp),intent(in)    :: Tp      ! gas temperature in Kelvin
  real(dp)               :: rosseland_ana
  !--------------------------------------------------------------
  ! Compute Rosseland mean opacity (in cgs)
  !--------------------------------------------------------------
  real(dp) :: Tevap ! if sublimation_kuiper

  if(sublimation_kuiper) then
     !# RMR #### Sublimation of dust grains as in kuiper+10 ApJ ####
     !### The highest dust temperature is the evaporation temperature
     !### Opacities are taken at this temperature
     !### The input temperature is kept to compute the d/g ratio
     Tevap = 2000.0d0*dens**0.0195  !! Evaporation temperature
     ! No dust grains above Tevap
     rosseland_ana = rosseland_params(1)*(dens**rosseland_params(2))*(min(Tp,Tevap)**rosseland_params(3))

     !# RMR ## Sublimation mimicked by a d/g ratio that decreases as a arctan function centered on Tevap ##
     rosseland_ana = rosseland_ana*(0.5d0 - 1./pi*atan(0.01d0*(Tp - Tevap) ) ) & !ross_ana contains the d/g ratio of 0.01
          + dens*0.01d0*(1.0d0-0.01d0*(0.5d0 - 1./pi*atan(0.01d0*(Tp - Tevap) ) )) !=> quasi full gas
  else
     rosseland_ana = rosseland_params(1)*(dens**rosseland_params(2))*(Tp**rosseland_params(3))
  endif

end function rosseland_ana