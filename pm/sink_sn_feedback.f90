subroutine make_sn_stellar
  use pm_commons
  use amr_commons
  use hydro_commons
  use sink_feedback_parameters
  use constants, only:pi,pc2cm,mH,M_sun
  use mpi_mod
  implicit none

  integer:: ivar, ilevel, ind, ix, iy, iz, ngrid, iskip, idim
  integer:: i, nx_loc, igrid, ncache
  integer, dimension(1:nvector), save:: ind_grid, ind_cell
  real(dp):: dx, scale, dx_loc, vol_loc
  real(dp), dimension(1:3):: skip_loc
  real(dp), dimension(1:twotondim, 1:3):: xc
  logical, dimension(1:nvector), save:: ok
  real(dp), dimension(1:nvector, 1:ndim), save:: xx
  real(dp):: sn_r, sn_m, sn_p, sn_e, sn_d, sn_ed
  real(dp):: rr,pgas,dgas,ekin
  integer:: info
  real(dp),dimension(1:nvector,1:ndim)::x
  real(dp),dimension(1:3):: xshift, x_sn
  logical, save:: first = .true.
  real(dp), save:: xseed
  real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v
  logical, dimension(1:nstellarmax):: mark_del
  integer:: istellar,isink
  real(dp)::T_sn,sn_ed_lim,pnorm_sn,vol_sn
  real(dp)::mass_sn, mass_sn_all,dens_moy,r_cooling, Tsat_local
  real(dp)::pgas_check,pgas_check_all,egas_check,egas_check_all
  integer, parameter:: navg = 3
  real(dp), dimension(1:3):: avg_center
  real(dp):: avg_radius
  real(dp), dimension(1:navg):: avg_rpow
  real(dp), dimension(1:navg, 1:nvar+3):: avg_upow
  real(dp), dimension(1:navg):: avg
  real(dp):: norm, distance_sn, ekin_before, ekin_after
  logical::r_cooling_resolved=.false.

  if(.not. hydro)return
  if(ndim .ne. 3)return

  if(verbose)write(*,*)'Entering make_sn_stellar'

  if (first) then
     xseed = 0.5
     call random_number(xseed)
     first = .false.
  endif

  ! Mesh spacing in that level
  nx_loc = icoarse_max - icoarse_min + 1
  skip_loc=(/0.0d0,0.0d0,0.0d0/)
  if(ndim>0)skip_loc(1)=dble(icoarse_min)
  if(ndim>1)skip_loc(2)=dble(jcoarse_min)
  if(ndim>2)skip_loc(3)=dble(kcoarse_min)
  scale = boxlen / dble(nx_loc)

  ! Conversion factor from user units to cgs units
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

  ! radius of sphere where we dump the SN energy/momentum/mass (numerical, we choose 3 coarse cells)
  sn_r = 3.0d0*(0.5d0**levelmin)*scale
  ! namelist option to set a minimum radius for the SN remnant
  if(sn_r_sat .ne. 0) sn_r = max(sn_r, sn_r_sat * pc2cm / scale_l)

  ! we assume the SN energy and momentum is always the same
  sn_p = sn_p_ref
  sn_e = sn_e_ref
  Tsat_local = Tsat

  ! Loop over stellar objects to determine whether one is turning supernovae
  ! After the explosion, the object is removed from the list
  mark_del = .false.
  do istellar = 1, nstellar
    if(t - tstellar(istellar) < ltstellar(istellar)) cycle
    mark_del(istellar) = .true.

    ! find corresponding sink
    isink = 1
    do while ((isink.le.nsink) .and. (id_stellar(istellar) .ne. idsink(isink)))
      isink = isink + 1
    end do
    if (isink.gt.nsink) then
      write(*,*)"BUG: COULD NOT FIND SINK"
      call clean_stop
    endif

    ! the mass of the massive star
    sn_m = mstellar(istellar) 

    !remove the mass that is dumped in the grid from the sink
    msink(isink) = msink(isink) - sn_m

    ! maximum distance the massive star could have traveled from the sink
    ! = the velocity dispersion (namelist) times the life time of the object
    distance_sn = ltstellar(istellar)*Vdisp

    ! determine random location within that distance
    ! find a random point within a sphere of radius < 1
    norm=2.
    do while (norm .gt. 1)
       norm=0.
       do idim = 1, ndim
          call random_number(xseed)
          xshift(idim) = (xseed-0.5)*2.
          norm = norm + xshift(idim)**2
       end do
    end do
    do idim = 1, ndim
        ! shift should not be more than half the box size
        xshift(idim) = xshift(idim) * min(distance_sn,0.5d0*boxlen)
    end do

    ! place the supernovae around sink particles
    x_sn(:) = xsink(isink, :) + xshift(:)
    ! if SN went outside the box, just invert the shift (this avoids having to check boundary conditions)
    do idim = 1,ndim
       if( (x_sn(idim) .lt. 0) .or. (x_sn(idim) .gt. boxlen)) x_sn(idim) = xsink(isink, idim) - xshift(idim)
    end do

    ! Now that we have the location of the SN, we check the properties of the surroundings
    avg_center = x_sn
    avg_radius = sn_r
    avg_rpow = 0.0d0
    avg_upow = 0.0d0
    ! avg_rpow(1) = 0 ; avg_upow(1, :) = 0 -> integrand(1) = 1
    ! avg_rpow(2) = 0 ; avg_upow(2, 1) = 1 -> integrand(2) = density
    ! avg_rpow(3) = 1 ; avg_upow(3, :) = 0 -> integrand(3) = radius
    avg_upow(2, 1) = 1.0d0
    avg_rpow(3) = 1.0d0
    call sphere_average(navg, avg_center, avg_radius, avg_rpow, avg_upow, avg)
    vol_sn = avg(1)
    mass_sn = avg(2) + sn_m ! region average + ejecta
    pnorm_sn = avg(3)

    ! density of the gas ejected by the SN, assumed to be distributed uniformly over the SN sphere
    sn_d = sn_m / vol_sn
    ! energy density of SN, assume uniform over SN sphere
    sn_ed = sn_e / vol_sn

    ! average density of gas in SN radius, after explosion (includes ejecta)
    dens_moy = mass_sn / vol_sn
    dens_moy = dens_moy*scale_d/mH !H/cc

    ! estimate cooling radius (Martizzi et al 2015)
    r_cooling = 6.3d0 * pc2cm/scale_l * (dens_moy/100d0)**(-0.42)
    ! if cooling radius resolved -> thermal feedback
    ! else -> momentum feedback
    r_cooling_resolved = (r_cooling > sn_r)
    ! determine SN momentum, see Iffrig and Hennebelle 2015
    ! NOT USED FOR NOW
    !sn_p = sn_p_ref * (dens_moy / 10.)**(-0.117647)

    pgas_check=0
    egas_check=0

    !now loop over cells again and dump energies, mass and momentum
    !loop over levels 
    do ilevel = levelmin, nlevelmax
      ! Computing local volume (important for averaging hydro quantities)
      dx = 0.5d0**ilevel
      dx_loc = dx * scale
      vol_loc = dx_loc**ndim

      ! Cell center position relative to grid center position
      do ind=1,twotondim
        iz = (ind - 1) / 4
        iy = (ind - 1 - 4 * iz) / 2
        ix = (ind - 1 - 2 * iy - 4 * iz)
        xc(ind,1) = (dble(ix) - 0.5d0) * dx
        xc(ind,2) = (dble(iy) - 0.5d0) * dx
        xc(ind,3) = (dble(iz) - 0.5d0) * dx
      end do

      ! Loop over grids
      ncache=active(ilevel)%ngrid
      do igrid = 1, ncache, nvector
        ngrid = min(nvector, ncache - igrid + 1)
        do i = 1, ngrid
          ind_grid(i) = active(ilevel)%igrid(igrid + i - 1)
        end do

        ! Loop over cells
        do ind = 1, twotondim
          ! Gather cell indices
          iskip = ncoarse + (ind - 1) * ngridmax
          do i = 1, ngrid
            ind_cell(i) = iskip + ind_grid(i)
          end do

          ! Gather cell center positions
          do i = 1, ngrid
            xx(i, :) = xg(ind_grid(i), :) + xc(ind, :)
          end do
          ! Rescale position from coarse grid units to code units
          do idim=1,ndim
             do i=1,ngrid
                xx(i,idim)=(xx(i,idim)-skip_loc(idim))*scale
             end do
          end do

          ! Flag leaf cells
          do i = 1, ngrid
            ok(i) = (son(ind_cell(i)) == 0)
          end do

          do i = 1, ngrid
            if(ok(i)) then
                rr = 0.
                do idim=1,ndim
                   rr = rr + ((xx(i,idim) - x_sn(idim)) / sn_r)**2
                enddo
                rr = sqrt(rr)

                ! if cell inside SN sphere, dump fraction of energy and momentum
                if(rr < 1.) then
                  ! add ejecta density
                  uold(ind_cell(i), 1) = uold(ind_cell(i), 1) + sn_d
                  dgas = uold(ind_cell(i), 1)

                  ! momemtum feedback

                  ! compute velocity of the gas within this cell assuming energy equipartition
                  ! limit the velocity using Vsat
                  pgas = min(sn_p / pnorm_sn * rr, Vsat * dgas)
                  pgas_check = pgas_check + pgas * vol_loc

                  ! kinetic energy before SN
                  ekin_before=0.
                  do idim=1,ndim
                    ekin_before = ekin_before + ( (uold(ind_cell(i),idim+1))**2 ) / dgas / 2.
                  enddo

                  ! add momemtum
                  do idim=1,ndim
                     uold(ind_cell(i),idim+1) = uold(ind_cell(i),idim+1) + pgas * (xx(i,idim) - x_sn(idim)) / (rr * sn_r)
                  enddo

                  ! kinetic energy after
                  ekin_after=0.
                  do idim=1,ndim
                    ekin_after = ekin_after + ( (uold(ind_cell(i),idim+1))**2 ) / dgas / 2.
                  enddo

                  ! add extra kinetic energy
                  uold(ind_cell(i), 2+ndim) = uold(ind_cell(i), 2+ndim) + (ekin_after - ekin_before)
                  egas_check = egas_check + (ekin_after - ekin_before) * vol_loc

                  ! Thermal feedback

                  !before adding thermal energy make sure the temperature is not too high (too small timesteps otherwise)
                  T_sn = (sn_ed / dgas * (gamma-1.) ) * scale_T2
                  T_sn = min( T_sn , Tsat_local) / scale_T2
                  sn_ed_lim = T_sn * dgas / (gamma-1.)
                  egas_check = egas_check + sn_ed_lim * vol_loc
                  uold(ind_cell(i), 2+ndim) = uold(ind_cell(i), 2+ndim) + sn_ed_lim

                end if

            end if
          end do
          ! End loop over sublist of cells
        end do
        ! End loop over cells
      end do
      ! End loop over grids
    end do
    ! End loop over levels

