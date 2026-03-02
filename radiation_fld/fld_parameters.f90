module fld_parameters
   use amr_parameters, only:dp
   use hydro_parameters, only:ngrp

  ! Boundaries for frequency groups (in Hz)
  real(dp), dimension(1:ngrp)::nu_min_hz ! minimum freq of given group in Hz
  real(dp), dimension(1:ngrp)::nu_max_hz ! maximum freq of given group in Hz

end module fld_parameters