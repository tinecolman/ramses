module hydro_parameters

#ifdef grackle
  use grackle_parameters
#endif
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
  integer,parameter::nextinct = NEXTINCT       ! Add a variable to store extinction coefficient [0,1]
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
  integer,parameter::firstindex_er=8+nent ! for radiative energies
  integer,parameter::firstindex_fr=8+nener ! for radiative fluxes (if M1)
  integer,parameter::firstindex_extinct=8+nent+nrad ! for extinction
  integer,parameter::firstindex_pscal=8+nent+nrad+nextinct ! for passive scalars
  integer::lastindex_pscal ! last index for passive scalars other than internal energy
  ! Initialize NVAR
#ifndef NVAR
  integer,parameter::nvar=ndim+2+nent+nrad+nextinct+npscal
#else
  integer,parameter::nvar=NVAR
#endif
  ! Size of hydro kernel
  integer,parameter::iu1=-1
  integer,parameter::iu2=+4
  integer,parameter::ju1=(1-ndim/2)-1*(ndim/2)
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
  real(dp),dimension(1:MAXBOUND,1:nvar)::boundary_var
  real(dp),dimension(1:MAXBOUND)::d_bound=0
  real(dp),dimension(1:MAXBOUND)::p_bound=0
  real(dp),dimension(1:MAXBOUND)::u_bound=0
  real(dp),dimension(1:MAXBOUND)::v_bound=0
  real(dp),dimension(1:MAXBOUND)::w_bound=0
#if NENER>0
  real(dp),dimension(1:MAXBOUND,1:NENER)::prad_bound=0
#endif
#if NVAR>NDIM+2+NENER
  real(dp),dimension(1:MAXBOUND,1:NVAR-NDIM-2-NENER)::var_bound=0
#endif
  ! Refinement parameters for hydro
  real(dp)::err_grad_d=-1.0d0  ! Density gradient
  real(dp)::err_grad_u=-1.0d0  ! Velocity gradient
  real(dp)::err_grad_p=-1.0d0  ! Pressure gradient
  real(dp)::floor_d=1d-10     ! Density floor
  real(dp)::floor_u=1d-10     ! Velocity floor
  real(dp)::floor_p=1d-10     ! Pressure floor
  real(dp)::mass_sph=0.0d0     ! mass_sph
!!! FlorentR - PATCH Temperature extrema
  real(dp)::temp_max = 1d99
!!! FRenaud
#if NENER>0
  real(dp),dimension(1:NENER)::err_grad_prad=-1
#endif
#if NVAR>NDIM+2+NENER
  real(dp),dimension(1:NVAR-NDIM-2)::err_grad_var=-1
#endif
  real(dp),dimension(1:MAXLEVEL)::jeans_refine=-1

  ! Initial condition parameter
  character(LEN=10)::condinit_kind =''

  ! Initial conditions hydro variables
  real(dp),dimension(1:MAXREGION)::d_region=0
  real(dp),dimension(1:MAXREGION)::u_region=0
  real(dp),dimension(1:MAXREGION)::v_region=0
  real(dp),dimension(1:MAXREGION)::w_region=0
  real(dp),dimension(1:MAXREGION)::p_region=0
#if NENER>0
  real(dp),dimension(1:MAXREGION,1:NENER)::prad_region=0
#endif
#if NVAR>NDIM+2+NENER
  real(dp),dimension(1:MAXREGION,1:NVAR-NDIM-2-NENER)::var_region=0
#endif
  ! Hydro solver parameters
  integer ::niter_riemann=10
  integer ::slope_type=1
  real(dp)::slope_theta=1.5d0
  real(dp)::gamma=1.4d0
  real(dp),dimension(1:512)::gamma_rad=1.33333333334d0
  real(dp)::courant_factor=0.5d0
  real(dp)::difmag=0
  real(dp)::smallc=1.0d-10
  real(dp)::smallr=1.0d-10
  character(LEN=10)::scheme='muscl'
  character(LEN=10)::riemann='llf'

  ! Interpolation parameters
  integer ::interpol_var=0
  integer ::interpol_type=1


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
  integer::imetal=6
  integer::idelay=6
  integer::ixion=6
  integer::ichem=6
  integer::ivirial1=6
  integer::ivirial2=6
  integer::inener=6

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
