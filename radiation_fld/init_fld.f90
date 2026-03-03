subroutine init_fld
   use amr_commons, only:ncoarse
   use amr_parameters, only:twotondim,ngridmax,ndim
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

end subroutine init_fld