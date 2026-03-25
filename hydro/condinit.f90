!================================================================
!================================================================
!================================================================
!================================================================
subroutine condinit(x,u,dx,nn)
  use amr_commons
  use hydro_parameters
  implicit none
  integer ::nn                            ! Number of cells
  real(dp)::dx                            ! Cell size
  real(dp),dimension(1:nvector,1:nvar)::u ! Conservative variables
  real(dp),dimension(1:nvector,1:ndim)::x ! Cell center position.
  logical,save:: first_call = .true.       ! True if this is the first call to condinit
  !================================================================
  ! This routine generates initial conditions for RAMSES.
  ! Positions are in user units:
  ! x(i,1:3) are in [0,boxlen]**ndim.
  ! U is the conservative variable vector. Conventions are here:
  ! U(i,1): d, U(i,2:ndim+1): d.u,d.v,d.w and U(i,ndim+2=neul): E.
  ! Q is the primitive variable vector. Conventions are here:
  ! Q(i,1): d, Q(i,2:ndim+1):u,v,w and Q(i,ndim+2=neul): P.
  ! If nvar >= ndim+3=nhydro+1, remaining variables are treated as passive
  ! scalars in the hydro solver.
  ! U(:,:) and Q(:,:) are in user units.
  !================================================================
#if NENER>0 || NVAR>NHYDRO+NENER
  integer::ivar
#endif
  real(dp),dimension(1:nvector,1:nvar),save::q   ! Primitive variables

  select case (condinit_kind)

  case('region')
    ! Call built-in initial condition generator
     call region_condinit(x, q, dx, nn)

  case('ana_disk_potential')
     call ana_disk_potential_condinit(x, q, dx, nn)

  case('SIS')
     call sis_condinit(x, q, dx, nn)

  ! Add here, if you wish, some user-defined initial conditions
  ! ........

  case DEFAULT
     if (myid == 1.and. first_call)  write(*,*) "[condinit] Void or invalid condinit_kind, using default IC"
     call region_condinit(x, q, dx, nn)

  end select

  first_call = .false.

  ! Convert primitive to conservative variables
  ! density -> density
  u(1:nn,1)=q(1:nn,1)
  ! velocity -> momentum
  u(1:nn,2)=q(1:nn,1)*q(1:nn,2)
#if NDIM>1
  u(1:nn,3)=q(1:nn,1)*q(1:nn,3)
#endif
#if NDIM>2
  u(1:nn,4)=q(1:nn,1)*q(1:nn,4)
#endif
  ! kinetic energy
  u(1:nn,neul)=0.0d0
  u(1:nn,neul)=u(1:nn,neul)+0.5d0*q(1:nn,1)*q(1:nn,2)**2
#if NDIM>1
  u(1:nn,neul)=u(1:nn,neul)+0.5d0*q(1:nn,1)*q(1:nn,3)**2
#endif
#if NDIM>2
  u(1:nn,neul)=u(1:nn,neul)+0.5d0*q(1:nn,1)*q(1:nn,4)**2
#endif
  ! thermal pressure -> total fluid energy
  u(1:nn,neul)=u(1:nn,neul)+q(1:nn,neul)/(gamma-1.0d0)
#if NENER>0
  ! radiative pressure -> radiative energy
  ! radiative energy -> total fluid energy
  do ivar=1,nener
     u(1:nn,nhydro+ivar)=q(1:nn,nhydro+ivar)/(gamma_rad(ivar)-1.0d0)
     u(1:nn,neul)=u(1:nn,neul)+u(1:nn,nhydro+ivar)
  enddo
#endif
#if NVAR>NHYDRO+NENER
  ! passive scalars
  do ivar=nhydro+1+nener,nvar
     u(1:nn,ivar)=q(1:nn,1)*q(1:nn,ivar)
  end do
#endif

end subroutine condinit