#ifndef WITHOUTMPI
    call MPI_ALLREDUCE(pgas_check,pgas_check_all,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,info)
    call MPI_ALLREDUCE(egas_check,egas_check_all,1,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,info)
#else
    pgas_check_all = pgas_check
    egas_check_all = egas_check
#endif

    if(myid == 1) write(*, *) "SN EVENT at", x_sn(1),x_sn(2),x_sn(3), "from sink", idsink(isink),"t=",t
    if(myid == 1) write(*, *) "Resolved?",r_cooling_resolved,"r_cool=",r_cooling,"r_sn=",sn_r,"density=",dens_moy,"starmass=",sn_m*(scale_d*scale_l**3)/M_sun
    if(myid == 1) write(*, *) "momentum (injected, expected)=", pgas_check_all * scale_d * scale_l**3 * scale_v, sn_p * scale_d * scale_l**3 * scale_v
    if(myid == 1) write(*, *) "energy (injected, expected)=", egas_check_all*(scale_d * scale_v**2 * scale_l**3), sn_e*(scale_d * scale_v**2 * scale_l**3)

  end do ! end of the loop over stellar objects

  call delete_stellar(mark_del)

  ! Update hydro quantities for split cells
  do ilevel = nlevelmax, levelmin, -1
    call upload_fine(ilevel)
    do ivar = 1, nvar
      call make_virtual_fine_dp(uold(1, ivar), ilevel)
    enddo
  enddo

