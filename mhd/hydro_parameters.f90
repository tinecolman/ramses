module hydro_parameters
  use amr_parameters

  ! Number of independant variables
#ifndef NENER
  integer,parameter::nener=0
#else
  integer,parameter::nener=NENER
#endif
#ifndef NGRP
  integer,parameter::ngrp=0   ! Number of radiative energy groups
#else
  integer,parameter::ngrp=NGRP
#endif
#if USE_M_1==0
  integer,parameter::nrad=ngrp          ! Number of pure radiative variables (= radiative energies)
  integer,parameter::nvar_bicg=nrad     ! Number of variables in BICG (= radiative variables)
#endif
#if USE_M_1==1
  integer,parameter::nrad=(1+ndim)*ngrp  ! Number of pure radiative variables (= radiative energies + radiative fluxes)
  integer,parameter::nvar_bicg=nrad+1    ! Number of variables in BICG (= temperature + radiative variables)
#endif
  integer,parameter::nvar_trad=nrad+1   ! Total number of radiative variables (= temperature + radiative energies)

#if NEXTINCT > 0
  integer,parameter::nextinct = NEXTINCT       ! Add a variable to store extinction coefficient
#else
  integer,parameter::nextinct = 0
#endif

  ! Advect internal energy as a passive scalar, in a supplementary index
#ifndef NPSCAL
  integer,parameter::npscal=1
#else
  integer,parameter::npscal=NPSCAL
#endif
! Cosmic rays energy groups
#ifndef NCR
  integer,parameter::ncr=0
#else
  integer,parameter::ncr=NCR
#endif

  integer,parameter::nent=nener-ngrp      ! Number of non-thermal energies
#if USE_M_1==0
  integer,parameter::nfr = 0              ! Number of radiative fluxes for M1
#else
  integer,parameter::nfr =ndim*ngrp       ! Number of radiative fluxes for M1
#endif

  ! First index of variables (in fact index just before the first index)
  ! so that we can loop over 1,nener for instance
  integer,parameter::firstindex_ent=8     ! for non-thermal energies
!  integer,parameter::firstindex_er=8+nent ! for radiative energies
!  integer,parameter::firstindex_fr=8+nener ! for radiative fluxes (if M1)


#ifdef NIONS
  integer,parameter::firstindex_pscal=8+nent+NIONS ! for passive scalars
#else
  integer,parameter::firstindex_pscal=8+nent ! for passive scalars
#endif
  

  integer::lastindex_pscal ! last index for passive scalars other than internal energy


  ! Initialize NVAR
#ifndef NVAR
  integer,parameter::nvar=8+nent+nrad+nextinct+npscal
#else
  integer,parameter::nvar=NVAR
#endif


!check the Makefile for consistencies
  !the extinction variables are put at the end say typically nvar-1 and nvar 
  integer,parameter::firstindex_extinct=nvar + 1 - nextinct ! for extinction

  ! Size of hydro kernel
  integer,parameter::iu1=-1
  integer,parameter::iu2=+4
  integer,parameter::ju1=(1-ndim/2)-1*(ndim/2) !integer division
  integer,parameter::ju2=(1-ndim/2)+4*(ndim/2)
  integer,parameter::ku1=(1-ndim/3)-1*(ndim/3)
  integer,parameter::ku2=(1-ndim/3)+4*(ndim/3)
  integer,parameter::if1=1
  integer,parameter::if2=3
  integer,parameter::jf1=1
  integer,parameter::jf2=(1-ndim/2)+3*(ndim/2)
  integer,parameter::kf1=1
  integer,parameter::kf2=(1-ndim/3)+3*(ndim/3)

  ! Imposed boundary condition variables
  real(dp),dimension(1:MAXBOUND,1:nvar+3)::boundary_var
  real(dp),dimension(1:MAXBOUND)::d_bound=0.0d0
  real(dp),dimension(1:MAXBOUND)::p_bound=0.0d0
  real(dp),dimension(1:MAXBOUND)::u_bound=0.0d0
  real(dp),dimension(1:MAXBOUND)::v_bound=0.0d0
  real(dp),dimension(1:MAXBOUND)::w_bound=0.0d0
  real(dp),dimension(1:MAXBOUND)::A_bound=0.0d0
  real(dp),dimension(1:MAXBOUND)::B_bound=0.0d0
  real(dp),dimension(1:MAXBOUND)::C_bound=0.0d0
#if NENER>0
  real(dp),dimension(1:MAXBOUND,1:NENER)::prad_bound=0.0
#endif
#if NVAR>8+NENER
  real(dp),dimension(1:MAXBOUND,1:NVAR-8-NENER)::var_bound=0.0