!================================================================
!================================================================
!================================================================
!================================================================
subroutine ana_disk_potential_condinit(x,q,dx,nn)
  use amr_parameters
  use hydro_parameters
  use constants

  implicit none
  integer ::nn                            ! Number of cells
  real(dp)::dx                            ! Cell size
  real(dp),dimension(1:nvector,1:nvar)::q ! Primitive variables
  real(dp),dimension(1:nvector,1:ndim)::x ! Cell center position.
  !================================================================
  ! This routine generates an analytical disk potential initial conditions for RAMSES.
  !================================================================
  real(dp)::scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2
  integer::i

  real(dp)::height0=150 ! disk height [c.u.]
  real(dp)::dens0=0.66d0 ! central density [c.u.]
  real(dp)::temp0=8000  ! initial temperature [T]

  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

  ! Call built-in initial condition generator
  call region_condinit(x,q,dx,nn)

  do i=1,nn
    ! density
    ! exponential profile along z
    q(i,1) = dens0 * exp(-( x(i,ndim) - 0.5d0 * boxlen)**2 / (2.*height0**2))

    ! pressure via constant temperature
    ! ideal gas: P = n kB T
    q(i,ndim+2) = q(i,1) * (kB*temp0/(mu_gas*mH))/scale_v**2

  end do

end subroutine ana_disk_potential_condinit
!================================================================
!================================================================
!================================================================
!================================================================
subroutine sis_condinit(x,q,dx,nn)
  use amr_parameters
  use hydro_parameters
  use constants, only:pi,M_sun,kB,mH
  implicit none
  integer ::nn                            ! Number of cells
  real(dp)::dx                            ! Cell size
  real(dp),dimension(1:nvector,1:nvar)::q ! Primitive variables
  real(dp),dimension(1:nvector,1:ndim)::x ! Cell center position.
  !================================================================
  ! This routine generates Singular Isothermal Sphere (SIS) 
  ! initial conditions for RAMSES.
  !================================================================
  ! core parameters
  !real(dp)::core_mass=5 ! mass of the core in solar mass
  !real(dp)::core_size=1000 ! mass of the core in AU
  !real(dp)::core_rmin=10 ! radius where to flatten the density profile in AU
  !real(dp)::sigma2=0.2 ! radius where to flatten the density profile in AU
  real(dp)::r2,rx,ry,rz,d,p,vx,vy,vz,sigma,M,f,r_vortex,r_trunc,r_min2,omega_0,sigma2
  real(dp)::r_vortex2,cs2,omega,r_trunc2,fact,r_min
  real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v,scale_m,scale_p
  integer::i
  real(dp),parameter ::au2cm        = 1.4959787d+13

  ! Call built-in initial condition generator
  call region_condinit(x,q,dx,nn)

  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
  scale_m=scale_d*scale_l**3

  ! core parameters
  sigma = 41716.75560097597/scale_v
  M=20*M_sun/scale_m
  f = 0.3
  r_vortex=1000*au2cm/scale_l
  fact = 1

  ! derived parameters
  r_trunc = M / (2*sigma**2)             ! radius of the core
  r_min = 16 * boxlen/2**nlevelmax       ! profile flattening in the center at resolution limit
  !r_min = max(r_min, 200*au2cm/scale_l)
  r_min2 = r_min**2
  omega_0 = f * sigma/(r_vortex)

  ! precalculate square of parameters
  sigma2 = sigma**2
  r_vortex2 = r_vortex**2
  r_trunc2 = r_trunc**2

  ! print info
  ! boxlen should be 8 times the truncation radius

  ! isothermal soundspeed from T_eos and mu_gas in cooling_params
  cs2 = (kB*10d0/(2.37d0*mH)) / scale_v**2

  do i=1,nn
     ! compute radius from center of the box
     rx=x(i,1)-boxlen/2.
     r2 = rx**2
#if NDIM>1
     ry=x(i,2)-boxlen/2.
     r2 = r2 + ry**2
#endif
#if NDIM>2
     rz=x(i,3)-boxlen/2.
     r2 = r2 + rz**2
#endif

     ! density
     d = fact * sigma2/(2*pi*(r2+r_min2))

     ! rotation
     omega = omega_0 / sqrt(1 + (r2/r_vortex2))

     ! truncate sphere
     if (r2>=r_trunc2)then
        d=d*1.e-4
        omega=0
     end if

     q(i,1)=d
#if NDIM==1
    ! no rotation if 1D, pure collapse
     q(i,2)=0
#endif
#if NDIM>1
     ! rotating core if 2D or 3D
     q(i,2)= -1.*omega*ry
     q(i,3)= omega*rx
#endif
#if NDIM>2
     ! no vertical initial velocity
     q(i,4)=0.
#endif
     ! pressure
     q(i,neul)=d*cs2
  end do

end subroutine sis_condinit