end subroutine make_sn_stellar
!################################################################
!################################################################
!################################################################
!################################################################
subroutine sphere_average(navg, center, radius, rpow, upow, avg)
    use amr_parameters, only: boxlen, dp, hydro, icoarse_max, icoarse_min &
        & , jcoarse_min, kcoarse_min, levelmin, ndim, ngridmax, nlevelmax &
        & , nvector, twotondim, verbose
    use amr_commons, only: active, ncoarse, son, xg, myid
    use hydro_parameters, only: nvar
    use hydro_commons, only: uold
    use mpi_mod
    implicit none

    ! Integrate quantities over spheres
    ! The integrand is (r / radius)**rpow(iavg) * product(u(ivar)**upow(iavg, ivar), ivar=1:nvar)

    integer, intent(in):: navg                               ! Number of quantities
    real(dp), dimension(1:ndim), intent(in):: center         ! Sphere center
    real(dp), intent(in):: radius                            ! Sphere radius
    real(dp), dimension(1:navg), intent(in):: rpow           ! Power of radius in the integral
#ifdef SOLVERmhd
    real(dp), dimension(1:navg, 1:nvar+3), intent(in):: upow ! Power of hydro variables in the integral
#else
    real(dp), dimension(1:navg, 1:nvar), intent(in):: upow   ! Power of hydro variables in the integral
#endif
    real(dp), dimension(1:navg), intent(out):: avg           ! Averages

    integer:: i, ivar, ilevel, igrid, ind, ix, iy, iz, iskip, idim
    integer:: nx_loc, ncache, ngrid
    integer, dimension(1:nvector):: ind_grid, ind_cell
    logical, dimension(1:nvector):: ok

    real(dp):: scale, dx, dx_loc, vol_loc, rr
    real(dp), dimension(1:3):: skip_loc
    real(dp), dimension(1:twotondim, 1:3):: xc
    real(dp), dimension(1:nvector, 1:ndim):: xx

    integer:: info
    real(dp), dimension(1:navg):: avg_loc
    real(dp), dimension(1:navg):: integrand
    real(dp), dimension(1:navg):: utemp

    if(.not. hydro)return
    if(ndim .ne. 3)return

    if(verbose .and. myid == 1) write(*, *) 'Entering sphere_average'

    ! Mesh spacing in that level
    nx_loc = icoarse_max - icoarse_min + 1
    skip_loc=(/0.0d0,0.0d0,0.0d0/)
    if(ndim>0)skip_loc(1)=dble(icoarse_min)
    if(ndim>1)skip_loc(2)=dble(jcoarse_min)
    if(ndim>2)skip_loc(3)=dble(kcoarse_min)
    scale = boxlen / dble(nx_loc)

    avg_loc = 0.0d0

    do ilevel = levelmin, nlevelmax
        ! Computing local volume (important for averaging hydro quantities)
        dx = 0.5d0**ilevel
        dx_loc = dx * scale
        vol_loc = dx_loc**ndim

        ! Cell center position relative to grid center position
        do ind = 1, twotondim
            iz = (ind - 1) / 4
            iy = (ind - 1 - 4 * iz) / 2
            ix = (ind - 1 - 2 * iy - 4 * iz)
            if(ndim>0) xc(ind, 1) = (dble(ix) - 0.5d0) * dx
            if(ndim>1) xc(ind, 2) = (dble(iy) - 0.5d0) * dx
            if(ndim>2) xc(ind, 3) = (dble(iz) - 0.5d0) * dx
        end do

        ! Loop over grids
        ncache = active(ilevel)%ngrid
        do igrid = 1, ncache, nvector
            ngrid = min(nvector, ncache - igrid + 1)
            do i = 1, ngrid
                ind_grid(i) = active(ilevel)%igrid(igrid + i - 1)
            end do

            ! Loop over cells
            do ind = 1, twotondim
                ! Gather cell indices
                iskip = ncoarse + (ind - 1) * ngridmax
                do i = 1, ngrid
                    ind_cell(i) = iskip + ind_grid(i)
                end do

                ! Gather cell center positions
                do i = 1, ngrid
                    xx(i, :) = xg(ind_grid(i), :) + xc(ind, :)
                end do

                ! Rescale position from coarse grid units to code units
                do idim=1,ndim
                   do i=1,ngrid
                      xx(i,idim)=(xx(i,idim)-skip_loc(idim))*scale
                   end do
                end do

                ! Flag leaf cells
                do i = 1, ngrid
                    ok(i) = (son(ind_cell(i)) == 0)
                end do

                do i = 1, ngrid
                    if(ok(i)) then
                        rr = sqrt(sum(((xx(i, :) - center) / radius)**2))
                        if(rr < 1.) then
                            integrand = rr**rpow
                            where(abs(rpow) < 1.0d-10) ! Avoid NaNs of the form 0**0
                                integrand = 1.0d0
                            end where
