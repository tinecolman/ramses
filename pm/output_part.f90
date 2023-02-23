subroutine backup_part(filename, filename_desc)
  use amr_commons
  use hydro_commons
  use pm_commons
  use dump_utils, only : generic_dump, dump_header_info, dim_keys
  use iso_fortran_env
  use mpi_mod
  implicit none
#ifndef WITHOUTMPI
  integer :: dummy_io, info2
  integer, parameter :: tag = 1122
#endif
  character(len=80) :: filename, filename_desc

  integer :: i, idim, unit_out, ipart
  character(len=80) :: fileloc
  character(len=5) :: nchar
  real(dp), allocatable, dimension(:) :: xdp
  integer(i8b), allocatable, dimension(:) :: ii8
  integer, allocatable, dimension(:) :: ll
  integer(int8), allocatable, dimension(:) :: ii1

  integer :: unit_info, ivar, info_var_count
  logical :: dump_info

  character(len=100) :: field_name

  real(dp) :: A,B,C

  if (verbose) write(*,*) 'Entering backup_part'

  ! Set ivar to 1 for first variable
  ivar = 1

  info_var_count = 1

  ! Wait for the token
#ifndef WITHOUTMPI
  if (IOGROUPSIZE > 0) then
     if (mod(myid-1, IOGROUPSIZE) /= 0) then
        call MPI_RECV(dummy_io, 1, MPI_INTEGER, myid-1-1, tag, &
             & MPI_COMM_WORLD, MPI_STATUS_IGNORE, info2)
     end if
  end if