#endif

  ! Refinement parameters for hydro
  real(dp)::err_grad_d=-1.0  ! Density gradient
  real(dp)::err_grad_u=-1.0  ! Velocity gradient
  real(dp)::err_grad_p=-1.0  ! Pressure gradient
  real(dp)::err_grad_A=-1.0  ! Bx gradient
  real(dp)::err_grad_B=-1.0  ! By gradient
  real(dp)::err_grad_C=-1.0  ! Bz gradient
  real(dp)::err_grad_B2=-1.0 ! B L2 norm gradient
  real(dp)::floor_d=1d-10   ! Density floor
  real(dp)::floor_u=1d-10   ! Velocity floor
  real(dp)::floor_p=1d-10   ! Pressure floor
  real(dp)::floor_A=1d-10   ! Bx floor
  real(dp)::floor_B=1d-10   ! By floor
  real(dp)::floor_C=1d-10   ! Bz floor
  real(dp)::floor_b2=1d-10  ! B L2 norm floor
  real(dp)::mass_sph=0.0D0   ! mass_sph
  !!! FlorentR - PATCH Temperature extrema
  real(dp)::temp_max = 1d99
!!! FRenaud
#if NENER>0
  real(dp),dimension(1:NENER)::err_grad_prad=-1.0
#endif
#if NVAR>8+NENER
  real(dp),dimension(1:NVAR-8-NENER)::err_grad_var=-1.0
#endif
  real(dp),dimension(1:MAXLEVEL)::jeans_refine=-1.0

  ! Initial condition parameter
  character(LEN=10)::condinit_kind =''
  ! Initial conditions hydro variables
  real(dp),dimension(1:MAXREGION)::d_region=0.
  real(dp),dimension(1:MAXREGION)::u_region=0.
  real(dp),dimension(1:MAXREGION)::v_region=0.
  real(dp),dimension(1:MAXREGION)::w_region=0.
  real(dp),dimension(1:MAXREGION)::p_region=0.
  real(dp),dimension(1:MAXREGION)::A_region=0.
  real(dp),dimension(1:MAXREGION)::B_region=0.
  real(dp),dimension(1:MAXREGION)::C_region=0.
#if NENER>0
  real(dp),dimension(1:MAXREGION,1:NENER)::prad_region=0.0
#endif
#if NVAR>8+NENER
  real(dp),dimension(1:MAXREGION,1:NVAR-8-NENER)::var_region=0.0
#endif

  ! Hydro solver parameters
  integer ::niter_riemann=10
  integer ::slope_type=1
  integer ::slope_mag_type=-1
  real(dp)::slope_theta=1.5d0
  real(dp)::gamma=1.4d0
  real(dp),dimension(1:512)::gamma_rad=1.33333333334d0
  real(dp)::courant_factor=0.5d0
  real(dp)::difmag=0.0d0
  real(dp)::smallc=1d-10
  real(dp)::smallr=1d-10
  real(dp)::eta_mag=0.0d0
  character(LEN=10)::scheme='muscl'
  character(LEN=10)::riemann='llf'
  character(LEN=10)::riemann2d='llf'
  logical ::allow_switch_solver=.false.   ! enable on the fly switching 1D riemann solver hll or hlld to llf to prevent numerical crash
  logical ::allow_switch_solver2D=.false. ! switching for 2D riemann solver hlld to llf (checks only minimum density, needed in cosmology)
  real(dp)::switch_solv_B=1d20            ! value of B_tot**2/P above which to switch solver
  real(dp)::switch_solv_dens=1d20         ! switch solver when density discontinuity is larger than this factor
  real(dp)::switch_solv_min_dens=1d-20    ! switch solver when density is smaller than this value [c.u.]
  integer ::ischeme=0
  integer ::iriemann=0
  integer ::iriemann2d=0

  ! Interpolation parameters
  integer ::interpol_var=0
  integer ::interpol_type=1
  integer ::interpol_mag_type=-1

  ! EXTINCTION RELATED PARAMETERS
  ! get_dx
  real(dp)                 :: pi_g           !pi for a global calculation (done in cooling_fine)
  real(dp),dimension(1:4)  :: mod13
  real(dp),dimension(1:4)  :: mod23
  real(dp),allocatable, dimension(:,:,:,:)   :: xalpha
  !  integer, allocatable, dimension(:,:,:)     :: dirM, dirN
  integer ,allocatable, dimension(:,:)       :: Mdirection, Ndirection
  integer ,allocatable, dimension(:,:,:,:)   :: dirM_ext, dirN_ext, dirMN_ext
  real(dp),allocatable, dimension(:,:)       :: Mdx_cross_int
  real(dp),allocatable, dimension(:,:,:,:)   :: Mdx_cross_loc
  real(dp),allocatable, dimension(:,:,:,:,:) :: Mdx_ext
  logical ,allocatable, dimension(:,:,:,:,:) :: Mdx_ext_logical

  ! Passive variables index
  integer::imetal=9
  integer::idelay=9
  integer::ixion=9
  integer::ichem=9
  integer::ivirial1=9
  integer::ivirial2=9
  integer::inener=9

!!! BrucyN - rho_floor
  logical  :: rho_floor  = .false.  ! whether to set a minimal value (equal to smallr) to density
!!! NBrucy


  ! Column density module (Valdivia & Hennebelle 2014)
  integer::NdirExt_m=3       ! Theta directions for screening
  integer::NdirExt_n=4       ! Phi directions for screening


  !threshold to take into account the screening 
  !dist_screen is expressed in fraction in boxlen
  real(dp)::dist_screen=1.


end module hydro_parameters