#ifdef SOLVERmhd
                            do ivar = 1, nvar + 3
#else
                            do ivar = 1, nvar
#endif
                                utemp(:) = uold(ind_cell(i), ivar)
                                where(abs(upow(:, ivar)) < 1.0d-10) ! Avoid NaNs of the form 0**0
                                    utemp = 1.0d0
                                end where
                                integrand = integrand * utemp**upow(:, ivar)
                            end do
                            avg_loc = avg_loc + vol_loc * integrand
                        endif
                        ! End test on radius
                    endif
                    ! End test on leaf cells
                end do
                ! End loop over sublist of cells
            end do
            ! End loop over cells
        end do
        ! End loop over grids
    end do
    ! End loop over levels

#ifndef WITHOUTMPI
    call MPI_ALLREDUCE(avg_loc, avg, navg, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, info)
#else
    avg = avg_loc
#endif
end subroutine sphere_average
!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

! THIS SECTION DEALS WITH INDIVIDUAL FIXED SOURCES IN THE NAMELIST
! TC: currently not used but we leave it for future reference

!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
!XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
subroutine feedback_fixed(ilevel)
  use amr_commons
  use hydro_parameters
  use sink_feedback_parameters
  implicit none
  integer::ilevel,isn
  !---------------------
  ! Dump a supernova/winds into cells
  ! NOTE: variables internally still labelled "sn", but valid for winds too
  !---------------------
  ! This check should be done already in amr_step, but best to be sure I suppose
  if(FB_on .and. ilevel == levelmin) then
     ! Reset per-step flags/variables used to signal to other routines
     FB_sourceactive = .false.
     FB_dtnew = 0d0
     do isn=1,FB_nsource
        ! Deal with supernovae
        if(FB_sourcetype(isn) .eq. 'supernova') then
          if(t >= FB_start(isn) .and. .not. FB_done(isn)) then
             ! NOTE: FB_done NOT SAVED BY OUTPUT, SO RELAUNCHING AFTER FB_start WILL LAUNCH SUPERNOVA
             if(myid == 1) write (*,*) 'Supernova ',isn,' @ t = ', t, &
                  & 'FB_start =', FB_start(isn)
             call make_fb_fixed(ilevel,isn)
             FB_done(isn) = .true.
          endif
        endif
        ! Deal with winds
        if(FB_sourcetype(isn) .eq. 'wind') then
          if(t >= FB_start(isn) .and. t <= FB_end(isn)) then
            ! Inject winds
            call make_fb_fixed(ilevel,isn)
            ! Log file book-keeping, wind starts
            if(.not. FB_done(isn)) then
              if(myid == 1) write (*,*) 'Wind started ',isn,' @ t = ', t, &
                    & 'FB_start =', FB_start(isn)
              FB_done(isn) = .true.
            endif
          endif
          ! Log file book-keeping, wind ends
          if(t > FB_end(isn) .and. FB_done(isn)) then
            if(myid == 1) write (*,*) 'Wind stopped ',isn,' @ t = ', t, &
                  & 'FB_end =', FB_end(isn)
            FB_done(isn) = .false.
          endif
        endif
     end do
  endif
end subroutine feedback_fixed

subroutine courant_fb_fixed(dtout)
  ! Find fixed source timestep
  ! NOTE: This basically just ensures that the source starts on time
  ! It's more efficient to let the other courant limiters work after that
  ! dtout - output parameter
  use amr_commons
  use hydro_parameters
  use amr_parameters,only:dp
  use sink_feedback_parameters
  implicit none
  
  integer::isn
  real(dp),intent(out)::dtout
  
  ! Loop through each source
  do isn=1,FB_nsource
     ! Check to see whether we're going to overshoot the supernova
