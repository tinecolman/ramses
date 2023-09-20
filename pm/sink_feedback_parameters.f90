module sink_feedback_parameters
  use amr_parameters,only:dp

  ! STELLAR_PARAMS namelist: parameters for spawning stellar particles

  integer:: nstellarmax                   ! maximum number of stellar objects
  real(dp):: imf_index, imf_low, imf_high ! power-law IMF model: PDF index (dN/dM), lower and higher mass bounds (Msun)
  ! Stellar lifetime model: t(M) = lt_t0 * exp(lt_a * (log(lt_m0 / M))**lt_b)
  ! default: Woosley et al 2002
  real(dp):: lt_t0=3.26515722d0   !Myr
  real(dp):: lt_m0=148.158972d0   !Msun
  real(dp):: lt_a=0.23840797d0
  real(dp):: lt_b=2.20522946d0

  character(LEN=100)::stellar_strategy='local' ! local: create stellar particles from each sink
                                               ! global: create when the total mass in sinks exceeds stellar_msink_th
  real(dp):: stellar_msink_th                  ! sink mass threshold for stellar object creation (Msun)

  real(dp):: rstar_init=2.5            ! Initial radius of the protostar in Rsun
  ! Allow users to pre-set stellar mass selection for physics comparison runs, etc
  ! Every time mstellar is added to, instead of a random value, use mstellarini
  integer,parameter::nstellarini=100
  real(dp),dimension(nstellarini)::mstellarini ! List of stellar masses to use

  ! STELLAR_PARAMS namelist: SN feedback parameters

  logical::sn_feedback_sink = .false. !SN feedback emanates from the sink
  logical::sn_direct = .false.        ! explode immediately instead of after lifetime

  real(dp):: sn_e_ref=1.d51      ! SN energy for forcing by sinks [erg]
  real(dp):: sn_p_ref=4.d43      ! SN momentum [g cm/s] for 10 H/cc (Iffrig and Hennebelle 2015)

  real(dp):: Tsat=1d99    ! maximum temperature in SN remnants
  real(dp):: Vsat=1d99    ! maximum velocity in SN remnants
  real(dp):: sn_r_sat=0d0 ! minimum radius for SN remnant

  real(dp):: Vdisp=1d0    ! dispersion velocity of the stellar objects [km/s] 
                          ! determines how far SN can explode from the sink

  logical::stellar_info=.true.  ! write stellar particles to log file

  ! SN parameters for density peak SN
  ! is the frequency at which supernova are damped in the densest cell
  ! of the simulation when parameter use_sn_nopart is on
  real(dp) :: sn_freq_mult = 0.
  logical  :: use_sn_nopart=.false. 
  !efficacity of the supernova used in make_sn (i.e. damped in densest cell 
  real(dp):: eff_sn=0.05
  real(dp):: t_last_sn=0.
  real(dp):: sn_min_dens=10 !minimum density to put a supernovae
  real(dp):: sn_r_min=12    !impose a minimum size of 12 pc for the radius
  real(dp):: sn_mass_ref = 2d33

  ! STELLAR_PARAMS namelist: HII feedback parameters

  ! Stellar ionizing flux model: S(M) = stf_K * (M / stf_m0)**stf_a / (1 + (M / stf_m0)**stf_b)**stf_c
  ! This is a fit from Vacca et al. 1996
  ! Corresponding routine : vaccafit
  real(dp)::stf_K=9.634642584812752d48 ! s**(-1) then normalised in code units in read_stellar
  real(dp)::stf_m0=2.728098824280431d1 ! Msun then normalised in code units in read_stellar
  real(dp)::stf_a=6.840015602892084d0
  real(dp)::stf_b=4.353614230584390d0
  real(dp)::stf_c=1.142166657042991d0 

  real(dp):: hii_t=0 !fiducial HII region lifetime [yr?], it is normalised in code units in read_stellar
  integer:: feedback_photon_group=-1 ! index of the photon group where to put the radiation

  ! commons

  ! stellar object arrays
  integer:: nstellar = 0 ! current number of stellar objects
  real(dp), allocatable, dimension(:):: mstellar, tstellar, ltstellar ! mass, birth time, life time
  integer, allocatable, dimension(:):: id_stellar                     !the id  of the sink to which it belongs

  !ADDED BY PH 29082023
!  character(LEN=15)::feedback_scheme='protostel_jets'
  logical::jets_feedback_sink = .false. !protostellar feedback emanates from the sink
  real(dp)::v_jets_frac=0.333                ! fraction of liberation velocity for protostellar jets    

  !---------------------------------------------------------------------
  ! TC: Everything below here is currently not used. Leave in for future
  !     reference. Deals with fixed feedback sources.

  !     hii_w: density profile exponent (n = n_0 * (r / r_0)**(-hii_w))
  !     hii_alpha: recombination constant in code units
  !     hii_c: HII region sound speed
  !     hii_t: fiducial HII region lifetime, it is normalised in code units in read_stellar 
  !     hii_T2: HII region temperature
  real(dp):: hii_w, hii_alpha, hii_c, hii_T2
  ! TC: these are nowhere in the code.

  ! Use the supernova module?
  logical::FB_on = .false.

  !series of supernovae specified by "hand"
  ! Number of supernovae (max limit and number active in namelist)
  integer,parameter::NSNMAX=5 !TC: limit amount of memory overhead by keeping these in the code
  integer::FB_nsource=0

  ! Location of single star module tables
  character(LEN=200)::ssm_table_directory
  ! Use single stellar module?
  logical::use_ssm=.false.

  ! Type of source ('supernova', 'wind')
  ! NOTE: 'supernova' is a single dump, 'wind' assumes these values are per year
  character(LEN=10),dimension(1:NSNMAX)::FB_sourcetype='supernova'

  ! Feedback start and end times (NOTE: supernova ignores FB_end)
  real(dp),dimension(1:NSNMAX)::FB_start = 1d10
  real(dp),dimension(1:NSNMAX)::FB_end = 1d10
  ! Book-keeping for whether the SN has happened
  logical,dimension(1:NSNMAX)::FB_done = .false.
  
  ! Source position in units from 0 to 1
  real(dp),dimension(1:NSNMAX)::FB_pos_x = 0.5d0
  real(dp),dimension(1:NSNMAX)::FB_pos_y = 0.5d0
  real(dp),dimension(1:NSNMAX)::FB_pos_z = 0.5d0

  ! Ejecta mass in solar masses (/year for winds)
  real(dp),dimension(1:NSNMAX)::FB_mejecta = 1.d0

  ! Energy of source in ergs (/year for winds)
  real(dp),dimension(1:NSNMAX)::FB_energy = 1.d51

  ! Use a thermal dump? (Otherwise add kinetic energy)
  ! Note that if FB_radius is 0 it's thermal anyway
  logical,dimension(1:NSNMAX)::FB_thermal = .false.

  ! Radius to deposit energy inside in number of cells (at highest level)
  real(dp),dimension(1:NSNMAX)::FB_radius = 12d0

  ! Radius in number of cells at highest level to refine fully around SN
  integer,dimension(1:NSNMAX)::FB_r_refine = 10

  ! Timestep to ensure winds are deposited properly
  ! NOT A USER-SETTABLE PARAMETER
  real(dp),dimension(1:NSNMAX)::FB_dtnew = 0d0

  ! Is the source active this timestep? (Used by other routines)
  ! NOT A USER-SETTABLE PARAMETER
  logical,dimension(1:NSNMAX)::FB_sourceactive = .false. 

end module sink_feedback_parameters

