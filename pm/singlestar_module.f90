! TC: currently not used but keep for future reference
! Output single star properties from Starburst99/Geneva tables
! Sam Geen, April 2017

MODULE singlestar_module
  
  use table_1d_module

  use rt_parameters
  
  implicit none

  logical::ssm_is_setup=.false.

  ! HACK TO MAKE THIS WORK WITHOUT RADIATION MODULE
  !integer,parameter::dp=kind(1.0D0) ! real*8  
  !integer,parameter::ngroups=3
  
  private
  
  ! Public functions (i.e. useable outside module) are:
  ! ssm_setup(tableloc_in)
  ! ssm_lifetime(mass_ini,lifetime)
  ! ssm_winds(mass_ini,t,dt,energy,massloss)
  ! ssm_radiation(mass_ini,t,dt,nphotons)
  public::ssm_setup, ssm_lifetime, ssm_winds, ssm_radiation

  ! Private functions (used only inside the module) are:
  private::ssm_mtoi, ssm_itom, ssm_filename, ssm_interpolate, ssm_title
  
  ! Number of tables to read
  integer::ssm_numtables
  ! Location of tables to read
  character(len=200)::ssm_tableloc
  ! Lifetimes of sources by mass
  type(lookup_table)::ssm_lifetimes
  ! Winds
  type(lookup_table),dimension(:), allocatable::ssm_energies
  type(lookup_table),dimension(:), allocatable::ssm_masslosses
  ! Radiation
  type(lookup_table),dimension(:,:), allocatable::ssm_rads
CONTAINS
  
! PUBLIC / INTERFACE FUNCTIONS
  
SUBROUTINE ssm_setup(tableloc_in)
  ! Set up the Single Star Module
  ! IMPORTANT! MUST BE RUN BEFORE YOU USE THE MOULE
  ! tableloc_in - string giving location of tables to read

  character(len=*),intent(in)::tableloc_in
  character(len=200)::filename
  integer::it,ip
  ssm_tableloc = tableloc_in
  ! Read the lifetimes tables
  ! NOTE - this is a lifetime per star
  ! These stars MUST match the stars in the other tables
  ! We assume stars are 5,10,15,...115,120 Msun
  if (ssm_is_setup) return
  filename = TRIM(ssm_tableloc)//"lifetimes.dat"
  call setup_table(ssm_lifetimes,filename)
  ssm_numtables = ssm_lifetimes%size
  ! Allocate wind and radiation tables
  allocate(ssm_energies(ssm_numtables))
  allocate(ssm_masslosses(ssm_numtables))
  allocate(ssm_rads(ssm_numtables,ngroups))
  ! Run through tables and set them up
  do it=1,ssm_numtables
     ! Winds
     call ssm_filename(it,"energy",filename)
     call setup_table(ssm_energies(it),filename)
     call ssm_filename(it,"massloss",filename)
     call setup_table(ssm_masslosses(it),filename)
     ! Radiation
     ip = 0
     if (ngroups.eq.5) then
        ip = 2
        call ssm_filename(it,"IR",filename)
        call setup_table(ssm_rads(it,1),filename)
        call ssm_filename(it,"Opt",filename)
        call setup_table(ssm_rads(it,2),filename)
     endif
     call ssm_filename(it,"HII",filename)
     call setup_table(ssm_rads(it,1+ip),filename)
     call ssm_filename(it,"HeII",filename)
     call setup_table(ssm_rads(it,2+ip),filename)
     call ssm_filename(it,"HeIII",filename)
     call setup_table(ssm_rads(it,3+ip),filename)
  enddo
  ssm_is_setup=.true.
  ! TODO: Should I also deallocate later???
  
END SUBROUTINE ssm_setup

SUBROUTINE ssm_lifetime(mass_ini,lifetime)
  ! Return the lifetime of a star in seconds
  ! mass_ini - initial stellar mass in Msun
  ! RETURNS
  ! lifetime - lifetime of the star in seconds

  real(dp),intent(in)::mass_ini
  real(dp),intent(out)::lifetime
  ! Interpolate over table to find lifetime for this mass
  call find_value(ssm_lifetimes,mass_ini,lifetime)
  
END SUBROUTINE ssm_lifetime

SUBROUTINE ssm_winds(mass_ini,t,dt,energy,massloss)
  ! Wind energy, mass loss between t and dt (from birth of star)
  ! mass_ini - initial stellar mass in Msun
  ! t - age of star in seconds
  ! dt - timestep length in seconds
  ! RETURNS
  ! energy - energy emitted in ergs between t and dt
  ! massloss - mass lost in g between t and dt

  real(dp),intent(in)::mass_ini
  real(dp),intent(in)::t
  real(dp),intent(in)::dt
  real(dp),intent(out)::energy
  real(dp),intent(out)::massloss
  real(dp)::v1,v2
  ! Get energies and mass losses for t and dt
  call ssm_interpolate(ssm_energies, mass_ini, t, v1)
  call ssm_interpolate(ssm_energies, mass_ini, t+dt, v2)
  energy = v2 - v1
  call ssm_interpolate(ssm_masslosses, mass_ini, t, v1)
  call ssm_interpolate(ssm_masslosses, mass_ini, t+dt, v2)
  massloss = v2 - v1