!     if (t+dtout > FB_start(isn)) then
!        dtout = FB_start(isn) - t
!     endif
     ! OLD CODE FOR LIMITING TIMING, USE OTHER COURANT LIMITERS INSTEAD
     ! TODO: REMOVE
     ! Is the source active this timestep?
     !if (FB_sourceactive(isn)) then
     !   ! Set the timestep to the current minimum
     !   if (dtout .gt. 0d0) then
     !      dtout = min(dtout,FB_dtnew(isn))
     !   else
     !      dtout = FB_dtnew(isn)
     !   end if
     !end if
  end do

end subroutine courant_fb_fixed

subroutine make_fb_fixed(currlevel,isn)
  ! Adapted from O. Iffrig's make_sn_blast
  use amr_commons
  use hydro_commons
  use amr_parameters,only:dp
  use sink_feedback_parameters
  use constants, only:pi,yr2sec,M_sun
  implicit none

  integer, intent(in) :: currlevel,isn

  integer:: ivar
  integer:: ilevel, ind, ix, iy, iz, ngrid, iskip, idim
  integer:: i, nx_loc, igrid, ncache
  integer, dimension(1:nvector), save:: ind_grid, ind_cell
  real(dp):: dx, dt
  real(dp):: scale, dx_min, dx_loc, vol_loc

  real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v
  real(dp)::scale_msun, scale_ecgs

  real(dp), dimension(1:3):: skip_loc
  real(dp), dimension(1:twotondim, 1:3):: xc
  logical, dimension(1:nvector), save:: ok

  real(dp),dimension(1:3):: sn_cent
  real(dp), dimension(1:nvector, 1:ndim), save:: xx
  real(dp):: sn_r, sn_m, sn_e, sn_vol, sn_d, sn_ed, dx_sel, sn_p, sn_v
  real(dp):: rr
  real(dp), dimension(1:ndim)::rvec
  logical:: sel = .false.

  if(.not. hydro)return
  if(ndim .ne. 3)return

  if(verbose)write(*,*)'Entering make_fb_fixed'

  ! Make source active this timestep
  FB_sourceactive(isn) = .true.

  ! Mesh spacing in that level
  nx_loc = icoarse_max - icoarse_min + 1
  skip_loc = (/ 0.0d0, 0.0d0, 0.0d0 /)
  if(ndim>0)skip_loc(1)=dble(icoarse_min)
  if(ndim>1)skip_loc(2)=dble(jcoarse_min)
  if(ndim>2)skip_loc(3)=dble(kcoarse_min)
  scale = boxlen / dble(nx_loc)
  dx_min = scale * 0.5d0**nlevelmax

  ! Conversion factor from user units to cgs units
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
  scale_msun = scale_d * scale_l**ndim / m_sun
  scale_ecgs = scale_d * scale_v**2 * scale_l**ndim

  ! Hard-code sn properties to centre of box
  sn_r = FB_radius(isn)*(0.5**nlevelmax)*scale

  !Set up injection energy, mass, velocity and position
  sn_m = FB_mejecta(isn) / scale_msun ! Put in 10 solar masses
  sn_e = FB_energy(isn) / scale_ecgs
  sn_v = sqrt(2.0*(sn_e*scale_ecgs)/(sn_m*scale_msun*m_sun))
  sn_v = sn_v / scale_v
  sn_cent(1)= FB_pos_x(isn)*boxlen
  sn_cent(2)= FB_pos_y(isn)*boxlen
  sn_cent(3)= FB_pos_z(isn)*boxlen

  ! HACK - force Courant condition on winds before first hydro step
  ! TODO: think about how this is synchronised more carefully
  FB_dtnew(isn) = courant_factor*dx_min/sn_v
  dt = min(dtnew(currlevel),dt)
  dt = dtnew(currlevel)

  ! If this is a wind, scale the luminosity by the timestep
  if (FB_sourcetype(isn) .eq. 'wind') then
    sn_m = sn_m * dt*scale_t/yr2sec ! dt in years
    sn_e = sn_e * dt*scale_t/yr2sec
  endif

  ! HACK !!! - KINETIC BLAST ONLY WORKS FOR sn_r > 0.0 !!!
  if(sn_r /= 0.0) then
     sn_vol = 4. / 3. * pi * sn_r**3
     sn_d = sn_m / sn_vol
     sn_ed = sn_e / sn_vol
     sn_p = sn_d*sn_v ! uniform momentum of blast ejecta
  end if
     
  if(myid .eq. 1 .and. FB_sourcetype(isn) .eq. 'supernova') then
     write(*,*) 'Supernova blast! Wow!'
     write(*,*) 'x_sn, y_sn, z_sn, ',sn_cent(1),sn_cent(2),sn_cent(3)
  endif

  ! Loop over levels
  do ilevel = levelmin, nlevelmax
    ! Computing local volume (important for averaging hydro quantities)
    dx = 0.5d0**ilevel
    dx_loc = dx * scale
    vol_loc = dx_loc**ndim

    ! Cell center position relative to grid center position
    do ind=1,twotondim
      iz = (ind - 1) / 4
      iy = (ind - 1 - 4 * iz) / 2
      ix = (ind - 1 - 2 * iy - 4 * iz)
      if(ndim>0) xc(ind,1) = (dble(ix) - 0.5d0) * dx
      if(ndim>1) xc(ind,2) = (dble(iy) - 0.5d0) * dx
      if(ndim>2) xc(ind,3) = (dble(iz) - 0.5d0) * dx
    end do

    ! Loop over grids
    ncache=active(ilevel)%ngrid
    do igrid = 1, ncache, nvector
      ngrid = min(nvector, ncache - igrid + 1)
      do i = 1, ngrid
        ind_grid(i) = active(ilevel)%igrid(igrid + i - 1)
      end do

      ! Loop over cells
      do ind = 1, twotondim
        ! Gather cell indices
        iskip = ncoarse + (ind - 1) * ngridmax
        do i = 1, ngrid
          ind_cell(i) = iskip + ind_grid(i)
        end do

        ! Gather cell center positions
        do i = 1, ngrid
          xx(i, :) = xg(ind_grid(i), :) + xc(ind, :)
        end do
        ! Rescale position from coarse grid units to code units
        do idim=1,ndim
           do i=1,ngrid
              xx(i,idim)=(xx(i,idim)-skip_loc(idim))*scale
           end do
        end do
        ! Flag leaf cells
        do i = 1, ngrid
          ok(i) = (son(ind_cell(i)) == 0)
        end do

        do i = 1, ngrid
          if(ok(i)) then
            if(sn_r == 0.0) then
              sn_d = sn_m / vol_loc ! XXX
              sn_ed = sn_e / vol_loc ! XXX
              rr = 1.0
              do idim = 1, ndim
                !rr = rr * max(1.0 - abs(xx(i, idim) - sn_center(sn_i, idim)) / dx_sel, 0.0)
                rr = rr * max(1.0 - abs(xx(i, idim) - sn_cent(idim)) / dx_loc, 0.0)
              end do
              !if(rr > 0.0) then
                !if(.not. sel) then
                  !! We found a leaf cell near the supernova center
                  !sel = .true.
                  !sn_d = sn_m / sn_vol
                  !sn_ed = sn_e / sn_vol
                !end if
                uold(ind_cell(i), 1) = uold(ind_cell(i), 1) + sn_d * rr
                uold(ind_cell(i), 2+ndim) = uold(ind_cell(i), 2+ndim) + sn_ed * rr
              !end if
            else
               ! Get direction to point the explosion in
               do idim = 1, ndim
                  rvec(idim) = (xx(i, idim) - sn_cent(idim)) / sn_r
               enddo
               rr = sqrt(sum(rvec**2))
               rvec = rvec/rr
   
               if(rr < 1.) then
                  uold(ind_cell(i), 1) = uold(ind_cell(i), 1) + sn_d
                  ! If not entirely thermal injection, add some velocity
                  if (.not.FB_thermal(isn)) then
                     do idim=1,ndim 
                        uold(ind_cell(i),1+idim) = uold(ind_cell(i),1+idim) + &
                          & sn_p * rvec(idim)
                     enddo
                  end if
                  uold(ind_cell(i), 2+ndim) = uold(ind_cell(i), 2+ndim) + sn_ed
               endif
            endif
          endif
        end do
      end do
      ! End loop over cells
    end do
    ! End loop over grids
  end do
  ! End loop over levels

  ! Update hydro quantities for split cells
  do ilevel = nlevelmax, levelmin, -1
    call upload_fine(ilevel)
    do ivar = 1, nvar
      call make_virtual_fine_dp(uold(1, ivar), ilevel)
    enddo
  enddo
