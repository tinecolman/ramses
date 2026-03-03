module fld_parameters
   use amr_parameters, only:dp
   use hydro_parameters, only:ngrp
   use constants, only:a_r

   ! Boundaries for frequency groups (in Hz)
   real(dp),dimension(1:ngrp)::nu_min_hz ! minimum freq of given group in Hz
   real(dp),dimension(1:ngrp)::nu_max_hz ! maximum freq of given group in Hz

   ! numerical limits
   real(dp),parameter::Tray_min=0.5d0 ! Minimum temperature in the radiative energy
   real(dp),parameter::eray_min=(a_r)*Tray_min**4 ! minimum rad energy inside frequency group
   !real(dp),parameter::deray_min=(4.0d0*a_r)*Tray_min**3 ! minimum rad energy derivative inside frequency group
   !real(dp):: small_er=1.0d-30       ! minimum rad energy inside frequency group in code units

   ! Tabulated black body radiative energy 
   integer::Ninv_art4=1000                               ! Number of points in tabulated arT4 function
   real(dp),dimension(:    ),allocatable::dEr_inv_art4   ! Radiative energy increment
   real(dp),dimension(:,:  ),allocatable::inverse_art4_T ! array for tabulated arT4 function dT regular
   real(dp),dimension(:,:,:),allocatable::inverse_art4_E ! array for tabulated arT4 function dE regular

   ! Radiation solver parameters
   integer::i_fld_limiter
   integer,parameter::i_fld_limiter_nolim=0
   integer,parameter::i_fld_limiter_minerbo=1
   integer,parameter::i_fld_limiter_levermore=2

   ! Opacity
   logical :: sublimation_kuiper=.false. ! Mimicks dust sublimation with decreasing d/g ratio, see Kuiper+10 ApJ
   real(dp),dimension(1:3)::rosseland_params=1.0     ! Rosseland opacity coefficient's parameters


end module fld_parameters