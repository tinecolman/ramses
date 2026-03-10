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

   ! Variables for BICG scheme
   ! 1 : r
   ! 2 : p
   ! 3 : r*
   ! 4 : M-1
   ! 5 : 
   ! 6 : z and Ap
   ! 7 : p*
   ! 8 : p*A
   ! 9 : z*
   allocate(kappaR_bicg(1:ncell,1:ngrp))
   ! if FLD: matrix of size ngrpxngrp (because matrix only on Eg)
   allocate(var_bicg(1:ncell,1:ngrp,1:10+2*ndim))
   allocate(precond_bicg(1:ncell,1:ngrp,1:ngrp))
   if(store_matrix) then
      allocate(mat_residual_glob(1:ncell,1:ngrp,1:ngrp),residual_glob(1:ncell,1:ngrp))
      allocate(coeff_glob_left(1:ncell,1:ngrp,1:ngrp,1:ndim),coeff_glob_right(1:ncell,1:ngrp,1:ngrp,1:ndim))
   else
      allocate(mat_residual_glob(1,1:ngrp,1:ngrp),residual_glob(1,1:ngrp))
      allocate(coeff_glob_left(1,1:ngrp,1:ngrp,1:ndim),coeff_glob_right(1,1:ngrp,1:ngrp,1:ndim))
   endif
   kappar_bicg=0.0d0;var_bicg=0.0d0;precond_bicg=0.0d0
   mat_residual_glob=0.0d0;residual_glob=0.0d0
   coeff_glob_left=0.0d0;coeff_glob_right=0.0d0

   allocate(temperature_array_old(1:ncell))  ! contain temperature for solver
   allocate(temperature_array_new(1:ncell))  ! contain temperature for solver
   allocate(cv_array(1:ncell))           ! contain CV for solver
   temperature_array_old=0d0
   temperature_array_new=0d0
   cv_array=0d0

end subroutine init_fld