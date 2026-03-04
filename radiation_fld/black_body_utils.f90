!###########################################################
!###########################################################
!###########################################################
!###########################################################

module coeff_xi
  use amr_parameters, only:dp
  real(dp), parameter :: C0 = -6.4939394022668291494e+00_dp
  real(dp), parameter :: C1 = -7.2459729120796762965e+00_dp
  real(dp), parameter :: C2 = -4.0425479966955722625e+00_dp
  real(dp), parameter :: C3 = -1.1702323487246738515e+00_dp
  real(dp), parameter :: C4 = -0.1738347185981371462e+00_dp
  real(dp), parameter :: C5 = -0.7276729479633296956e-02_dp
  real(dp), parameter :: C6 =  6.4939394022668291494e+00_dp
  real(dp), parameter :: C7 =  1.1158054400000000000e+00_dp
  real(dp), parameter :: limhigh = 1.0e+02_dp, limlow = 2.0e-05_dp
end module coeff_xi

!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function RADIATION_SOURCE
!
!> Computes radiation source
!<
function radiation_source(T,igrp)
  use const
  use constants, only: a_r
  use hydro_parameters, only:ngrp
  use fld_parameters, only : grey_rad_transfer

  implicit none

  real(dp), intent(in) :: T
  integer , intent(in) :: igrp
  real(dp)             :: radiation_source,artheta4

  if(grey_rad_transfer)then
     radiation_source = a_r*T**4
  else
     if(T.gt.zero) then
        radiation_source = artheta4(T,igrp)
     else
        radiation_source = zero
     end if
  end if

end function radiation_source

!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function DERIV_RADIATION_SOURCE
!
!> Computes radiation source derivative
!<
function deriv_radiation_source(T,igrp)
  use const
  use constants, only: a_r
  use hydro_parameters, only:ngrp
  use fld_parameters, only : grey_rad_transfer
  implicit none

  real(dp), intent(in) :: T
  integer , intent(in) :: igrp
  real(dp)              :: deriv_radiation_source,deriv_artheta4

  if(grey_rad_transfer)then
     deriv_radiation_source = four*a_r*T**3
  else
     if(T.gt.zero) then
        deriv_radiation_source = deriv_artheta4(T,igrp)
     else
        deriv_radiation_source = zero
     end if
  end if

  return

end function deriv_radiation_source

!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Subroutine TABULATE_ART4
!
!> Tabulates the artheta4 function to find group interface
!! values for Eray in the comoving frame matter/radiation
!! coupling terms.
!<
subroutine tabulate_art4

  use amr_parameters,   only: dp
  use hydro_parameters, only: ngrp
  use fld_parameters,   only: Ninv_art4,inverse_art4_T,inverse_art4_E,dEr_inv_art4
  implicit none

  integer  :: i,igrp,j
  real(dp) :: T,T1,T2,artheta4,cal_Teg_slow,dTinv_art4

  allocate(inverse_art4_T(ngrp+1,Ninv_art4),inverse_art4_E(2,ngrp,Ninv_art4),dEr_inv_art4(ngrp))

  T1 = log10(1.0_dp) ; T2 = log10(1.0e+07_dp)

  dTinv_art4 = (T2 - T1)/real(Ninv_art4-1,dp)

  ! First pass: log-regular in temperature
  do i = 1,Ninv_art4
     T = real(i-1,dp)*dTinv_art4 + T1
     do igrp = 1,ngrp
        inverse_art4_T(igrp,i) = log10(artheta4(10.0_dp**(T),igrp))
     enddo
     inverse_art4_T(ngrp+1,i) = T
  enddo

  ! Second pass: re-sample curves with regular dEr
  do igrp = 1,ngrp
     dEr_inv_art4(igrp) = (inverse_art4_T(igrp,Ninv_art4) - inverse_art4_T(igrp,1))/real(Ninv_art4-1,dp)
     do i = 1,Ninv_art4
        inverse_art4_E(1,igrp,i) = real(i-1,dp)*dEr_inv_art4(igrp)+inverse_art4_T(igrp,1)
     enddo
  enddo
  ! Warning: do NOT merge this loop with the previous one (does not work with ifort -O3)
  do igrp=1,ngrp
     do i = 1,Ninv_art4
        inverse_art4_E(2,igrp,i) = cal_Teg_slow(inverse_art4_E(1,igrp,i),igrp)
     enddo
  enddo

  !deallocate(inverse_art4_T)

  return

end subroutine tabulate_art4

