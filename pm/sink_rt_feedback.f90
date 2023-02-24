#ifdef RT
!*************************************************************************
!*************************************************************************
!*************************************************************************
!*************************************************************************
SUBROUTINE update_sink_RT_feedback

! Turn on RT advection if needed.
! Update photon group properties from stellar populations.
!-------------------------------------------------------------------------
  use rt_parameters
  use sink_feedback_parameters
  implicit none

  if(nstellar>0)then
     rt_advect=.true.
  endif

END SUBROUTINE update_sink_RT_feedback
!*************************************************************************
!*************************************************************************
!*************************************************************************
!*************************************************************************
SUBROUTINE sink_RT_feedback(ilevel, dt)

! This routine adds photons from radiating sinks to appropriate cells in 
! the  hydro grid. Emission is determined from massive stellar particles
! attached to the sinks.
! ilevel =>  grid level in which to perform the feedback
! dt     =>  real timestep length in code units
!-------------------------------------------------------------------------
  use pm_commons
  use amr_commons
  use rt_parameters
  use sink_feedback_parameters

  implicit none
  integer:: ilevel
  real(dp):: dt
  integer:: igrid, jgrid, ipart, jpart, next_part
  integer:: ig, ip, npart1, npart2, icpu
  integer,dimension(1:nvector),save:: ind_grid, ind_part, ind_grid_part
  !this array gathers the ionising flux by looping over stellar object
  !note that this array is local and therefore is not declared in pm_common
  real(dp),dimension(1:nsink,1:ngroups):: sink_ioni_flux
!-------------------------------------------------------------------------
  if(.not.rt_advect)RETURN
  if(nsink .le. 0 ) return
  if(numbtot(1,ilevel)==0)return
  if(verbose)write(*,111)ilevel

  ! Start by looping over the stellar objects and gather their fluxes
  call gather_ioni_flux(dt,sink_ioni_flux)

  ! Loop over cpus
  do icpu=1,ncpu
     igrid=headl(icpu,ilevel)
     ig=0
     ip=0
     ! Loop over grids
     do jgrid=1,numbl(icpu,ilevel)
        npart1=numbp(igrid)
        npart2=0
        if(npart1 > 0)then
          ipart = headp(igrid) 
           ! Loop over particles
           do jpart = 1, npart1
              next_part = nextp(ipart)
              ! only sink cloud particles
              if(idp(ipart) .lt. 0) then 
                 npart2 = npart2+1     
              endif
              ipart = next_part
           end do
        endif

        ! Gather sink and cloud particles within the grid
        if(npart2 > 0)then        
           ig = ig+1
           ind_grid(ig) = igrid
           ipart = headp(igrid)
           ! Loop over particles
           do jpart = 1, npart1
              next_part = nextp(ipart)
              if(idp(ipart) .lt. 0) then
                 if(ig==0)then
                    ig=1      
                    ind_grid(ig)=igrid
                 end if
                 ip = ip+1
                 ind_part(ip) = ipart
                 ind_grid_part(ip) = ig
              endif
              if(ip == nvector)then
                 call sink_RT_vsweep_stellar( &
                              ind_grid,ind_part,ind_grid_part,ig,ip,dt,ilevel,sink_ioni_flux)
                 ip = 0
                 ig = 0
              end if
              ipart = next_part  ! Go to next particle
           end do
           ! End loop over particles
        end if
        igrid = next(igrid)   ! Go to next grid
     end do
     ! End loop over grids
     if(ip > 0) then
         call sink_RT_vsweep_stellar( &
                     ind_grid,ind_part,ind_grid_part,ig,ip,dt,ilevel,sink_ioni_flux)
     endif
  end do 
  ! End loop over cpus

111 format('   Entering sink_rt_feedback for level ',I2)

