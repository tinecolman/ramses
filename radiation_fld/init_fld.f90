subroutine init_fld
   use amr_commons, only:ncoarse
   use amr_parameters, only:twotondim,ngridmax,ndim
   use hydro_parameters, only:ngrp
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


end subroutine init_fld