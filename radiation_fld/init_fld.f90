subroutine init_fld
   use amr_commons, only:ncoarse
   use amr_parameters, only:twotondim,ngridmax,ndim
   use hydro_parameters, only:ngrp
   use fld_parameters, only:store_matrix
   use fld_commons
   implicit none
   !------------------------------
   ! Initialize variables for FLD
   !------------------------------
   integer::ncell

   ! 
   call tabulate_art4

   ! allocate global arrays
   ncell=ncoarse+twotondim*ngridmax  
   allocate(frad(1:ncell,1:ndim))
   frad=0.0d0

   allocate(precond_bicg(1:ncell,1:ngrp,1:ngrp))
 precond_bicg=0.0d0

  if(store_matrix) then
     allocate(mat_residual_glob(1:ncell,1:ngrp,1:ngrp),residual_glob(1:ncell,1:ngrp))
     allocate(coeff_glob_left(1:ncell,1:ngrp,1:ngrp,1:ndim),coeff_glob_right(1:ncell,1:ngrp,1:ngrp,1:ndim))
  else
     allocate(mat_residual_glob(1,1:ngrp,1:ngrp),residual_glob(1,1:ngrp))
     allocate(coeff_glob_left(1,1:ngrp,1:ngrp,1:ndim),coeff_glob_right(1,1:ngrp,1:ngrp,1:ndim))
  endif
  mat_residual_glob=0.0d0;residual_glob=0.0d0
  coeff_glob_left=0.0d0;coeff_glob_right=0.0d0


end subroutine init_fld