end subroutine make_fb_fixed

!################################################################
!################################################################
!################################################################
!################################################################

! TC: currently not used but we leave it for future reference
SUBROUTINE feedback_refine(xx,ok,ncell,ilevel)

! This routine flags cells immediately around SN sources to the finest
! level of refinement. The criteria for refinement at a point are:
! a) The point is less than one ilevel cell width from an SN source.
! b) The point is within FB_r_wind finest level cell widths from
!    the SN source.
!-------------------------------------------------------------------------
  use amr_commons
  use pm_commons
  use hydro_commons
  use poisson_commons
  use amr_parameters, only:dp
  use sink_feedback_parameters
  implicit none
  integer::ncell,ilevel,i,k,nx_loc,isn
  real(dp),dimension(1:nvector,1:ndim)::xx
  logical ,dimension(1:nvector)::ok
  real(dp)::dx_loc,rvec(ndim),w,rmag,rFB
!-------------------------------------------------------------------------
  nx_loc=(icoarse_max-icoarse_min+1)
  dx_loc = boxlen*0.5D0**ilevel/dble(nx_loc)
  ! Loop over regions
#if NDIM==3
  do isn=1,FB_nsource
     do i=1,ncell
        rFB = FB_r_refine(isn)*boxlen*0.5D0**nlevelmax
        rvec(1)=xx(i,1)-FB_pos_x(isn)*boxlen
        rvec(2)=xx(i,2)-FB_pos_y(isn)*boxlen
        rvec(3)=xx(i,3)-FB_pos_z(isn)*boxlen
        rmag=sqrt(sum(rvec**2))
        if(rmag .le. 2*rFB+dx_loc) then
           ok(i)=.true.
        endif
     end do
  end do
#endif
  
