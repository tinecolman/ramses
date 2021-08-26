#if USE_TURB==1
module turb_parameters
  use amr_parameters

  integer, parameter  :: ILP = selected_int_kind(r=15) ! integer long precision

  ! Precision string
#ifndef NPRE
  integer,parameter::cdp=kind((1.0E0, 1.0E0)) ! default
  character(len=16), parameter :: precision_str='SINGLE_PRECISION'
#else
#if NPRE==4
  integer,parameter::cdp=kind((1.0E0, 1.0E0)) ! complex*4
  character(len=16), parameter :: precision_str='SINGLE_PRECISION'
#else
  integer,parameter::cdp=kind((1.0D0, 1.0D0)) ! complex*8
  character(len=16), parameter :: precision_str='DOUBLE_PRECISION'
#endif
#endif

  ! Turbulence variables
  integer, parameter  :: TURB_GS=64                    ! Turbulent grid size
  integer, parameter  :: TGRID_X=TURB_GS-1             ! Limit of grid, x dimension
#if NDIM>1
  integer, parameter  :: TGRID_Y=TURB_GS-1             ! Limit of grid, x dimension
#else
  integer, parameter  :: TGRID_Y=0                     ! Limit of grid, x dimension
#endif
#if NDIM>2
  integer, parameter  :: TGRID_Z=TURB_GS-1             ! Limit of grid, x dimension
#else
  integer, parameter  :: TGRID_Z=0                     ! Limit of grid, x dimension
#endif
  real(dp), parameter :: turb_gs_real=real(TURB_GS,dp) ! real(TURB_GS, dp)

  logical  :: turb=.FALSE.        ! Use turbulence?
  integer  :: turb_type=1         ! Turbulence type
                                  ! 1 = forced, evolving turbulence
                                  ! 2 = forced, fixed turbulence
                                  ! 3 = decaying turbulence
  integer  :: turb_seed=-1        ! Turbulent seed (-1=random)
  logical  :: instant_turb=.TRUE. ! Generate initial turbulence before start?
  character (LEN=100) :: forcing_power_spectrum='parabolic'
                                  ! Power spectrum type of turbulent forcing

  real(dp) :: comp_frac=0.3333_dp ! Compressive fraction
  real(dp) :: turb_T=1.0_dp       ! Turbulent velocity autocorrelation time
  integer  :: turb_Ndt=100        ! Number of timesteps per autocorr. time
  real(dp) :: turb_rms=1.0_dp     ! rms turbulent forcing acceleration

  real(dp) :: turb_min_rho=1d-50  ! Minimum density for turbulence

  real(dp) :: turb_kx_min=-TURB_GS/2        ! Minimum driving mode in the x direction
  real(dp) :: turb_kx_max=TURB_GS/2        ! Maximum driving mode in the x direction
  real(dp) :: turb_ky_min=-TURB_GS/2        ! Minimum driving mode in the y direction
  real(dp) :: turb_ky_max=TURB_GS/2        ! Maximum driving mode in the y direction
  real(dp) :: turb_kz_min=-TURB_GS/2        ! Minimum driving mode in the z direction
  real(dp) :: turb_kz_max=TURB_GS/2        ! Maximum driving mode in the z direction
  real(dp) :: turb_k_min=0         ! Minimum total driving mode, taken into account after selecting modes in each direction
  real(dp) :: turb_k_max=TURB_GS         ! Maximum total driving mode
  logical  :: turb1D=.false.             ! drive only in the x direction (vy=vz=0)
  logical  :: turb2D=.false.             ! drive only in the x and y direction (vz=0)
  real(dp) :: turb_power_law_slope=-2    ! slope of the power law spectrum P=k**slope
  real(dp) :: turb_parabolic_center=2    ! center of parabola spectrum b, P = 1 - a (k-b)**2
  real(dp) :: turb_parabolic_width=1     ! determines the zero point of the parabola
                                         ! width = sqrt(1/a)
                                         ! width <= center to satisfy P>=0

end module turb_parameters
#endif