END SUBROUTINE sink_RT_feedback
!*************************************************************************
!*************************************************************************
!*************************************************************************
!*************************************************************************
SUBROUTINE gather_ioni_flux(dt,sink_ioni_flux)
! This routine is called by sink_RT_feedback is stellar objects are used
! It gathers the ionising flux on each sinks which is used to perform ionising radiation feedback

! sink_ioni_flux =>  the ionising flux of each sink 
  use amr_commons
  use pm_commons
  use rt_parameters
  use sink_feedback_parameters

  implicit none

  real(dp),intent(in)::dt
  real(dp),dimension(1:nsink,1:ngroups),intent(out):: sink_ioni_flux !this arrays gathers the ionising flux by looping over stellar object
  integer:: istellar,isink,ig
  real(dp)::M_stellar,Flux_stellar
  real(dp),dimension(1:ngroups)::nphotons

  sink_ioni_flux = 0d0

  do istellar=1,nstellar
    ! find corresponding sink
     isink = 1
     do while ((isink.le.nsink) .and. (id_stellar(istellar) .ne. idsink(isink)))
       isink = isink + 1
     end do
     if (isink.gt.nsink) then
       write(*,*)"BUG: COULD NOT FIND SINK"
       call clean_stop
     endif
     M_stellar = mstellar(istellar)
     ! Reset the photon counter
     nphotons = 0d0
     Flux_stellar = 0

     !! Use singlestar_module (reads SB99-derived tables)
     !if (use_ssm) then
     !   ts = (t-tstellar(istellar))*scale_t
     !   dts = dt*scale_t
     !   M_stellar_Msun = M_stellar*(scale_m/Msun)
     !   call ssm_radiation(M_stellar_Msun,ts,dts,nphotons)
     !   write(*,*) "SSM_RADIATION", M_stellar_Msun,ts,dts,nphotons
     !   ! Divide by dt so we can scale up later
     !   nphotons = nphotons/dt
     !   nphotons = max(nphotons,0d0)
     !! Use fit to Vacca+ 1996
     !else

     ! Use fit to Vacca+ 1996
     !check whether the object is emitting
     if (t - tstellar(istellar) < hii_t) then
        !remember vaccafits is in code units because the corresponding parameters have been normalised in read_stellar_params (stf_K and stf_m0)
        call vaccafit(M_stellar,Flux_stellar)
        nphotons(feedback_photon_group) = Flux_stellar
     endif

     do ig=1,ngroups
        ! Remove negative photon counts
        nphotons(ig) = max(nphotons(ig),0d0)
        sink_ioni_flux(isink,ig) = sink_ioni_flux(isink,ig) + nphotons(ig)
     enddo

  enddo

END SUBROUTINE gather_ioni_flux
!*************************************************************************
!*************************************************************************
!*************************************************************************
!*************************************************************************
SUBROUTINE sink_RT_vsweep_stellar(ind_grid,ind_part,ind_grid_part,ng,np,dt,ilevel,sink_ioni_flux)
! This routine is called by subroutine sink_rt_feedback.
! Each sink and cloud  particle dumps a number of photons into the nearest grid cell
! using array rtunew.
! Radiation is injected into cells at level ilevel, but it is important
! to know that ilevel-1 cells may also get some radiation. This is due
! to sink and cloud particles that have just crossed to a coarser level. 
!

! The ionising flux of each sink must be provided in sink_ioni_flux

