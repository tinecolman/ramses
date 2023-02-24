! TC: currently not used but keep for future reference
! A 1D lookup table that allows (linear) interpolation between values
! Sam Geen, March 2017
MODULE table_1d_module

  !use amr_parameters

  implicit none
  integer,parameter::dp=kind(1.0D0) ! real*8  

  private   ! default

  public setup_table, clear_table, find_value
  public lookup_table, debug_lkup

  !------------------------------------------------------------------------
  ! The table structure (should really be an object but hey ho):
  ! Contains up to 4 dimensions (more and you have to re-code it)
  ! TODO: Allow generic types in the table (if possible in FORTRAN)
  integer, parameter         :: TDIMS = 4
  logical                    :: debug_lkup=.false.
  type lookup_table
     ! Table's filename
     character(len=128)                    :: filename
     ! The size in each dimension
     integer*4                             :: size
     ! Values along each axis
     real(dp), dimension(:), pointer       :: xaxis
     real(dp), dimension(:), pointer       :: yaxis
  end type lookup_table
  
CONTAINS
!************************************************************************
SUBROUTINE setup_table(table, filename)
!------------------------------------------------------------------------ 
  type(lookup_table) :: table
  character(len=*) :: filename

  table%filename = filename
  call read_table(table)

END SUBROUTINE setup_table

!************************************************************************
! Reads the table
SUBROUTINE read_table(table)
  !use amr_commons
  integer,parameter::myid=1
  type(lookup_table) :: table
  logical            :: ok

  IF (debug_lkup) &
       write(*,*)"Reading lookup table "//TRIM(table%filename)
  inquire(file=TRIM(table%filename), exist=ok)
  if(.not. ok)then
     if(myid.eq.1) then 
        write(*,*)'Cannot read file...'
        write(*,*)'File '//TRIM(table%filename)//' not found'
     endif
     !call clean_stop
     stop
  end if
  open(unit=1336,file=TRIM(table%filename),form='unformatted')
  ! Read the table's number of dimensions (can be up to 4)
  if (debug_lkup) write(*,*)"READING SIZE"
  read(1336)table%size
  ! Read the axis values
  allocate(table%xaxis(table%size))
  allocate(table%yaxis(table%size))
  if (debug_lkup) write(*,*)"READING AXES"
  read(1336)table%xaxis
  read(1336)table%yaxis
  close(1336)
  IF (debug_lkup) write(*,*)"Done reading table"

END SUBROUTINE read_table

SUBROUTINE clear_table(table)
! Clear out data in table
  type(lookup_table) :: table

  IF (debug_lkup) write(*,*)"Clearing out lookup table "//TRIM(table%filename)
  !IF (table%contains_data) THEN
     ! Deallocate data
     deallocate(table%xaxis)
     deallocate(table%yaxis)
     table%size = 0
  !END IF
END SUBROUTINE clear_table

!************************************************************************
! TODO: Interpolate between values
! TODO: Do extrapolation outside data range
SUBROUTINE find_value(table, xin, outval)
! Find result in array from input coordinates (interpolate to nearest values)
! v[1,2,3,4] - Input coordinates
! outval     - Output value
  type(lookup_table)       :: table
  real(dp), intent(in)     :: xin
  real(dp), intent(out)    :: outval

  IF (debug_lkup) &
       write(*,*)"Finding value in lookup table "//TRIM(table%filename)
  ! Interpolate between the values
  call interpolate(table, xin, outval)
END SUBROUTINE find_value

!************************************************************************
SUBROUTINE find_index(table, xin, iout)
! Find a value in a given axis
! table   - lookup table
! xin     - value along the axis to find
! iout    - output coordinate on axis
  type(lookup_table)               :: table
  real(dp)                         :: xin
  integer                          :: iout

  IF (debug_lkup) write(*,*)"Finding value in axis between ", &
       table%xaxis(1), " and ", table%xaxis(table%size)
  ! Fix the inputted value to prevent bad extrapolation
  xin = MIN(xin,table%xaxis(table%size))
  xin = MAX(xin,table%xaxis(1))
  iout=1
  ! Find the index just above the value chosen
  ! Check: 1) value in axis is too small still and 
  !        2) that we haven't overflowed the array
  ! TODO: Add bisection/binary search (or even a tree? nah)
  IF (table%size.gt.1) THEN
     DO WHILE ((table%xaxis(iout+1).lt.xin).and.(iout.le.table%size-1))
        iout=iout+1
     END DO
  ENDIF
  ! ASSUMES EQUAL AXIS VALUE SPACING
  ! index is (value - first element) / spacing
  !if (numaxis .lt. 2) then
  !   io = 1
  !else
  !   io = int( (value - axis(1)) / (axis(2) - axis(1)) ) + 1
  !endif
  ! Bound check the index returned
  iout = MIN(iout,table%size-1) ! Must be -1 as we add 1 to interpolate later
  iout = MAX(iout,1)
  ! Debug message
  IF (debug_lkup) &
       write(*,*)"Value chosen: ", table%xaxis(iout), " at ",iout,&
       "; (Value inputted: ", xin, ")"
END SUBROUTINE find_index

! Linear 1D interpolation on table
SUBROUTINE interpolate(table, xin, outval)
  ! Trilinear interpolation on values v1,v2,v3
  ! gi = distance from nearest grid cell under vi (between 0 and 1) 
  type(lookup_table)       :: table
  real(dp), intent(in)     :: xin
  real(dp)                 :: v1t
  real(dp), intent(out)    :: outval
  real(dp)                 :: x0,x1, y0,y1, t0, t1
  integer                  :: index
  
  IF (debug_lkup) &
       write(*,*)"Linear 1D interpolation"
  ! Get the lowest indices closest to the object
  v1t = xin
  call find_index(table, v1t, index)
  
  ! Get fractional length along the selected axis bin
  t0 = table%xaxis(index)
  t1 = table%xaxis(index+1)
  x1 = (v1t - t0) / (t1 - t0)
  x0 = 1d0-x1
  y0 = 1d0-y1

  ! Get interpolated value
  outval = &
       x0*table%yaxis(index) + &
       x1*table%yaxis(index+1)
  ! That's it. LEAVE NOW.
END SUBROUTINE interpolate

END MODULE table_1d_module
