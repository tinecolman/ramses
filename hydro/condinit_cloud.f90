module cloud_module
  use amr_parameters
  !================================================================
  ! This module contains the variable needed for cloud IC
  !================================================================

  !initial temperature used for the isothermal run
  real(dp)::temper
  real(dp)::temper_iso

  !feedback from jet
  logical:: jet = .false., rad_jet=.false. 
  real(dp)::Ucoef=1.
  real(dp):: mass_jet_sink=0. !mass above which a jets is included

  !Initial conditions parameter for the dense core
  real(dp)::bx_bound=0.
  real(dp)::by_bound=0.
  real(dp)::bz_bound=0.
  real(dp)::turb=0.
  real(dp)::dens0=0.
  real(dp)::V0=0.
  real(dp)::Height0=0.
  character(len=200)::file_init_turb='ramses.data'

  real(dp)::bl_fac=1.   !multiply calculated boxlen by this factor


  !Initial conditions parameters for the dense core
  logical ::bb_test=.false. ! Activate Boss & Bodenheimer inital conditions instead of 1/R^2 density profile
  logical ::uniform_bmag=.false. ! Activate uniform magnetic field initial conditions for BE-like initial density profile
  real(dp)::mass_c=1.         !cloud mass in solar mass
  real(dp)::contrast=100.d0   !density contrast (used when bb_test=.true.)
  real(dp)::cont=1.           !density contrast (used when bb_test=.false.)
  real(dp)::rap=1.            !axis ratio
  real(dp)::ff_sct=1.         !freefall time / sound crossing time
  real(dp)::ff_rt=1.          !freefall time / rotation time
  real(dp)::ff_act=1.         !freefall time / Alfven crossing time
  real(dp)::ff_vct=1.         !freefall time / Vrms crossing time
  real(dp)::theta_mag=0.      !angle between magnetic field and rotation axis
  real(dp)::thet_mag=0.      !angle between magnetic field and rotation axis

  real(dp):: C2_vis=0.0d0 !Von Neumann & Richtmeyer artificial viscosity coefficient 3 en principe
  real(dp):: alpha_dense_core=0.5d0
  real(dp):: beta_dense_core=0.0d0
  real(dp):: crit=0.0d0
  real(dp):: delta_rho=0.0d0
  real(dp):: Mach=0.0d0
  real(dp):: r0_box=4.0d0

  !delayed gravity
  !gravity forces are applied only after this time (this is typically to prepare initial conditions)
  !time_grav is assumed to be in Myr 
  real(dp)::time_grav=0.0d0


end module cloud_module





!================================================================
!================================================================
!================================================================
!================================================================

subroutine calc_dmin(d_c)
  use amr_commons
  use hydro_commons
  use cloud_module
  implicit none

  real(dp):: d_c, cont_ic, dmin

  cont_ic = 10.
  dmin = d_c / cont / cont_ic

  if (myid == 1) then
    write(*,*) "dmin = ", dmin
  endif
end subroutine calc_dmin
!================================================================
!================================================================
!================================================================
!================================================================
subroutine calc_boxlen
  use amr_commons
  use amr_parameters
  use hydro_commons
  use poisson_parameters
  use cloud_module
!  use const
  implicit none
  !================================================================
  !this routine calculate boxlen
  !================================================================
  integer :: i
  real(dp):: pi
  real(dp):: d_c,zeta
  real(dp):: res_int,r_0,C_s
  integer::  np
  real(dp)::scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2
  real(dp),save:: first
  real(dp):: mu=1.4d0 ! NOTE - MUST BE THE SAME AS IN units.f90!!
!  real(dp)::myid