END SUBROUTINE feedback_refine
!################################################################
!################################################################
!################################################################
!################################################################
!!in this version the supernovae are put in the densest cell
subroutine make_sn
  use amr_commons
  use hydro_commons
  use sink_feedback_parameters
  use constants, only:pi
  use mpi_mod
  implicit none

  integer:: ivar, ilevel, ind, ix, iy, iz, ngrid, iskip, idim
  integer:: i, nx_loc, igrid, ncache
  integer, dimension(1:nvector), save:: ind_grid, ind_cell
  real(dp):: dx, scale, dx_loc, vol_loc
  real(dp), dimension(1:3):: skip_loc
  real(dp), dimension(1:twotondim, 1:3):: xc
  logical, dimension(1:nvector), save:: ok
  real(dp), dimension(1:nvector, 1:3), save:: xx
  real(dp):: sn_r, sn_vol, sn_d, sn_ed
  real(dp):: rr, dens_max,pgas,dgas,ekin,mass_sn_tot,dens_max_all,mass_sn_tot_all
  logical, save:: first = .true.
  real(dp)::xseed
  integer:: info
  integer :: max_loc
  integer,dimension(1) :: max_loc_v
  real(dp),dimension(1:ncpu)::dens_v
  real(dp),dimension(1:ncpu,4)::dens_max_v,dens_max_all_v
  real(dp) ::dens_max_loc,dens_max_loc_all
  real(dp),dimension(1:3):: sn_cent2_all

  if(.not. hydro)return
  if(ndim .ne. 3)return

  if(verbose)write(*,*)'Entering make_sn_from_peak'

  if (first) then 
     xseed=0.5
     call random_number(xseed)
     first=.false.
  endif

  ! Mesh spacing in that level
  nx_loc = icoarse_max - icoarse_min + 1
  skip_loc = (/ 0.0d0, 0.0d0, 0.0d0 /)
  skip_loc(1) = dble(icoarse_min)
  skip_loc(2) = dble(jcoarse_min)
  skip_loc(3) = dble(kcoarse_min)
  scale = boxlen / dble(nx_loc)

  ! Find the cell with highest density in the cpu
  dens_max_v = 0
  dens_max=0
  do ilevel = levelmin, nlevelmax
    ! Computing local volume (important for averaging hydro quantities)
    dx = 0.5d0**ilevel
    dx_loc = dx * scale
    vol_loc = dx_loc**ndim

    ! Cell center position relative to grid center position
    do ind=1,twotondim
      iz = (ind - 1) / 4
      iy = (ind - 1 - 4 * iz) / 2
      ix = (ind - 1 - 2 * iy - 4 * iz)
      xc(ind,1) = (dble(ix) - 0.5d0) * dx
      xc(ind,2) = (dble(iy) - 0.5d0) * dx
      xc(ind,3) = (dble(iz) - 0.5d0) * dx
    end do

    ! Loop over grids
    ncache=active(ilevel)%ngrid
    do igrid = 1, ncache, nvector
      ngrid = min(nvector, ncache - igrid + 1)
      do i = 1, ngrid
        ind_grid(i) = active(ilevel)%igrid(igrid + i - 1)
      end do

      ! Loop over cells
      do ind = 1, twotondim
        ! Gather cell indices
        iskip = ncoarse + (ind - 1) * ngridmax
        do i = 1, ngrid
          ind_cell(i) = iskip + ind_grid(i)
        end do

        ! Gather cell center positions
        do i = 1, ngrid
          xx(i, :) = xg(ind_grid(i), :) + xc(ind, :)
        end do
        ! Rescale position from coarse grid units to code units
        do i = 1, ngrid
           xx(i, :) = (xx(i, :) - skip_loc(:)) * scale
        end do

        ! Flag leaf cells
        do i = 1, ngrid
          ok(i) = (son(ind_cell(i)) == 0)
        end do

        do i = 1, ngrid
          if(ok(i)) then
            !we look for the densest cell in the cpu
            if( uold(ind_cell(i), 1) .gt. dens_max) then 
              dens_max           = uold(ind_cell(i), 1)
              dens_max_v(myid,1) = dens_max
              dens_max_v(myid,2) = xx(i,1) + dx /10. !small shift avoid division by 0 later
              dens_max_v(myid,3) = xx(i,2) + dx /10. !small shift avoid division by 0 later
              dens_max_v(myid,4) = xx(i,3) + dx /10. !small shift avoid division by 0 later
            endif
          endif
        end do
      end do
      ! End loop over cells
    end do
    ! End loop over grids
  end do
  ! End loop over levels

  ! Find the densest cell among cpus
  dens_max_all_v=0.d0
#ifndef WITHOUTMPI
  call MPI_ALLREDUCE(dens_max_v,dens_max_all_v,4*ncpu,MPI_DOUBLE_PRECISION,MPI_SUM,MPI_COMM_WORLD,info)
#else
  dens_max_all_v = dens_max_v