!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function ARTHETA4
!
!> Computes the energy of a Planck black body distribution
!! inside a given group.
!<
function artheta4(Tray,igrp)
  use amr_parameters, only:dp
  use fld_parameters, only : nu_min_hz,nu_max_hz,eray_min
  use constants, only:pi,hplanck,kB,c_cgs
  implicit none

  real(dp), intent(in) :: Tray
  integer , intent(in) :: igrp
  real(dp)             :: constant,xmin,xmax,xsimin,xsimax,xi,artheta4,BPlanck

  constant = (8d0*pi*kb**4)/(c_cgs*hplanck)**3

  xmin = hplanck*nu_min_hz(igrp)/(kb*Tray)
  xmax = hplanck*nu_max_hz(igrp)/(kb*Tray)

  xsimin = xi(xmin) ; xsimax = xi(xmax)

  if(xsimin==xsimax)then
     artheta4 = max(BPlanck(0.5d0*(nu_min_hz(igrp)+nu_max_hz(igrp)),Tray)*(nu_max_hz(igrp)-nu_min_hz(igrp)),eray_min)
  else
     artheta4 = max(constant*(Tray**4)*(xsimax-xsimin),eray_min)
  endif

  return

end function artheta4


!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function DERIV_ARTHETA4
!
!> Derivative of the artheta4() function which is used
!! to compute the radiative energy source term.
!<
function deriv_artheta4(Tray,igrp)

  use const
  use fld_parameters, only : nu_min_hz,nu_max_hz,eray_min,deray_min
  use constants, only:pi,hplanck,kB,c_cgs

  implicit none

  real(dp), intent(in) :: Tray
  integer , intent(in) :: igrp
  real(dp)             :: xi,deriv_xi,deriv_artheta4,nu,dnu,Div_BPlanck
  real(dp)             :: constant,xmin,xmax,xsimin,xsimax,v1,v2,v3

  constant = (8d0*pi*kb**4)/(c_cgs*hplanck)**3

  xmin = hplanck*nu_min_hz(igrp)/(kb*Tray)
  xmax = hplanck*nu_max_hz(igrp)/(kb*Tray)

  xsimin = xi(xmin) ; xsimax = xi(xmax)

  if(xsimin==xsimax)then
     deriv_artheta4 = max(Div_BPlanck(half*(nu_min_hz(igrp)+nu_max_hz(igrp)),Tray)*(nu_max_hz(igrp)-nu_min_hz(igrp)),deray_min)
  else
     v1 = four*constant*(Tray**3)*(xsimax-xsimin)
     v2 = deriv_xi(xmin,Tray)
     v3 = deriv_xi(xmax,Tray)
     deriv_artheta4 = v1 + constant*(Tray**4)*(v3-v2)
     deriv_artheta4 = max(deriv_artheta4,deray_min)
  endif

  return

end function deriv_artheta4

!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function DERIV_XI
!
!> Derivative of the xi() function which is used in the
!! artheta4() computations.
!<
function deriv_xi(x,T)

  use amr_parameters, only : dp
  use coeff_xi
  use const

  implicit none

  real(dp),intent(in) :: x,T
  real(dp)            :: deriv_xi,p0,p1,p2

  if(x >= limhigh)then
     deriv_xi = zero
  elseif(x <= limlow)then
     deriv_xi = zero
  else
     p0 = exp(-c7*x)
     p1 = c7*(x/T) * p0 * (c0 + c1*x + c2*(x**2) + c3*(x**3) + c4*(x**4) + c5*(x**5))
     p2 = -p0*( c1*x/T + 2.0d0*c2*(x**2)/T + 3.0d0*c3*(x**3)/T + 4.0d0*c4*(x**4)/T + 5.0d0*c5*(x**5)/T )
     deriv_xi = p1 + p2
  endif

end function deriv_xi

!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function XI
!
!> Used by artheta4() to compute the energy of a Planckian
!! distribution between two frequencies.
!<
function xi(nu)
  use amr_parameters, only:dp
  use coeff_xi
  use const
  implicit none

  real(dp),intent(in) :: nu
  real(dp)            :: xi

  if(nu >= limhigh)then
     xi = c6
  elseif(nu <= limlow)then
     xi = 0d0
  else
     xi = exp(-c7*nu) * ( c0 + c1*nu + c2*(nu**2) + c3*(nu**3) + c4*(nu**4) + c5*(nu**5) ) + c6
  endif

  if(xi < zero)then
     write(*,*)'negative xi!',xi,nu
     read(*,*)
  endif

end function xi

!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function BPLANCK
!
!> Computes the Planck Black Body distribution function.
!<
function BPlanck(nu,T)

  use amr_parameters, only : dp
  use coeff_xi      , only : limhigh
  use constants, only:pi,hplanck,kB,c_cgs

  implicit none

  real(dp), intent(in) :: nu,T
  real(dp)             :: BPlanck

  if((hplanck*nu/(kb*T)) > limhigh)then
     BPlanck = (8d0*pi*hplanck*nu**3)/c_cgs**3 * exp(-hplanck*nu/(kb*T))
  else
     BPlanck = (8d0*pi*hplanck*nu**3)/c_cgs**3 / ( exp(hplanck*nu/(kb*T)) - 1d0 )
  endif