!   myid=1

    if (first .eq. 0.) then

    pi=acos(-1.0d0)

    call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
    scale_T2 = scale_T2 * mu

    !calculate the mass in code units (Msolar / Mparticle / pc^3
    mass_c = mass_c * (2.d33 / (scale_d * scale_l**3) )

    !calculate the sound speed
    C_s = sqrt( T2_star / scale_T2)

    !calculate  zeta=r_ext/r_0
    zeta = sqrt(cont - 1.)

    !calculate an integral used to compute the cloud radius
    np=1000
    res_int=0.
    do i=1,np
     res_int = res_int + log(1.+(zeta/np*i)**2) * zeta/np
    enddo
    res_int = zeta*log(1.+zeta**2) - res_int

    !now we determine the central density and the external cloud radius
    !we have mass = 2 pi rho_c r_0^2 z_0 * res_int
    !which results from the integration of rho = dc/(1.+(x^2+y^2)/r_O^2+z^2/z_0^2)
    !for (x^2+y^2)/r_O^2+z^2/z_0^2 < zeta
    !we also have ff_sct = sqrt(3. pi / 32 / G / d_c) C_s / (r_0)
    !which just state the ratio of freefall time over sound crossing time
    !from these 2 formula, rho_c and r_0 are found to be:



    r_0 = mass_c / (2.*pi*rap*res_int) * (ff_sct)**2 / (3.*pi/32.) / C_s**2

    d_c = mass_c / (2.*pi*rap*res_int) / r_0**3

    !it is equal to twice the length of the major axis
    boxlen = r_0 * zeta * max(rap,1.) * 4.

    ! Multiply boxlen by an extra factor
    boxlen = bl_fac * boxlen

    if (myid == 1) then
    write(*,*) '** Cloud parameters estimated in calc-boxlen **'
    write(*,*) 'inner radius (pc) ', r_0
    write(*,*) 'peak density (cc) ', d_c
    write(*,*) 'total box length (pc) ', boxlen
    write(*,*) 'cloud mass (code units) ', mass_c
    write(*,*) 'boxlen (code units) ',boxlen
    write(*,*)
    endif



    first=1.
    endif

    call calc_dmin(d_c)

end subroutine calc_boxlen
!#########################################################
!#########################################################
!#########################################################
subroutine read_cloud_params(nml_ok)

  use amr_parameters
  use clfind_commons
  use cloud_module

  implicit none
  logical::nml_ok
  real(dp)::cellsize
  real(dp)::scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2
  real(dp),parameter::pcincm=3.086d18

  !--------------------------------------------------
  ! Namelist definitions
  !--------------------------------------------------
  namelist/cloud_params/mass_c,rap,cont,ff_sct,ff_rt,ff_act,ff_vct,thet_mag &
       & ,bl_fac !, scale_tout,time_grav

  ! Read namelist file
  rewind(1)
  read(1,NML=cloud_params,END=101)
101 continue                                   ! No harm if no namelist

  ! Get some units out there
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

  !convert time_grav from Myr into scale_units
  time_grav = time_grav * 1d6 * 365.25d0 * 86400d0 / scale_t


  ! Calculate boxlen
  if (mass_c .gt. 0) then
     call calc_boxlen
  end if

  !since boxlen is not known initialy we must multiply the
  !refining parameters by boxlen here
  x_refine = x_refine*boxlen
  y_refine = y_refine*boxlen
  z_refine = z_refine*boxlen
  r_refine = r_refine*boxlen

end subroutine read_cloud_params

!================================================================
!================================================================
!================================================================
!================================================================
subroutine condinit_cloud(x,u,dx,nn)
  use amr_commons
  use amr_parameters
  use hydro_commons
  use cloud_module
  use poisson_parameters
!  use const
  implicit none
  integer ::nn                              ! Number of cells
  real(dp)::dx                              ! Cell size
  real(dp),dimension(1:nvector,1:nvar+3)::u ! Conservative variables
  real(dp),dimension(1:nvector,1:ndim)::x ! Cell center position.
  !================================================================
  ! This routine generates initial conditions for RAMSES.
  ! Positions are in user units:
  ! x(i,1:3) are in [0,boxlen]**ndim.
  !TAKE CARE at this stage and  in this version this is not true for the
  ! first time that condinit is called
  ! because boxlen is determined in condinit
  ! for the first call x(i,1:3) are in  [0.,1.]
  ! U is the conservative variable vector. Conventions are here:
  ! U(i,1): d, U(i,2:ndim+1): d.u,d.v,d.w and U(i,ndim+2): E.
  ! Q is the primitive variable vector. Conventions are here:
  ! Q(i,1): d, Q(i,2:ndim+1):u,v,w and Q(i,ndim+2): P.
  ! If nvar >= ndim+3, remaining variables are treated as passive
  ! scalars in the hydro solver.
  ! U(:,:) and Q(:,:) are in user units.
  !================================================================
  integer :: i,j,k,id,iu,iv,iw,ip
  real(dp):: pi
  integer :: ivar
  real(dp),dimension(1:nvector,1:nvar+3),save::q   ! Primitive variables

  real(dp),save:: first
  real(dp),dimension(1:3,1:100,1:100,1:100),save::q_idl
  real(dp),save::vx_tot,vy_tot,vz_tot,vx2_tot,vy2_tot,vz2_tot
  integer,save:: n_size
  integer:: ind_i, ind_j, ind_k
  real(dp),save:: d_c,B_c,ind,seed1,seed2,seed3,xi,yi,zi,zeta
  real(dp),save:: res_int,r_0,C_s,omega,v_rms,cont_ic,mass_total,mass_tot2,min_col_d,max_col_d
  real(dp):: col_d,eli,sph,vx,vy,vz
  real(dp)::scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2
  real(dp)::xl,yl,zl,xx,yy,zz,bx,by,bz,dxmin
  integer:: ii,jj,kk,nticks
  real(dp)::ener_rot,ener_grav,ener_therm,ener_grav2,ener_turb
  real(dp),dimension(1000):: mass_rad
  real(dp):: mu=1.4d0 ! NOTE - MUST BE THE SAME AS IN units.f90!!
!  real(dp)::myid
  real(dp)::P_WNM=0.0d0
  logical :: turbvalid = .false.

!    myid=1


  ! Call built-in initial condition generator
  call region_condinit(x,q,dx,nn)

   !do various things which needs to be done only one time
   if( first .eq. 0.) then
    id=1; iu=2; iv=3; iw=4; ip=5
    pi=acos(-1.0d0)



    if(myid==1) write(*,*) '** ENTER  in condinit **'

    call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
    scale_T2 = scale_T2 * mu

    !calculate the mass in code units (Msolar / Mparticle / pc^3
!    mass_c = mass_c * (2.d33 / (scale_d * scale_l**3) )
!    done in calc_boxlen

    if(myid ==1) write(*,*) 'cloud mass (code units) ',mass_c

    !calculate the sound speed
    C_s = sqrt( T2_star / scale_T2 )
    ! Set a WNM pressure with T=8000K and nH=0.5
    P_WNM = 8000d0/scale_T2 * 0.5/scale_nH


    if(myid == 1)  write(*,*) 'T2_star (K) ', T2_star
    if(myid == 1)  write(*,*)  'C_s (code unist) ', C_s

    !cont_ic is the density contrast between the edge of the cloud and the intercloud medium
    cont_ic = 10.

    !calculate  zeta=r_ext/r_0
    zeta = sqrt(cont - 1.)


    !calculate an integral used to compute the cloud radius
    res_int=0.
    do i=1,1000
     res_int = res_int + log(1.+(zeta/1000.*i)**2) * zeta/1000.
     mass_rad(i) = i*zeta/1000. * log(1+(zeta/1000.*i)**2) - res_int
    enddo
    res_int = zeta*log(1.+zeta**2) - res_int


    !now we determine the central density and the external cloud radius
    !we have mass = 2 pi rho_c r_0^2 z_0 * res_int
    !which results from the integration of rho = dc/(1.+(x^2+y^2)/r_O^2+z^2/z_0^2)
    !for (x^2+y^2)/r_O^2+z^2/z_0^2 < zeta
    !we also have ff_sct = sqrt(3. pi / 32 / G / d_c) C_s / (r_0 )
    !which just state the ratio of freefall time over sound crossing time
    !from these 2 formula, rho_c and r_0 are found to be:

    !ph 01/09 new definition entails r_0 instead of r_0 * zeta, the external radius
    r_0 = mass_c / (2.*pi*rap*res_int) * (ff_sct)**2 / (3.*pi/32.) / C_s**2

    if (myid ==1) write(*,*) 'inner radius (pc) ',r_0

    d_c = mass_c / (2.*pi*rap*res_int) / r_0**3

    if(myid ==1) write(*,*) 'central density ',d_c



    ener_therm = 3./2.*mass_c*C_s**2
    ener_grav  = 3./5.*(mass_c**2)/(r_0*zeta)
    ener_grav2=0.
    do i=1,1000
     ener_grav2 = ener_grav2 + (i*zeta/1000.) / (1.+(zeta/1000.*i)**2) * zeta/1000. * mass_rad(i)
    enddo
    ener_grav2 = ener_grav2 * 8.*(pi**2)*(d_c**2)*(r_0**5)



    !angular velocity
    omega = ff_rt * 2.*pi * sqrt( 32.*d_c/3./pi)

    !central value of magnetic field
    !remember magnetic variable is B/sqrt(4pi)

    !ph 01/09 new definition entails r_0 instead of r_0 * zeta, the external radius
    B_c = ff_act * sqrt( 32./3./pi) * d_c * r_0


    mass_sph = d_c / cont * (boxlen*(0.5**levelmin))**3

    !the smallest initial column density
    min_col_d = boxlen * d_c / cont / cont_ic

    !the largest initial column density
    !obtained by integrating the density distribution through the box
    max_col_d = r_0*d_c*atan(zeta) + (boxlen -2.*r_0*zeta) * d_c / cont / cont_ic

    if (myid==1) write(*,*) 'valeur du champ magnetique central non normalise B_c', B_c
    if (myid==1) write(*,*) 'valeur du champ magnetique a l exterieur ', B_c*min_col_d/max_col_d

    !calculate the value of mu the mass to flux over critical mass to flux ratio
    !from Mouschovias & Spitzer 1979 M/phi)_crit = 1/(3pi) * sqrt(5/G) * 0.53
    !since B(r)=B_c * sig(r)/sig(0), phi = B_c * mass_c / sig(0)
    !thus mass_c / phi = sig(0) / B_c
    !taking into account the fact that B_c = champ mag / sqrt(4 pi)
    ! we have in code units mu = sig(0) / (B_c*sqrt(4 pi)) / (sqrt(5)/(3 pi) * 0.53)
#ifdef SOLVERmhd
    if (myid ==1) write(*,*) 'the mass to flux over critical mass to flux ratio in the case of a spheroidal cloud (not correct if rap ne 1)'
    if (myid ==1) write(*,*) 'mu= ',max_col_d / (B_c*sqrt(4.*pi)) / (sqrt(5.)/(3.*pi) * 0.53)
    !note here we make the approximation that max_col_d is equal to the column density through the cloud which is note exactly
    !the case since the column density of the external medium is also taken into account
#endif


    !now read the turbulent velocity field used as initial condition
    if( myid ==1) write(*,*) 'Read the file which contains the initial turbulent velocity field'
    open(20,file=file_init_turb,form='formatted')
    read(20,*) n_size, ind, seed1,seed2,seed3

     if(n_size .ne. 100) then
       write(*,*) 'Unextected field size'
       stop
     endif

     v_rms=0.
     mass_total=0.
     mass_tot2 =0.
     do k=1,n_size
     do j=1,n_size
     do i=1,n_size
        read(20,*)xi,yi,zi,vx,vy,vz
        q_idl(1,i,j,k) = vx
        q_idl(2,i,j,k) = vy
        q_idl(3,i,j,k) = vz

        xi = boxlen/bl_fac*((i-0.5)/n_size-0.5)
        yi = boxlen/bl_fac*((j-0.5)/n_size-0.5)
        zi = boxlen/bl_fac*((k-0.5)/n_size-0.5)
        eli =  (xi/r_0)**2+(yi/r_0)**2+(zi/(r_0*rap))**2
        if( eli .lt. zeta**2) then

         vx_tot = vx_tot + d_c/(1.+eli)*vx
         vy_tot = vy_tot + d_c/(1.+eli)*vy
         vz_tot = vz_tot + d_c/(1.+eli)*vz

         vx2_tot = vx2_tot + d_c/(1.+eli)*vx**2
         vy2_tot = vy2_tot + d_c/(1.+eli)*vy**2
         vz2_tot = vz2_tot + d_c/(1.+eli)*vz**2

         ener_turb = ener_turb + d_c/(1.+eli)*(vx**2+vy**2+vz**2)
         mass_total = mass_total +  d_c / (1.+eli)
         ener_rot = ener_rot + d_c/(1.+eli) * omega**2 * (yi**2 + zi**2)
        endif
     enddo
     enddo
     enddo
    close(20)

     vx_tot = vx_tot / mass_total
     vy_tot = vy_tot / mass_total
     vz_tot = vz_tot / mass_total

     vx2_tot = vx2_tot / mass_total
     vy2_tot = vy2_tot / mass_total
     vz2_tot = vz2_tot / mass_total

     v_rms = sqrt( vx2_tot-vx_tot**2 + vy2_tot-vy_tot**2 + vz2_tot-vz_tot**2 )

     mass_total = mass_total*(boxlen/n_size)**3
     if (myid ==1) write(*,*) 'We verify the calculation for the mass. The 2 following values must be very close:'
     if (myid ==1) write(*,*) 'mass_total, mass_c ',mass_total, mass_c !,mass_tot2

     ener_rot  = 0.5 * ener_rot*(boxlen/n_size)**3
     ener_turb = 0.5 * ener_turb*(boxlen/n_size)**3

     !estimate of the thermal over gravitational energy
     if (myid == 1) write(*,*) 'estimate (uniform density is assumed) of the ratio of thermal over gravitational energy'
     if (myid == 1) write(*,*)  ener_therm / ener_grav

     if (myid == 1) write(*,*) 'good estimate of the ratio of thermal over gravitational energy'
     if (myid == 1) write(*,*)  ener_therm / ener_grav2

     !estimate of the rotational over gravitational energy ratio
     if (myid .eq. 1) write(*,*) 'estimate of the rotational over gravitational energy ratio'
     if (myid .eq. 1) write(*,*) 'ener_rot/ener_grav2 ', ener_rot / ener_grav2


     !calculate now the coefficient by which the turbulence velocity needs
     !to be multiplied

     if (myid .eq. 1) write(*,*) 'vrms non norm ',v_rms

    !ph 01/09 new definition entails r_0 instead of r_0 * zeta, the external radius
     v_rms = ff_vct * sqrt(32.*d_c/3./pi)*r_0 / v_rms

     if (myid .eq. 1) write(*,*) 'vrms mult ',v_rms


     !estimate of the turbulent over gravitational energy ratio
     if (myid .eq. 1) write(*,*) 'estimate of the turbulent over gravitational energy ratio'
     if (myid .eq. 1) write(*,*) 'ener_turb/ener_grav2 ', ener_turb*(v_rms**2) / ener_grav2



    100 format(i5,4e12.5)
    101 format(6e12.5)
    102 format(i5)

    if (myid ==1)  write(*,*) 'Reading achieved'
    first = 1.
   endif


   DO i=1,nn


       x(i,1) = x(i,1) - 0.5*boxlen
       x(i,2) = x(i,2) - 0.5*boxlen
       x(i,3) = x(i,3) - 0.5*boxlen


       !initialise the density field
       eli =  (x(i,1)/r_0)**2+(x(i,2)/r_0)**2+(x(i,3)/(r_0*rap))**2



       if( eli .le. zeta**2) then
          ! Is inside the cloud
          q(i,1) = d_c / (1.+eli)
          q(i,5) = q(i,1) * C_s**2
          q(i,5) = max(q(i,5),P_WNM)
       else if (eli .le. 4*zeta**2) then
          ! Is inside a circle of diameter boxlen
          q(i,1) = d_c / cont / cont_ic
          q(i,5) = q(i,1) * C_s**2
          !if the cloud is in pressure equilibrium with the surrounding medium
          !remove this line if the IC gas is isothermal as well
          !        q(i,5) = q(i,5) * cont_ic
          q(i,5) = max(q(i,5),P_WNM)
       else
          ! External medium
          ! Is inside a circle of diameter boxlen
          ! NOTE - Here we heat up the gas (by 1/0.8) so P_ext > P_cloud
          ! This is to balance extra turbulent KE energy in the cloud
          ! This is only an issue if B~0, otherwise B contains the cloud
          q(i,1) = 1d0 !d_c / cont / cont_ic / 100d0
          q(i,5) = q(i,1) * C_s**2
          q(i,5) = max(q(i,5),P_WNM/0.8d0)
       end if


       if(all(abs(x(i,:) / (boxlen / bl_fac)) <= 0.5)) then
         !initialise the turbulent velocity field
         !make a zero order interpolation (should be improved)
         ind_i = int((x(i,1)/(boxlen/bl_fac)+0.5)*n_size)+1
         ind_j = int((x(i,2)/(boxlen/bl_fac)+0.5)*n_size)+1
         ind_k = int((x(i,3)/(boxlen/bl_fac)+0.5)*n_size)+1

         ! Is this a valid cell for the turbulence?
         turbvalid = .true.
         ! Periodic hack
         ind_i = 1+modulo(ind_i-1, n_size)
         ind_j = 1+modulo(ind_j-1, n_size)
         ind_k = 1+modulo(ind_k-1, n_size)

         !if (turbvalid) then
         q(i,2) = v_rms*(q_idl(1,ind_i,ind_j,ind_k)-vx_tot)
         q(i,3) = v_rms*(q_idl(2,ind_i,ind_j,ind_k)-vy_tot)
         q(i,4) = v_rms*(q_idl(3,ind_i,ind_j,ind_k)-vz_tot)
         !endif

         !add  rotation. x cos(thet_mag) + y sin(thet_mag) is the rotation axis
         sph =  (x(i,1)/r_0)**2+(x(i,2)/r_0)**2+(x(i,3)/(r_0))**2
         if( sph .lt. (zeta*rap)**2 ) then

         !to check these formulae one can verify that those arrays are perpendicular
         !with (cos(thet_mag),sin(thet_mag),0) and that the norm of the vectorial product of
         ! (cos(thet_mag),sin(thet_mag),0) by the above arrays is equal to the distance
         !  (x sin(thet)-y cos(thet))^2 + z^2
           q(i,2) = q(i,2) - (omega*x(i,3)*sin(thet_mag))
           q(i,3) = q(i,3) + (omega*x(i,3)*cos(thet_mag))
           q(i,4) = q(i,4) + (omega*(x(i,1)*sin(thet_mag)-x(i,2)*cos(thet_mag)))
         endif
       else
         q(i, 2:4) = 0.0
       endif


  ENDDO


  dxmin=boxlen*0.5d0**(nlevelmax)

  if( dx .lt. dxmin) then
    write(*,*) 'dxmin too large'
    write(*,*) 'dx ',dx/boxlen
    write(*,*) 'dxmin ',dxmin/boxlen
    stop
  endif

  nticks=dx/dxmin


!Set all scalar variables to 0 initially
!Include, radiation, extinction and passive scalar
     DO i=1,nn
        q(i,9:nvar) = 0d0
     ENDDO ! LAYS EGGS



#ifdef SOLVERmhd
   DO i=1,nn
   q(i,6)=0.

     xl=x(i,1)-0.5*dx
     yl=x(i,2)-0.5*dx
     zl=x(i,3)-0.5*dx

     !the magnetic field in cells must be subdivided in order to insure that the magnetic
     !flux is the same in coarse and refined grids
     DO jj=1,nticks
     DO kk=1,nticks

        yy=yl+(dble(jj)-0.5d0)*dxmin
        zz=zl+(dble(kk)-0.5d0)*dxmin

       !this formula comes from the integration of the density distribution along x
       eli = (yy/r_0)**2 + (zz/r_0/rap)**2
        if( eli .lt. zeta**2) then
         col_d = r_0*d_c/sqrt(1.+eli)*atan( sqrt( (zeta**2-eli)/(1.+eli) ) )
         col_d = max(col_d,min_col_d)
        else
         col_d = min_col_d
        endif

       !Bx component
       q(i,6     ) = q(i,6) + B_c * col_d / max_col_d
       q(i,nvar+1) = q(i,6)

       !By component
       q(i,7     ) = 0.
       q(i,nvar+2) = 0.

       !Bz component
       q(i,8     ) = 0.
       q(i,nvar+3) = 0.

     ENDDO
     ENDDO

       q(i,6:8)           = q(i,6:8)           / dble(nticks)**2

       q(i,nvar+1:nvar+3) = q(i,6:8)
  ENDDO
#endif

  ! Convert primitive to conservative variables
  ! density -> density
  u(1:nn,1)=q(1:nn,1)
  ! velocity -> momentum
  u(1:nn,2)=q(1:nn,1)*q(1:nn,2)
  u(1:nn,3)=q(1:nn,1)*q(1:nn,3)
  u(1:nn,4)=q(1:nn,1)*q(1:nn,4)
  ! kinetic energy
  u(1:nn,5)=0.0d0
  u(1:nn,5)=u(1:nn,5)+0.5*q(1:nn,1)*q(1:nn,2)**2
  u(1:nn,5)=u(1:nn,5)+0.5*q(1:nn,1)*q(1:nn,3)**2
  u(1:nn,5)=u(1:nn,5)+0.5*q(1:nn,1)*q(1:nn,4)**2
  !kinetic + magnetic energy
#ifdef SOLVERmhd
  u(1:nn,5)=u(1:nn,5)+0.125*(q(1:nn,6)+q(1:nn,nvar+1))**2
  u(1:nn,5)=u(1:nn,5)+0.125*(q(1:nn,7)+q(1:nn,nvar+2))**2
  u(1:nn,5)=u(1:nn,5)+0.125*(q(1:nn,8)+q(1:nn,nvar+3))**2
#endif
  ! thermal pressure -> total fluid energy
  u(1:nn,5)=u(1:nn,5)+q(1:nn,5)/(gamma-1.0d0)
  ! magnetic field
#ifdef SOLVERmhd
  u(1:nn,6:8)=q(1:nn,6:8)
  u(1:nn,nvar+1:nvar+3)=q(1:nn,nvar+1:nvar+3)
  ! passive scalars
  do ivar=9,nvar
     u(1:nn,ivar)=q(1:nn,1)*q(1:nn,ivar)
  end do
#else
  ! passive scalars
  do ivar=6,nvar
     u(1:nn,ivar)=q(1:nn,1)*q(1:nn,ivar)
  end do
#endif

end subroutine condinit_cloud
!================================================================
!================================================================
!================================================================
!================================================================
