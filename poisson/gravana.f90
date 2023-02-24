!#########################################################
!#########################################################
!#########################################################
!#########################################################
subroutine gravana(x,f,dx,ncell)
  use amr_parameters
  use poisson_parameters
  use poisson_commons, only: multipole
  use constants, only: mH, twopi, Myr2sec, factG_in_cgs

  implicit none
  integer ::ncell                         ! Size of input arrays
  real(dp)::dx                            ! Cell size
  real(dp),dimension(1:nvector,1:ndim)::f ! Gravitational acceleration
  real(dp),dimension(1:nvector,1:ndim)::x ! Cell center position.
  !================================================================
  ! This routine computes the acceleration using analytical models.
  ! x(i,1:ndim) are cell center position in [0,boxlen] (user units).
  ! f(i,1:ndim) is the gravitational acceleration in user units.
  !================================================================
  integer::idim,i
  real(dp)::gmass,emass,xmass,ymass,zmass,rr,rx,ry,rz
  real(dp):: a1,a2,z0,a1_rho,a2_rho,sigma,f_max

  select case (gravity_type)

  case(1)
    ! Constant vector
     do idim=1,ndim
        do i=1,ncell
           f(i,idim)=gravity_params(idim)
        end do
     end do

  case(2)
    ! Point mass
     gmass=gravity_params(1) ! GM
     emass=dx
     emass=gravity_params(2) ! Softening length
     xmass=gravity_params(3) ! Point mass coordinates
     ymass=gravity_params(4)
     zmass=gravity_params(5)
     do i=1,ncell
        rx=0.0d0; ry=0.0d0; rz=0.0d0
        rx=x(i,1)-xmass
#if NDIM>1
        ry=x(i,2)-ymass
#endif
#if NDIM>2
        rz=x(i,3)-zmass
#endif
        rr=sqrt(rx**2+ry**2+rz**2+emass**2)
        f(i,1)=-gmass*rx/rr**3
#if NDIM>1
        f(i,2)=-gmass*ry/rr**3
#endif
#if NDIM>2
        f(i,3)=-gmass*rz/rr**3
#endif
     end do

  case(3)
    ! Add the vertical galactic gravitational field
    ! Kuijken & Gilmore 1989 taken from Joung & MacLow (2006)
    a1 = gravity_params(1) ! Star potential coefficient in kpc Myr-2
    a2 = gravity_params(2) ! DM potential coefficient in Myr-2
    z0 = gravity_params(3) ! Scale height in pc scale height in pc in kpc Myr-2
    ! If negative value, use default values
    if(a1 < 0.) a1 = 1.42d-3
    if(a2 < 0.) a2 = 5.49d-4
    if(z0 <= 0.) z0 = 0.18d3

    a1=1.d3*a1/(Myr2sec**2)/mH/factG_in_cgs
    a2=a2/(Myr2sec**2)/mH/factG_in_cgs

    ! TC archeology: sigma is column density, we take into account the weigth of the gas
    !                when self-gravity is off. 
    !sigma = multipole(1)/(boxlen**2)
    !f_max=(a1*0.5*boxlen)/(((0.5*boxlen)**2+z0**2)**0.5) + a2*(0.5*boxlen)
    do i=1,ncell
      x(i,3)=x(i,3)-0.5*boxlen
      f(i,3)=-(a1*x(i,3))/(((x(i,3))**2+z0**2)**0.5) + a2*(x(i,3))
      ! Patrick: Bug? This should be f - sigma... probably.
      !f(i,3) = f(i,3) * sigma / (2.*f_max / 2*twopi)
    end do
  end select

end subroutine gravana
!#########################################################
!#########################################################
!#########################################################
!#########################################################
subroutine phi_ana(rr,pp,ngrid)
  use amr_commons
  use poisson_commons
  use constants, only: twopi
  implicit none
  integer::ngrid
  real(dp),dimension(1:nvector)::rr,pp
  ! -------------------------------------------------------------------
  ! This routine set up boundary conditions for fine levels.
  ! -------------------------------------------------------------------

  integer :: i
  real(dp):: fourpi

  fourpi=2*twopi

#if NDIM==1
  do i=1,ngrid
     pp(i)=multipole(1)*fourpi/2*rr(i)
  end do
#endif
#if NDIM==2
  do i=1,ngrid
     pp(i)=multipole(1)*2*log(rr(i))
  end do
#endif
#if NDIM==3
  do i=1,ngrid
     pp(i)=-multipole(1)/rr(i)
  end do
#endif
end subroutine phi_ana
