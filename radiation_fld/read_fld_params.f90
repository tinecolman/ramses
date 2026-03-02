
subroutine read_fld_params(namelist_unit,nml_ok)
   use amr_commons, only:myid
   use fld_parameters
   use constants,   only:hplanck,eV2erg
   implicit none
   integer,intent(in)::namelist_unit
   logical,intent(inout)::nml_ok
   integer::nml_err
   !------------------------------------------------------------------------
   ! Reads the parameters for the flux-limited diffusion (FLD) radiation.
   !
   ! FREQUENCY GROUPS
   ! Group boundary parameters are inputted eiter in Hz or eV (freqs_in_Hz option).
   ! The code uses group boundaries in Hz for calculations, nu_min_hz and nu_max_hz,
   ! which are set the end of this routine.
   ! Input options
   !   If NGRP=1:
   !     * single group with numin and numax read from namelist
   !   If NGRP>1:
   !     * reads a list of group boundaries from a file 'groups.dat'
   !     * splits the groups automatically between numin and numax, either 
   !       logarithmically or lineraly using the keyword 'split_groups_log'.
   !       If you want the last group to go from numax to +infinity, set extra_end_group=.true.
   !
   !------------------------------------------------------------------------
   ! radiation group namelist parameters
   real(dp)::numin=1.0d5,numax=1.0d19    ! Overall frequency boundaries
   logical::freqs_in_Hz=.true.           ! Input frequency units in Hz if true; else eV
   logical::read_groups=.false.          ! Read group boundaries from file
   logical::split_groups_log=.true.      ! Automatic splitting of group in log if true; else linear
   logical :: extra_end_group=.false. ! The last group holds frequencies numax -> frequency_upperlimit if true
   ! local variables for processing group boundaries
   real(dp)::frequency_upperlimit=1.0d35 ! High end frequency if extra_end_group = .true., basically infinity
   integer::igrp,nstep
   real(dp)::fstep
   real(dp),dimension(1:ngrp)::nu_min_ev ! minimum freq of given group in eV
   real(dp),dimension(1:ngrp)::nu_max_ev ! maximum freq of given group in eV

   namelist/radiation_params/numin,numax &
        & ,freqs_in_Hz,read_groups,split_groups_log,extra_end_group

   ! Go to the beginning of the file
   rewind(namelist_unit)

   ! Read namelist
   read(namelist_unit,NML=radiation_params,IOSTAT=nml_err)

   if(nml_err>0)then
      if(myid==1)write(*,*)'Error reading namelist &FLD_PARAMS. Check formatting.'
      nml_ok=.false.
   endif

   ! Checks on values
   if(numin<=0)then
      if(myid==1)write(*,*)'Error in FLD namelist: numin should be strictly positive!'
      nml_ok=.false.
   endif
   if(numax<=numin)then
      if(myid==1)write(*,*)'Error in FLD namelist: numax should be strictly larger than numin!'
      nml_ok=.false.
   endif

   !--------------------------------------------------------
   ! Create frequency groups (sets nu_min_hz and nu_max_hz)
   !--------------------------------------------------------
 
   if(ngrp == 1)then
      ! Only 1 group (Grey)
      if(freqs_in_Hz)then
         nu_min_hz(1) = numin
         nu_max_hz(1) = numax
      else
         nu_min_ev(1) = numin
         nu_max_ev(1) = numax
      endif
 
   else if(read_groups)then
      ! Multiple groups: read boundaries from file
      open(19,file='groups.dat',status='old')
      do igrp = 1,ngrp
         if(freqs_in_Hz)then
            read(19,*)nu_min_hz(igrp),nu_max_hz(igrp)
         else
            read(19,*)nu_min_ev(igrp),nu_max_ev(igrp)
         endif
      enddo
 
   else
      ! Multiple groups: by default split groups evenly
      if(extra_end_group)then
         nstep = ngrp-1
      else
         nstep = ngrp
      endif
 
      if(freqs_in_Hz)then
         if(split_groups_log)then
            ! divide logarithically
            fstep = (log10(numax)-log10(numin))/float(nstep)
            nu_min_hz(1) = numin
            nu_max_hz(1) = 10.0d0**(log10(numin) + fstep)
            do igrp = 2,nstep
               nu_min_hz(igrp) = nu_max_hz(igrp-1)
               nu_max_hz(igrp) = 10.0d0**(log10(nu_min_hz(igrp)) + fstep)
            enddo
         else
            ! divide linearly
            fstep = (numax-numin)/float(nstep)
            nu_min_hz(1) = numin
            nu_max_hz(1) = fstep + numin
            do igrp = 2,nstep
               nu_min_hz(igrp) = nu_max_hz(igrp-1)
               nu_max_hz(igrp) = nu_min_hz(igrp) + fstep
            enddo
         endif
 
         if(extra_end_group)then
            nu_min_hz(ngrp) = nu_max_hz(ngrp-1)
            nu_max_hz(ngrp) = frequency_upperlimit
         endif
 
      else
         ! Frequencies in eV
         if(split_groups_log)then
            fstep = (log10(numax)-log10(numin))/float(nstep)
            nu_min_ev(1) = numin
            nu_max_ev(1) = 10.0d0**(log10(numin) + fstep)
            do igrp = 2,nstep
               nu_min_ev(igrp) = nu_max_ev(igrp-1)
               nu_max_ev(igrp) = 10.0d0**(log10(nu_min_ev(igrp)) + fstep)
            enddo
         else
            fstep = (numax-numin)/float(nstep)
            nu_min_ev(1) = numin
            nu_max_ev(1) = fstep + numin
            do igrp = 2,nstep
               nu_min_ev(igrp) = nu_max_ev(igrp-1)
               nu_max_ev(igrp) = nu_min_ev(igrp) + fstep
            enddo
         endif
         if(extra_end_group)then
            nu_min_ev(ngrp) = nu_max_ev(ngrp-1)
            nu_max_ev(ngrp) = frequency_upperlimit
         endif
      endif
   endif
 
   ! Conversion between Hz and eV
   do igrp = 1,ngrp
      if(freqs_in_Hz)then
         nu_min_ev(igrp) = nu_min_hz(igrp) * hplanck/eV2erg  ! convert from Hz to eV
         nu_max_ev(igrp) = nu_max_hz(igrp) * hplanck/eV2erg  ! convert from Hz to eV
      else
         nu_min_hz(igrp) = nu_min_ev(igrp) * eV2erg/hplanck  ! convert from eV to Hz
         nu_max_hz(igrp) = nu_max_ev(igrp) * eV2erg/hplanck  ! convert from eV to Hz
      endif
   enddo
 
   ! Write info to log
   if(myid==1) then
      write(*,*) ' '
      write(*,*) 'Number of FLD radiation groups: ',ngrp
      write(*,*) ' '
      write(*,*) 'Group frequencies in Hz:'
      do igrp = 1,ngrp
         write(*,998) igrp,nu_min_hz(igrp),nu_max_hz(igrp)
      enddo
      write(*,*) ' '
      write(*,*) 'Group frequencies in eV:'
      do igrp = 1,ngrp
         write(*,998) igrp,nu_min_ev(igrp),nu_max_ev(igrp)
      enddo
      write(*,*) ' '
   endif
 
   998 format('igrp, numin, numax = ',i4,2(2x,es12.4))
 
 
end subroutine read_fld_params