! ind_grid       =>  grid indexes in amr_commons (1 to ng)
! ind_part       =>  sink indexes in pm_commons(1 to np)
! ind_grid_part  =>  points from star to grid (ind_grid) it resides in
! ng             =>  number of grids
! np             =>  number of sink and cloud particles
! dt             =>  timestep length in code units
! ilevel         =>  amr level at which we're adding radiation
! sink_ioni_flux =>  the ionising flux of each sink 
!-------------------------------------------------------------------------
  use amr_commons
  use pm_commons
  use rt_hydro_commons
  use rt_parameters
  use sink_feedback_parameters
  implicit none
  integer::ng,np,ilevel
  integer,dimension(1:nvector)::ind_grid
  integer,dimension(1:nvector)::ind_grid_part,ind_part
  real(dp)::dt
  !-----------------------------------------------------------------------
  integer::i,j,idim,nx_loc,isink,ig
  real(dp)::dx,dx_loc,scale,vol_cgs
  ! Grid based arrays
  real(dp),dimension(1:nvector,1:ndim),save::x0
  integer ,dimension(1:nvector),save::ind_cell
  integer ,dimension(1:nvector,1:threetondim),save::nbors_father_cells
  integer ,dimension(1:nvector,1:twotondim),save::nbors_father_grids
  ! Particle based arrays
  logical,dimension(1:nvector),save::ok
  real(dp),dimension(1:nvector,1:ndim),save::x
  integer ,dimension(1:nvector,3),save::id=0,igd=0,icd=0
  integer ,dimension(1:nvector),save::igrid,icell,indp,kg
  real(dp),dimension(1:3)::skip_loc
  ! units and temporary quantities
  real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v,scale_Np,scale_Fp
  !this arrays gather the ionising flux by looping over stellar object
  real(dp),dimension(1:nsink,1:ngroups):: sink_ioni_flux

!-------------------------------------------------------------------------
  ! Conversion factor from user units to cgs units
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
  call rt_units(scale_Np, scale_Fp)

  ! Mesh spacing in ilevel
  dx = 0.5D0**ilevel
  nx_loc = (icoarse_max - icoarse_min + 1)
  skip_loc = (/0.0d0,0.0d0,0.0d0/)
  if(ndim>0)skip_loc(1) = dble(icoarse_min)
  if(ndim>1)skip_loc(2) = dble(jcoarse_min)
  if(ndim>2)skip_loc(3) = dble(kcoarse_min)
  scale = boxlen/dble(nx_loc) 
  dx_loc = dx*scale

  vol_cgs = (dx_loc*scale_l)**ndim

  ! Lower left corners of 3x3x3 grid-cubes (with given grid in center)
  do idim = 1, ndim
     do i = 1, ng
        x0(i,idim) = xg(ind_grid(i),idim) - 3.0D0*dx
     end do
  end do

  ! Gather 27 neighboring father cells (should be present anytime !)
  do i=1,ng
     ind_cell(i) = father(ind_grid(i))
  end do
  call get3cubefather(&
          ind_cell, nbors_father_cells, nbors_father_grids, ng, ilevel)

  ! Rescale position of stars to positions within 3x3x3 cell supercube
  do idim = 1, ndim
     do j = 1, np
        x(j,idim) = xp(ind_part(j),idim)/scale + skip_loc(idim)
        x(j,idim) = x(j,idim) - x0(ind_grid_part(j),idim)
        x(j,idim) = x(j,idim)/dx 
     end do
  end do

   ! NGP at level ilevel
  do idim=1,ndim
     do j=1,np
        id(j,idim) = x(j,idim)
     end do
  end do

  ! Compute parent grids
  do idim = 1, ndim
     do j = 1, np
        igd(j,idim) = id(j,idim)/2
     end do
  end do
  do j = 1, np
     kg(j) = 1 + igd(j,1) + 3*igd(j,2) + 9*igd(j,3) ! 1 to 27
  end do
  do j = 1, np
     igrid(j) = son(nbors_father_cells(ind_grid_part(j),kg(j))) 
  end do

  ! Check if particles are entirely in level ilevel.
  ok(1:np) = .true.
  do j = 1, np
     ok(j) = ok(j) .and. igrid(j) > 0
  end do

  ! Compute parent cell position within it's grid
  do idim = 1, ndim
     do j = 1, np
        if( ok(j) ) then
           icd(j,idim) = id(j,idim) - 2*igd(j,idim)
        end if
     end do
  end do
  do j = 1, np
     if( ok(j) ) then
        icell(j) = 1 + icd(j,1) + 2*icd(j,2) + 4*icd(j,3)
     end if
  end do

  ! Compute parent cell adress
  do j = 1, np
     if( ok(j) )then
        indp(j) = ncoarse + (icell(j)-1)*ngridmax + igrid(j)
     else
        indp(j) = nbors_father_cells(ind_grid_part(j),kg(j))
     end if
  end do
  

  ! Increase photon density in cell due to accretion luminosity
  do j=1,np
     if( ok(j) ) then                                      !   ilevel cell
        ! Get sink index
        isink=-idp(ind_part(j))
        ! deposit the photons onto the grid
        ! remark: the flux is normalised in read_stellar_object : thus no "scale_t" here see stf_K parameter
        do ig=1,ngroups
           rtunew(indp(j),iGroups(ig))=rtunew(indp(j),iGroups(ig)) + &
                sink_ioni_flux(isink,ig) * dt / dble(ncloud_sink) / vol_cgs / scale_Np
        end do

     endif
  end do