#endif


  call title(myid, nchar)
  fileloc = TRIM(filename) // TRIM(nchar)
  open(newunit=unit_out, file=TRIM(fileloc), form='unformatted')
  if (myid == 1) then
     open(newunit=unit_info, file=trim(filename_desc), form='formatted')
     call dump_header_info(unit_info)
     dump_info = .true.
  else
     dump_info = .false.
  end if

  rewind(unit_out)
  ! Write header
  write(unit_out) ncpu
  write(unit_out) ndim
  write(unit_out) npart
  if (MC_tracer) then
     write(unit_out) localseed, tracer_seed
  else
     write(unit_out) localseed
  end if
  write(unit_out) nstar_tot
  write(unit_out) mstar_tot
  write(unit_out) mstar_lost
  write(unit_out) nsink
  ! Write position
  allocate(xdp(1:npart))
  do idim = 1, ndim
     ipart = 0
     do i = 1, npartmax
        if (levelp(i) > 0) then
           ipart = ipart+1
           xdp(ipart) = xp(i, idim)
        end if
     end do
     call generic_dump("position_"//dim_keys(idim), info_var_count, xdp, unit_out, dump_info, unit_info)
  end do
  ! Write velocity
  do  idim = 1, ndim
     ipart = 0
     do i = 1, npartmax
        if (levelp(i) > 0) then
           ipart = ipart+1
           xdp(ipart) = vp(i, idim)
        end if
     end do
     call generic_dump("velocity_"//dim_keys(idim), info_var_count, xdp, unit_out, dump_info, unit_info)
  end do
  ! Write mass
  ipart = 0
  do i = 1, npartmax
     if (levelp(i) > 0) then
        ipart = ipart+1
        xdp(ipart) = mp(i)
     end if
  end do
  call generic_dump("mass", info_var_count, xdp, unit_out, dump_info, unit_info)
  deallocate(xdp)
  ! Write identity
  allocate(ii8(1:npart))
  ipart = 0
  do i = 1, npartmax
     if (levelp(i) > 0) then
        ipart = ipart+1
        ii8(ipart) = idp(i)
     end if
  end do
  call generic_dump("identity", info_var_count, ii8, unit_out, dump_info, unit_info)
  deallocate(ii8)

  ! Write level
  allocate(ll(1:npart))
  ipart = 0
  do i = 1, npartmax
     if (levelp(i) > 0) then
        ipart = ipart+1
        ll(ipart) = levelp(i)
     end if
  end do
  call generic_dump("levelp", info_var_count, ll, unit_out, dump_info, unit_info)

  deallocate(ll)

  ! Write family
  allocate(ii1(1:npart))
  ipart = 0
  do i = 1, npartmax
     if (levelp(i) > 0) then
        ipart = ipart+1
        ii1(ipart) = int(typep(i)%family, 1)
     end if
  end do
  call generic_dump("family", info_var_count, ii1, unit_out, dump_info, unit_info)

  ! Write tag
  ipart = 0
  do i = 1, npartmax
     if (levelp(i) > 0) then
        ipart = ipart+1
        ii1(ipart) = int(typep(i)%tag, 1)
     end if
  end do
  call generic_dump("tag", info_var_count, ii1, unit_out, dump_info, unit_info)
  deallocate(ii1)

#ifdef OUTPUT_PARTICLE_POTENTIAL
  ! Write potential (added by AP)
  allocate(xdp(1:npart))
  ipart = 0
  do i = 1, npartmax
     if (levelp(i) > 0) then
        ipart = ipart+1
        xdp(ipart) = ptcl_phi(i)
     end if
  end do
  call generic_dump("potential", info_var_count, xdp, unit_out, dump_info, unit_info)

  deallocate(xdp)
#endif

  ! Write birth epoch
  if (star .or. sink) then
     allocate(xdp(1:npart))
     ipart = 0
     do i = 1, npartmax
        if (levelp(i) > 0) then
           ipart = ipart+1
           xdp(ipart) = tp(i)
        end if
     end do
     call generic_dump("birth_time", info_var_count, xdp, unit_out, dump_info, unit_info)
     ! Write metallicity
     if (metal) then
        ipart = 0
        do i = 1, npartmax
           if (levelp(i) > 0) then
              ipart = ipart+1
              xdp(ipart) = zp(i)
           end if
        end do
        call generic_dump("metallicity", info_var_count, xdp, unit_out, dump_info, unit_info)
     end if
     deallocate(xdp)
  end if

  !add properties of the cells in which the tracer is located 
  if (MC_tracer) then
     ! Dump particle pointer
     allocate(ll(1:npart))
     ! Get the idp of the stars on which tracers are attached
     ipart = 0
     do i = 1, npartmax
        if (levelp(i) > 0) then
           ipart = ipart + 1
           ! For star tracers, store the id of the star instead of local index
           if (is_star_tracer(typep(i))) then
              ll(ipart) = idp(partp(i))
           else ! store the relative location
              ll(ipart) = partp(i)
           end if
        end if
     end do
     call generic_dump("partp", info_var_count, ll, unit_out, dump_info, unit_info)
     deallocate(ll)

     allocate(xdp(1:npart))
!     do idim = 1, ndim
        ipart = 0
        do i = 1, npartmax
           if (levelp(i) > 0) then
              ipart = ipart + 1
              if (is_gas_tracer(typep(i))) then ! Go fetch the data from the AMR grid
                 xdp(ipart) = uold(partp(i), 1)
              else
                 xdp(ipart) = 0.
              end if
           endif
        end do
        call generic_dump("rho", info_var_count, xdp, unit_out, dump_info, unit_info)
!      end do
     deallocate(xdp)


   ! Write thermal pressure
     allocate(xdp(1:npart))
        ipart = 0
        do i = 1, npartmax
           if (levelp(i) > 0) then
                 ipart = ipart + 1
              if (is_gas_tracer(typep(i))) then ! Go fetch the data from the AMR grid
                 xdp(ipart) = uold(partp(i), ndim+2)

                 xdp(ipart) = xdp(ipart)-0.5d0*uold(partp(i), 2)**2/max(uold(partp(i), 1), smallr)
#if NDIM > 1
                 xdp(ipart) = xdp(ipart)-0.5d0*uold(partp(i), 3)**2/max(uold(partp(i), 1), smallr)
#endif
#if NDIM > 2
                 xdp(ipart) = xdp(ipart)-0.5d0*uold(partp(i), 4)**2/max(uold(partp(i), 1), smallr)
#endif

#ifdef SOLVERmhd
                 !remove the magnetic field
                 A = 0.5*(uold(partp(i), 6)+uold(partp(i), nvar+1))
                 B = 0.5*(uold(partp(i), 7)+uold(partp(i), nvar+2))
                 C = 0.5*(uold(partp(i), 8)+uold(partp(i), nvar+3))

                 xdp(ipart) = xdp(ipart)-0.5*(A**2+B**2+C**2)
#endif

#if NENER > 0
                 do irad = 1, nener
                    xdp(ipart) = xdp(ipart)-uold(partp(i), ndim+2+irad)
                 end do
#endif
                 xdp(ipart) = (gamma-1d0)*xdp(ipart)
              else
                 xdp(ipart) = 0.
              endif
           end if
        end do
        call generic_dump("pressure", info_var_count, xdp, unit_out, dump_info, unit_info)
     deallocate(xdp)



              ! Write passive scalars
#if NVAR > 8+NENER
     allocate(xdp(1:npart))
# if  NEXTINCT > 0 
     do ivar = 9+nener, nvar  - nextinct ! Write passive scalars if any
# else 
     do ivar = 9+nener, nvar ! Write passive scalars if any
#endif
           ipart = 0
           do i = 1, npartmax
              if (levelp(i) > 0) then
                 ipart = ipart + 1
                 if (is_gas_tracer(typep(i))) then ! Go fetch the data from the AMR grid
                    xdp(ipart) = uold(partp(i), ivar)/max(uold(partp(i), 1), smallr)
                 else
                    xdp(ipart) = 0.
                 endif
              endif   
           end do
           if (metal .and. imetal == ivar) then
              field_name = 'metallicity'
           else
              write(field_name, '("scalar_", i0.2)') ivar - 9-nener
           end if
           call generic_dump(field_name, info_var_count, xdp, unit_out, dump_info, unit_info)
     end do
     deallocate(xdp)
#endif



# if NEXTINCT > 0
     allocate(xdp(1:npart))
     do ivar = nvar+1 - nextinct, nvar ! Write extinction variables if any
           ipart = 0
           do i = 1, npartmax
              if (levelp(i) > 0) then
                 ipart = ipart + 1
                 if (is_gas_tracer(typep(i))) then ! Go fetch the data from the AMR grid
                    xdp(ipart) = uold(partp(i), ivar)
                 else
                    xdp(ipart) = 0.
                 endif
              endif
           end do

             if(ivar .eq. nvar) field_name='dust extinction'
#if NEXTINCT > 1
             if(ivar .eq. nvar-1) field_name='H2 self-schielding'
#endif
            call generic_dump(field_name, info_var_count, xdp, unit_out, dump_info, unit_info)
     end do
     deallocate(xdp)
#endif 


  end if !related to MC_tracer 

  !------------!
  close(unit_out)
  if (myid == 1) close(unit_info)

  ! Send the token
#ifndef WITHOUTMPI
  if (IOGROUPSIZE > 0) then
     if (mod(myid, IOGROUPSIZE) /= 0 .and. (myid .lt. ncpu)) then
        dummy_io = 1
        call MPI_SEND(dummy_io, 1, MPI_INTEGER, myid-1+1, tag, &
             & MPI_COMM_WORLD, info2)
     end if
  end if
#endif

end subroutine backup_part
