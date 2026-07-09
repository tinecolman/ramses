module nimhd_parameters
  use amr_parameters

  logical :: nambipolar = .false. ! flag to activate ambipolar diffusion
  logical :: nmagdiffu  = .false. ! flag to activate magnetic  diffusion
  logical :: use_nonideal_mhd = .false.     ! true if any of the non-ideal MHD effects is used

  logical :: nimhdheating_in_flux = .true. ! flag to activate the non-ideal mhd energy fluxes
  logical :: nimhdheating_source_term = .false. ! flag to activate the non-ideal mhd heating as a source term

  ! Resistivity parameters
  integer :: resistivity_method=0     ! How to determine the resistivity
                                      ! resistivity_method=0  -> use fixed value
                                      ! resistivity_method=1  -> use analytical model
                                      ! resistivity_method=2  -> use tabulated values from resnh.dat
  character(LEN=80) :: resistivity_file="resnh.dat"
  ! Mellon & Li 2009 (?) or Hennebelle & Teyssier 2007
  ! WARNING this value is in CGS. The connection with user units
  ! is made in function gammaadbis
  real(dp):: gammaAD=1.0d0            ! ambipolar diffusion coefficient (beta = 1/(gammaAD*rho))
  real(dp):: rho_threshold=1d-10     ! safeguard for the ambipolar flux in high density contrast cases (in code units)
  ! useful to restrict ambipolar diff in low rho regions
  ! rename rho_min_AD or something
  real(dp):: etaMD=1d0                ! Ohmic (magnetic) diffusion coefficient
  real(dp), parameter:: H2_fraction = 0.844d0 !remove ! H2 fraction in number of particules (equals 0.73 in mass)
! WARNING !! Think to change xmolaire if proportion are changed
  
  ! timestep regulation
  real(dp):: coefad = 0.1d0    ! CFL condition for ambipolar diffusion
  real(dp):: coefohm = 0.05d0  ! CFL condition for ohmic dissipation
  logical :: nimhd_dt_cap = .false.  ! flag to activate timestep limitation hack (artificailly increase it)
  real(dp):: frac_dt_cap_ad = 1d-10  ! If capping dt: maximal ratio between ambipolar diffusion timestep and ideal MHD timestep.
  real(dp):: frac_dt_cap_ohm = 1d-10 ! same as frac_dt_cap_ad but for Ohmic dissipation.

end module nimhd_parameters
