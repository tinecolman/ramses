module fld_commons
   use amr_parameters, only:dp

   real(dp),allocatable,dimension(:,:)::frad     ! Radiative force

   ! Variables for bi-CG scheme
   real(dp),dimension(:,:,:  ),allocatable :: var_bicg
   real(dp),dimension(:,:    ),allocatable :: kappaR_bicg

end module fld_commons