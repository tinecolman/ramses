!##################################################################################################
!##################################################################################################
!##################################################################################################
!##################################################################################################

!  Function ROSSELAND_ANA:
!
!> Compute Rosseland mean opacity.
!<
function rosseland_ana(dens,Tp,Tr,igroup)

  use amr_commons
  use fld_parameters
  use constants, only:pi

  implicit none

  integer ,intent(in)    :: igroup
  real(dp),intent(in)    :: dens,Tp,Tr
  real(dp)               :: rosseland_ana,Tgd
  real(dp)               :: Tevap ! if sublimation_kuiper
  real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v
  ! Conversion factor from user units to cgs units
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

  if(sublimation_kuiper) then
     !# RMR #### Sublimation of dust grains as in kuiper+10 ApJ ####
     !### The highest dust temperature is the evaporation temperature
     !### Opacities are taken at this temperature
     !### The input temperature is kept to compute the d/g ratio
     Tgd = Tp
     Tevap = 2000.0d0*dens**0.0195  !! Evaporation temperature
     if(Tp .gt. Tevap) Tgd = Tevap
  endif

  if(sublimation_kuiper) then !! No dust grains above Tevap
     rosseland_ana = rosseland_params(1)*(dens**rosseland_params(2))*(Tgd**rosseland_params(3))
  else
     rosseland_ana = rosseland_params(1)*(dens**rosseland_params(2))*(Tp**rosseland_params(3))
  endif

  if(sublimation_kuiper) then
     !# RMR ## Sublimation mimicked by a d/g ratio that decreases as a arctan function centered on Tevap ##
     rosseland_ana = rosseland_ana*(0.5d0 - 1./pi*atan(0.01d0*(Tp - Tevap) ) ) & !ross_ana contains the d/g ratio of 0.01
          +dens*0.01d0*(1.0d0-0.01d0*(0.5d0 - 1./pi*atan(0.01d0*(Tp - Tevap) ) )) !=> quasi full gas
  endif

  !if (sinks_opt_thin .and. insink) rosseland_ana = min_optical_depth/(0.5D0**nlevelmax*boxlen*scale_l)

end function rosseland_ana