#endif
  dens_v = dens_max_all_v(1:ncpu,1)
  dens_max_all = maxval(dens_v)
  max_loc_v    = maxloc(dens_v)
  max_loc = max_loc_v(1)
  ! position of the densest cell
  sn_cent2_all(1) =  dens_max_all_v(max_loc,2)
  sn_cent2_all(2) =  dens_max_all_v(max_loc,3)
  sn_cent2_all(3) =  dens_max_all_v(max_loc,4)

  ! radius of sphere where we dump the SN energy/momentum/mass (numerical, we choose 3 coarse cells)
  sn_r = 3.*(0.5**levelmin)*scale
  sn_r = max(sn_r,sn_r_min) !impose a minimum size of 12 pc for the radius
  sn_vol = 4. / 3. * pi * sn_r**3
  sn_d = sn_mass_ref / sn_vol
  sn_ed = sn_e_ref / sn_vol

  ! the supernova is introduced only if there is dense enough gas
  if(dens_max_all .gt. sn_min_dens) then 

    if( myid .eq. 1 ) write(*,*) 'myid ',myid ,'max_loc', max_loc , dens_max_all,sn_cent2_all(1),sn_cent2_all(2),sn_cent2_all(3)

    dens_max_loc = 0.
    mass_sn_tot = 0.
    dens_max_loc_all = 0.
    mass_sn_tot_all = 0.

    ! Loop over levels again and place the sink at the density peak
    do ilevel = levelmin, nlevelmax
      ! Computing local volume (important for averaging hydro quantities)
      dx = 0.5d0**ilevel
      dx_loc = dx * scale
      vol_loc = dx_loc**ndim

      ! Cell center position relative to grid center position
      do ind=1,twotondim
        iz = (ind - 1) / 4
        iy = (ind - 1 - 4 * iz) / 2
        ix = (ind - 1 - 2 * iy - 4 * iz)
        xc(ind,1) = (dble(ix) - 0.5d0) * dx
        xc(ind,2) = (dble(iy) - 0.5d0) * dx
        xc(ind,3) = (dble(iz) - 0.5d0) * dx
      end do

      ! Loop over grids
      ncache=active(ilevel)%ngrid
      do igrid = 1, ncache, nvector
        ngrid = min(nvector, ncache - igrid + 1)
        do i = 1, ngrid
          ind_grid(i) = active(ilevel)%igrid(igrid + i - 1)
        end do

        ! Loop over cells
        do ind = 1, twotondim
          ! Gather cell indices
          iskip = ncoarse + (ind - 1) * ngridmax
          do i = 1, ngrid
            ind_cell(i) = iskip + ind_grid(i)
          end do

          ! Gather cell center positions
          do i = 1, ngrid
            xx(i, :) = xg(ind_grid(i), :) + xc(ind, :)
          end do
          ! Rescale position from coarse grid units to code units
          do i = 1, ngrid
            xx(i, :) = (xx(i, :) - skip_loc(:)) * scale
          end do

          ! Flag leaf cells
          do i = 1, ngrid
            ok(i) = (son(ind_cell(i)) == 0)
          end do

          do i = 1, ngrid
            if(ok(i)) then
                rr = sum(((xx(i, :) - sn_cent2_all(:)) / sn_r)**2)

                ! if the cell is inside the SN radius: dump mass and momentum?
                if(rr < 1.) then
                  ! add ejecta density
                  uold(ind_cell(i), 1) = uold(ind_cell(i), 1) + sn_d
                  dgas = uold(ind_cell(i), 1)
                  if(dgas .gt. dens_max_loc) dens_max_loc = dgas

                  !compute velocity of the gas within this cell assuming energy equipartition
                  rr = sqrt(sum(((xx(i, :) - sn_cent2_all(:)))**2))
                  pgas = sqrt(eff_sn*sn_ed / dgas) * dgas !!more a guess for now one should compute the momentum
  !!                pgas = min(sn_p / pnorm_sn * rr /  dgas , Vsat) * dgas

                  ekin = ((uold(ind_cell(i),2))**2 + (uold(ind_cell(i),3))**2 + (uold(ind_cell(i),4))**2) / dgas / 2.
                  uold(ind_cell(i), 5) = uold(ind_cell(i), 5) - ekin

                  uold(ind_cell(i),2) = uold(ind_cell(i),2) + pgas * (xx(i,1) - sn_cent2_all(1)) / rr 
                  uold(ind_cell(i),3) = uold(ind_cell(i),3) + pgas * (xx(i,2) - sn_cent2_all(2)) / rr 
                  uold(ind_cell(i),4) = uold(ind_cell(i),4) + pgas * (xx(i,3) - sn_cent2_all(3)) / rr 

                  ekin = ((uold(ind_cell(i),2))**2 + (uold(ind_cell(i),3))**2 + (uold(ind_cell(i),4))**2) / dgas / 2.

                  uold(ind_cell(i), 5) = uold(ind_cell(i), 5) + ekin + sn_ed

                endif

            endif
          end do 
          !  End loop over sublist of cells
        end do
        ! End loop over cells
      end do
      ! End loop over grids
    end do
    ! End loop over levels

#ifndef WITHOUTMPI
    call MPI_ALLREDUCE(dens_max_loc,dens_max_loc_all,1,MPI_DOUBLE_PRECISION,MPI_MAX,MPI_COMM_WORLD,info)
#else
    dens_max_loc_all = dens_max_loc
#endif

    if(myid .eq. 1) write(102,112) t,sn_cent2_all(1),sn_cent2_all(2),sn_cent2_all(3),dens_max_loc_all

    112 format(6e12.4)

  endif !end of the if on the density threshold for the second loop

  ! Update hydro quantities for split cells
  do ilevel = nlevelmax, levelmin, -1
    call upload_fine(ilevel)
    do ivar = 1, nvar
      call make_virtual_fine_dp(uold(1, ivar), ilevel)
    enddo
  enddo

end subroutine make_sn
!################################################################
!################################################################
!################################################################
!################################################################

