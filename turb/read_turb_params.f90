#if USE_TURB==1
subroutine read_turb_params(nml_ok)
  use amr_commons
  use turb_commons
  implicit none
  logical, intent(inout) ::nml_ok
  !--------------------------------------------------
  ! Local variables
  !--------------------------------------------------
  integer       :: ierr          ! Error variable
  integer, dimension(6) :: k_limit ! array for looping over kmin and kmax
  integer       :: i

  !--------------------------------------------------
  ! Namelist definitions
  !--------------------------------------------------
  namelist/turb_params/turb, turb_seed, turb_type, instant_turb, comp_frac,&
       & forcing_power_spectrum, turb_T, turb_Ndt, turb_rms, turb_min_rho,&
       & turb_kx_min, turb_kx_max, turb_ky_min, turb_ky_max, turb_kz_min, turb_kz_max,&
       & turb_k_min, turb_k_max, turb1D, turb2D,&
       & turb_parabolic_center, turb_parabolic_width, turb_power_law_slope

  !--------------------------------------------------
  ! Read namelist; check variables that have been loaded
  !--------------------------------------------------

  ! Read namelist file
  rewind(1)
  read(1,NML=turb_params,END=87)

  if (.NOT. turb) return

  if (turb_type < 1 .OR. turb_type > 3) then
     write (*,*) "Invalid turbulence type selected! (1 to 3)"
     nml_ok = .FALSE.
  end if

  ! BUG: upon restart, turb_type 2 gives the wrong rms.
  if (turb_type == 2) then
     write (*,*) "Turbulence type 2 is bugged. Please select 1 instead."
     nml_ok = .FALSE.
  end if

  if (comp_frac < 0.0_dp .OR. comp_frac > 1.0_dp) then
     write (*,*) "Invalid compressive fraction selected! (0.0 to 1.0)"
     nml_ok = .FALSE.
  end if

  if (turb_T <= 0.0_dp) then
     write (*,*) "Turbulent autocorrelation time must be > 0!"
     nml_ok = .FALSE.
  end if

  if (turb_Ndt <= 0) then
     write (*,*) "Number of timesteps per autocorrelation time must be > 0!"
     nml_ok = .FALSE.
  end if

  if (turb_rms <= 0.0_dp) then
     write (*,*) "Turbulent forcing rms acceleration must be > 0.0!"
     nml_ok = .FALSE.
  end if

  if (turb2D) then
     ndimturb = 2
  end if

  k_limit = (/ turb_kx_min, turb_ky_min, turb_kz_min, turb_kx_max, turb_ky_max, turb_kz_max /)
  do i=1,6
     if (k_limit(i) < (-TURB_GS/2) .OR. k_limit(i) > (TURB_GS/2)) then
        write (*,*) "Minimal and maximum turbulent forcing mode must be between 0 and ", TURB_GS/2,"!"
        nml_ok = .FALSE.
     end if
  end do

  if (turb_k_min < 0.0_dp .OR. turb_k_min > (TURB_GS*sqrt(3.0_dp))) then
     write (*,*) "Minimal and maximum total turbulent forcing mode must be between 0 and ", TURB_GS*sqrt(3.0_dp),"!"
     nml_ok = .FALSE.
  end if

  do i=1,3
     if (k_limit(i) > k_limit(i+3)) then
        write (*,*) "Maximal turbulent forcing mode must larger or equal to minimal mode!"
        nml_ok = .FALSE.
     end if
  end do

   if (turb_k_min > turb_k_max) then
        write (*,*) "Maximal turbulent forcing mode must larger or equal to minimal mode!"
        nml_ok = .FALSE.
   end if

   if ((forcing_power_spectrum=='parabolic') .and. (turb_parabolic_width > turb_parabolic_center)) then
      write (*,*) "The width of the parabolic turbulence spectrum should not be larger than the center value!"
      nml_ok = .FALSE.
   end if

87 continue

end subroutine read_turb_params
#endif