END SUBROUTINE sink_RT_vsweep_stellar
!*************************************************************************
!*************************************************************************
!*************************************************************************
!*************************************************************************
!TC: currently not used since we now use the stellar particle method. Leave in as a reference.
SUBROUTINE sink_RT_vsweep(ind_grid,ind_part,ind_grid_part,ng,np,dt,ilevel)

! This routine is called by subroutine sink_rt_feedback.
! Each sink and cloud  particle dumps a number of photons into the nearest grid cell
! using array rtunew.
! Radiation is injected into cells at level ilevel, but it is important
! to know that ilevel-1 cells may also get some radiation. This is due
! to sink and cloud particles that have just crossed to a coarser level. 
!
! The mass of the sink is first added to estimate the number of the cluster
! then using a fit performed by Sam Geen, the ionising flux of the cluster is estimated
! and spread over the sinks using an estimate based on their mass


! ind_grid      =>  grid indexes in amr_commons (1 to ng)
! ind_part      =>  sink indexes in pm_commons(1 to np)
! ind_grid_part =>  points from star to grid (ind_grid) it resides in
! ng            =>  number of grids
! np            =>  number of sink and cloud particles
! dt            =>  timestep length in code units
! ilevel        =>  amr level at which we're adding radiation
!-------------------------------------------------------------------------
  use amr_commons
  use pm_commons
  use rt_hydro_commons
  use rt_parameters
  use sink_feedback_parameters
  !use rt_cooling_module, only:iIR
  implicit none
  integer::ng,np,ilevel
  integer,dimension(1:nvector)::ind_grid
  integer,dimension(1:nvector)::ind_grid_part,ind_part
  real(dp)::dt, sourcemass
  !-----------------------------------------------------------------------
  integer::i,j,idim,nx_loc,isink
  real(dp)::dx,dx_loc,scale,vol_loc,vol_cgs
  logical::error
  ! Grid based arrays
  real(dp),dimension(1:nvector,1:ndim),save::x0
  integer ,dimension(1:nvector),save::ind_cell
  integer ,dimension(1:nvector,1:threetondim),save::nbors_father_cells
  integer ,dimension(1:nvector,1:twotondim),save::nbors_father_grids
  ! Particle based arrays
  integer,dimension(1:nvector),save::igrid_son,ind_son
  logical,dimension(1:nvector),save::ok
  real(dp),dimension(1:nvector,ngroups),save::part_NpInp
  real(dp),dimension(1:nvector,1:ndim),save::x
  integer ,dimension(1:nvector,3),save::id=0,igd=0,icd=0
  integer ,dimension(1:nvector),save::igrid,icell,indp,kg
  real(dp),dimension(1:3)::skip_loc
  real(dp)::Ep2Np
  ! units and temporary quantities
  real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v, scale_Np  & 
            , scale_Fp, age, z, scale_inp, scale_Nphot, dt_Gyr           &
            , dt_loc_Gyr, scale_msun
  real(dp),parameter::vol_factor=2**ndim   ! Vol factor for ilevel-1 cells
  ! changed:
  real(dp),dimension(1:nvector),save::dn
  real(dp)::ener
  ! Emission law based on Vacca 1996
  real(dp),parameter::qh_power=3.184
  real(dp),parameter::qh_const=10d0**43.97
  ! Sink cluster totals
  real(dp)::scluster,mcluster,wcluster,ssink