end function BPlanck
!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function CAL_TEG
!
!> Computes the temperature of a black body which would
!! provide the same energy as Eg inside a given group igrp.
!<
function cal_Teg(Eg,igrp)
  use amr_parameters, only : dp
  use fld_parameters, only : inverse_art4_E,Ninv_art4,dEr_inv_art4

  implicit none

  real(dp), intent(in) :: Eg
  integer , intent(in) :: igrp
  integer              :: iEg
  real(dp)             :: cal_Teg,m,x1,x2,y1,y2,lEg

  lEg = log10(Eg)

  if(lEg < inverse_art4_E(1,igrp,1))then
     cal_Teg = inverse_art4_E(2,igrp,1)
  elseif(lEg >= inverse_art4_E(1,igrp,Ninv_art4))then
     cal_Teg = inverse_art4_E(2,igrp,Ninv_art4)
  else
     iEg = int((lEg-inverse_art4_E(1,igrp,1))/dEr_inv_art4(igrp)) + 1
     x1 = inverse_art4_E(1,igrp,iEg  )
     x2 = inverse_art4_E(1,igrp,iEg+1)
     y1 = inverse_art4_E(2,igrp,iEg  )
     y2 = inverse_art4_E(2,igrp,iEg+1)
     ! compute gradient
     m = (y2-y1)/(x2-x1)
     cal_Teg = (m*(lEg-x1))+y1
  endif

  cal_Teg = 10.0_dp**(cal_Teg)

end function cal_Teg
!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function CAL_TEG_SLOW
!
!> Computes the temperature of a black body which would
!! provide the same energy as Eg inside a given group igrp.
!! Slow version of cal_Teg but needed when increment in
!! radiative energy is not constant.
!<
function cal_Teg_slow(Eg,igrp)

  use amr_parameters      , only : dp
  use fld_parameters, only : inverse_art4_T,Ninv_art4,ngrp

  implicit none

  real(dp), intent(in) :: Eg
  integer , intent(in) :: igrp
  integer              :: i
  real(dp)             :: cal_Teg_slow,m,x1,x2,y1,y2
  logical              :: q

  q            = .true.
  cal_Teg_slow =  inverse_art4_T(ngrp+1,1)
  m            =  0.0_dp

  i = 1

!!$  write(*,*) 'Teg_slow: Eg',Eg,cal_Teg_slow
!!$  write(*,*) 'inv',inverse_art4_T(igrp,i)

  ! search through grid and locate temp
  do while(q)
     if((Eg < inverse_art4_T(igrp,i)).or.(i == Ninv_art4))then
        q = .false.
     elseif(Eg == inverse_art4_T(igrp,i)) then
        cal_Teg_slow = inverse_art4_T(ngrp+1,i)
        q = .false.
     else
        if(Eg < inverse_art4_T(igrp,i+1)) then
!!$           write(*,*) 'Teg_slow: i,cal_Teg_slow',i,igrp
!!$           write(*,*) 'cal_Teg_slow',cal_Teg_slow
!!$           write(*,*) 'Eg',Eg
!!$           write(*,*) 'inverse',inverse_art4_T(igrp,i)
           ! first order linear interpolation
           x1 = inverse_art4_T(igrp  ,i  )
           x2 = inverse_art4_T(igrp  ,i+1)
           y1 = inverse_art4_T(ngrp+1,i  )
           y2 = inverse_art4_T(ngrp+1,i+1)
           ! compute gradient
           m = (y2-y1)/(x2-x1)
           cal_Teg_slow = (m*(Eg-x1))+y1
           q = .false.
           !write(*,*) 'Teg_slow: i,cal_Teg_slow',i,cal_Teg_slow,Eg,inverse_art4_T(igrp,i)
        else
           i = i + 1
        endif
     endif
     !write(*,*) 'Teg_slow: i,cal_Teg_slow',i,cal_Teg_slow,Eg,inverse_art4_T(igrp,i)
  enddo

  !write(*,*) 'Teg_slow: i,cal_Teg_slow',i,cal_Teg_slow,Eg,inverse_art4_T(igrp,i)

end function cal_Teg_slow

!###########################################################
!###########################################################
!###########################################################
!###########################################################

!  Function DIV_BPLANCK
!
!> Computes the derivative of the Planck Black Body
!! distribution function.
!<
function Div_BPlanck(nu,T)
  use amr_parameters, only : dp
  use coeff_xi,       only : limhigh
  use const
  use constants, only:hplanck,kB

  implicit none

  real(dp), intent(in) :: nu,T
  real(dp)             :: Div_BPlanck,x,BPlanck,y,ee

  x = hplanck*nu/(kb*T)
  if(x > limhigh)then
     Div_BPlanck = BPlanck(nu,T) * (x/T)
  else
     ee = exp(x)
     y = ee / (ee - one)
     Div_BPlanck = BPlanck(nu,T) * (x/T) * y
  endif

end function Div_BPlanck