END SUBROUTINE ssm_winds

SUBROUTINE ssm_radiation(mass_ini,t,dt,nphotons)
  ! Number of photons to emit in each group from a star
  ! mass_ini - initial stellar mass in Msun
  ! t - age of star in seconds
  ! dt - timestep length in seconds
  ! RETURNS
  ! nphotons - number of photons emitted between t and t+dt

  real(dp),intent(in)::mass_ini
  real(dp),intent(in)::t
  real(dp),intent(in)::dt
  real(dp),dimension(ngroups),intent(out)::nphotons
  real(dp)::v1,v2
  integer::ig

  do ig=1,ngroups
     call ssm_interpolate(ssm_rads(:,ig),mass_ini,t,v1)
     call ssm_interpolate(ssm_rads(:,ig),mass_ini,t+dt,v2)
     nphotons(ig) = v2 - v1
  enddo

END SUBROUTINE ssm_radiation

! PRIVATE FUNCTIONS
! CANNOT BE CALLED OUTSIDE THE MODULE

SUBROUTINE ssm_mtoi(mass_ini,index)
  ! Convert mass to index (1 index every 5 Msun)
  
  real(dp),intent(in)::mass_ini
  integer,intent(out)::index

  index = int(mass_ini/5d0)
  
END SUBROUTINE ssm_mtoi

SUBROUTINE ssm_itom(index,mass_ini)
  ! Convert mass to index (1 index every 5 Msun)

  integer,intent(in)::index
  real(dp),intent(out)::mass_ini

  mass_ini = 5d0*index
  
END SUBROUTINE ssm_itom

SUBROUTINE ssm_filename(index,prop,filename)
  ! Returns a filename for each of the tables

  integer,intent(in)::index
  character(len=*),intent(in)::prop
  character(len=*),intent(out)::filename
  character(LEN=3)::nmass
  ! Index is 1 to 24 for masses 5 to 120
  call ssm_title(index*5,nmass)
  ! Put together filename
  filename = TRIM(ssm_tableloc)//"_m"//TRIM(nmass)// &
       & "cumul"//prop//".dat"
  ! TODO: Add error checking for file existence
END SUBROUTINE ssm_filename

SUBROUTINE ssm_interpolate(tables, mass_ini, time, output)
  ! Find interpolated values between two masses
  ! This works by assuming that each stellar track is "stretched"
  !  so that a point at x=[0,1]*lifetime is similar between tracks
  type(lookup_table),dimension(:),intent(in)::tables
  real(dp),intent(in)::mass_ini,time
  real(dp),intent(out)::output
  integer::i1,i2
  real(dp)::m1,m2,x1,x2,x,life,life1,life2,o1,o2
  type(lookup_table)::table1,table2
  ! Find tables to interpolate between
  call ssm_mtoi(mass_ini,i1)
  i2 = i1+1
  ! Table overflow: return value from largest star
  if (i2.gt.ssm_numtables) then
     table2 = tables(ssm_numtables)
     call find_value(table2,time,output)
  ! Underflow: assume small stars do nothing
  else if (i1.lt.1) then
     output = 0d0
  ! Interpolate
  else
     ! Get masses and lifetimes of bounding stellar tracks
     call ssm_itom(i1,m1)
     call ssm_itom(i2,m2)
     call ssm_lifetime(mass_ini,life)
     call ssm_lifetime(m1,life1)
     call ssm_lifetime(m2,life2)
     table1 = tables(i1)
     table2 = tables(i2)
     ! Scale time to a scale-free value
     x = time / life
     ! Find value in each track scaled to their lifetimes
     call find_value(table1,x*life1,o1)
     call find_value(table2,x*life2,o2)
     ! Interpolate between these values in mass
     output = (o1 * (mass_ini - m1) + o2 * (m2 - mass_ini)) / (m2 - m1)
  end if
  
END SUBROUTINE ssm_interpolate

SUBROUTINE ssm_title(n,nchar)
  ! Returns integer as a 3-character zero-filled string
  ! Used to generate filenames for tables

  implicit none
  integer,intent(in)::n
  character(LEN=3),intent(out)::nchar

  character(LEN=1)::nchar1
  character(LEN=2)::nchar2
  character(LEN=3)::nchar3

  if(n.ge.100)then
     write(nchar3,'(i3)') n
     nchar = nchar3
  elseif(n.ge.10)then
     write(nchar2,'(i2)') n
     nchar = '0'//nchar2
  else
     write(nchar1,'(i1)') n
     nchar = '00'//nchar1
  endif

END SUBROUTINE ssm_title

END MODULE singlestar_module