!-------------------------------------------------------------------------
! if(.not. metal) z = log10(max(z_ave*0.02, 10.d-5))![log(m_metals/m_tot)]
  ! Conversion factor from user units to cgs units
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
  call rt_units(scale_Np, scale_Fp)
  dt_Gyr = dt*scale_t*sec2Gyr
  ! Mesh spacing in ilevel
  dx = 0.5D0**ilevel
  nx_loc = (icoarse_max - icoarse_min + 1)
  skip_loc = (/0.0d0,0.0d0,0.0d0/)
  if(ndim>0)skip_loc(1) = dble(icoarse_min)
  if(ndim>1)skip_loc(2) = dble(jcoarse_min)
  if(ndim>2)skip_loc(3) = dble(kcoarse_min)
  scale = boxlen/dble(nx_loc) 
  dx_loc = dx*scale
  vol_loc = dx_loc**ndim
  scale_inp = rt_esc_frac * scale_d / scale_np / vol_loc / m_sun    
  scale_nPhot = vol_loc * scale_np * scale_l**ndim / 1.d50
  scale_msun = scale_d * scale_l**ndim / m_sun    
  vol_cgs = (dx_loc*scale_l)**ndim

  ! Ep2Np=(scale_d * scale_v**2)/( scale_Np * group_egy(iIR) * ev_to_erg)

  ! Lower left corners of 3x3x3 grid-cubes (with given grid in center)
  do idim = 1, ndim
     do i = 1, ng
        x0(i,idim) = xg(ind_grid(i),idim) - 3.0D0*dx
     end do
  end do

  ! Gather 27 neighboring father cells (should be present anytime !)
  do i=1,ng
     ind_cell(i) = father(ind_grid(i))
  end do
  call get3cubefather(&
          ind_cell, nbors_father_cells, nbors_father_grids, ng, ilevel)

  ! Rescale position of stars to positions within 3x3x3 cell supercube
  do idim = 1, ndim
     do j = 1, np
        x(j,idim) = xp(ind_part(j),idim)/scale + skip_loc(idim)
        x(j,idim) = x(j,idim) - x0(ind_grid_part(j),idim)
        x(j,idim) = x(j,idim)/dx 
     end do
  end do

   ! NGP at level ilevel
  do idim=1,ndim
     do j=1,np
        id(j,idim) = x(j,idim)
     end do
  end do

  ! Compute parent grids
  do idim = 1, ndim
     do j = 1, np
        igd(j,idim) = id(j,idim)/2
     end do
  end do
  do j = 1, np
     kg(j) = 1 + igd(j,1) + 3*igd(j,2) + 9*igd(j,3) ! 1 to 27
  end do
  do j = 1, np
     igrid(j) = son(nbors_father_cells(ind_grid_part(j),kg(j))) 
  end do

  ! Check if particles are entirely in level ilevel.
  ok(1:np) = .true.
  do j = 1, np
     ok(j) = ok(j) .and. igrid(j) > 0
  end do

  ! Compute parent cell position within it's grid
  do idim = 1, ndim
     do j = 1, np
        if( ok(j) ) then
           icd(j,idim) = id(j,idim) - 2*igd(j,idim)
        end if
     end do
  end do
  do j = 1, np
     if( ok(j) ) then
        icell(j) = 1 + icd(j,1) + 2*icd(j,2) + 4*icd(j,3)
     end if
  end do

  ! Compute parent cell adress
  do j = 1, np
     if( ok(j) )then
        indp(j) = ncoarse + (icell(j)-1)*ngridmax + igrid(j)
     else
        indp(j) = nbors_father_cells(ind_grid_part(j),kg(j))
     end if
  end do
  
  ! Calculate photon emission totals for model
  scluster = 0d0
  mcluster = 0d0
  wcluster = 0d0
  do isink=1,nsink
     ! Handwavy fit assuming dominant star in sink is msink/3
