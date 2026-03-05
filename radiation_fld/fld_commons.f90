module fld_commons
   use amr_parameters, only:dp

   real(dp),allocatable,dimension(:,:)::frad     ! Radiative force

   ! Variables for bi-CG scheme
   real(dp),dimension(:,:,:  ),allocatable :: var_bicg
   real(dp),dimension(:,:    ),allocatable :: kappaR_bicg

   real(dp),dimension(:,:,:  ),allocatable :: precond_bicg
   real(dp),dimension(:,:,:,:),allocatable :: coeff_glob_left,coeff_glob_right
  real(dp),dimension(:,:,:  ),allocatable :: mat_residual_glob
  real(dp),dimension(:,:    ),allocatable :: residual_glob

  real(dp),dimension(:),allocatable :: temperature_array
  real(dp),dimension(:),allocatable :: cv_array

  real(dp)   ::dt_imp                            ! Implicit timestep               
  integer,allocatable,dimension(:)::liste_ind
  integer::nb_ind


end module fld_commons