!     call vaccafit(0.3*msink(isink)*scale_msun,ssink)
     !CAREFUL : vaccafit expect code units as the coefficient stf_m0 is normalise in read_stellar_params
     call vaccafit(0.3*msink(isink),ssink)
     mcluster = mcluster + msink(isink)
     wcluster = wcluster + ssink
  end do
  ! Analytic fit to emission from IMF using Vacca 1996
  ! this function has been fitted by Sam and mcluster must be expressed in solar mass
  scluster = 4.6d46 * (mcluster*scale_msun)**1.0746
  ! Debug printing
  ! write(*,*) "Mcluster, Scluster", mcluster*scale_msun, scluster

  ! Increase photon density in cell due to accretion luminosity
  do j=1,np
     if( ok(j) ) then                                      !   ilevel cell
        ! Get sink index
        isink=-idp(ind_part(j))
        ! HACK - ADD PHOTONS TO SINKS
        ! Use weighted fit
        ! sink emission = scluster * vacca(msink/3) / sum(vacca(msink/3))
!        call vaccafit(0.3*msink(isink)*scale_msun,ssink)

        !CAREFUL : vaccafit expect code units as the coefficient stf_m0 is normalise in read_stellar_params
        call vaccafit(0.3*msink(isink),ssink)
        dn(j) = scluster * ssink / wcluster
        ! Scale that photon emission rate right up
!        dn(j) = dn(j) * dt*scale_t / dble(ncloud_sink) / vol_cgs / scale_Np
         !!!CAREFUL : CHANGE with respect to Sam's original choices
         !the flux is normalised in read_stellar_object : thus no "scale_t" here see stf_K parameter
        ! Note from Sam: I'm not sure this follows since I'm not normalising
        !   above, so if you use this code double check it all, I guess
        ! (the Vacca fit is just used to scale the output, scluster is 
        !   still in absolute number of photons)
        dn(j) = dn(j) * dt / dble(ncloud_sink) / vol_cgs / scale_Np
        !write(*,*) "DEBUG",dn(j),j,ncloud_sink,msink(isink),&
        !     & scale_msun,scale_Np,dt,scale_t,vol_cgs
        !call clean_stop
        ! energy increase due to accretion luminosity 
        !ener=acc_lum(isink)*dt
        !increase in energy density
        !dn(j)=ener/dble(ncloud_sink)/vol_loc
        !increase in photon number density
        !dn(j)=dn(j)*Ep2Np
        ! deposit the photons onto the grid
        ! TODO: ADD HELIUM 1 & 2
        rtunew(indp(j),1)=rtunew(indp(j),1)+dn(j)
     endif
  end do

END SUBROUTINE sink_RT_vsweep
!################################################################
!################################################################
!################################################################
!################################################################
SUBROUTINE vaccafit(M,S)
  ! perform a fit of the Vacca et al. 96 ionising flux
  ! M - stellar mass / solar masses
  ! S - photon emission rate in / s

  use amr_parameters,only:dp
  use sink_feedback_parameters
  implicit none

  real(dp),intent(in)::M
  real(dp),intent(out)::S

  S = stf_K * (M / stf_m0)**stf_a / (1. + (M / stf_m0)**stf_b)**stf_c

END SUBROUTINE
!################################################################
!################################################################
!################################################################
!################################################################
#endif
