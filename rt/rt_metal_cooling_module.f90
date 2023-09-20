MODULE rt_metal_cooling_module

! Returns metal cooling values
! Sam Geen, September 2014

! Use lookup table module for speed, mass-loss arrays
use amr_parameters
use hydro_parameters

implicit none

public

CONTAINS

!************************************************************************
! Calculates metal cooling rates using tables that include photon flux
SUBROUTINE rt_metal_cool(Tin,Nin,xin,mu,metal_tot,metal_prime,coeff_chi,XH2)
  ! Taken from the equilibrium cooling_module of RAMSES
  ! Compute cooling enhancement due to metals
  ! Tin          => Temperature in Kelvin, divided by mu
  ! Nin          => Hydrogen number density (H/cc)
  ! Fin          => Photon flux in lowest energy group (erg /cm^2/s)
  !              => Can be calculated as Np_i * c_red * e_group
  ! xin          => Hydrogen ionisation fraction (0->1)
  ! mu           => Average mass per particle in terms of mH
  ! ne           => Electron number density
  ! metal_tot   <=  Metal cooling contribution to de/dt / (nH*ne) [erg s-1 cm-3]
  ! metal_prime <=  d(metal_tot)/dT2 / (nH*ne) [erg s-1 cm-3 K-1]
  real(dp),intent(in)::Tin,Nin,mu,xin
  real(dp)::T1,T2,nH,flux,cool1,cool2,eps,XH2
  real(dp),intent(out)::metal_tot,metal_prime

  real(dp):: coeff_chi

  ! Set a reference temperature to calculate gradient wrt T
  eps = 1d-5 ! A small value
  T1 = Tin*mu
  T2 = Tin*(1+eps)*mu
  if(isnan(Tin)) then
     write(*,*) 'Tin rt_metal_cool', Tin
  endif
  ! Call a function mixing the two cooling functions
  call rt_metal_cool_mashup(T1,Nin,xin,mu,cool1,coeff_chi,XH2)
  call rt_metal_cool_mashup(T2,Nin,xin,mu,cool2,coeff_chi,XH2)
  
  ! Don't cool below 10K to prevent bound errors, but allow heating
  !if ((Tin*mu .gt. 10d0) .or. (cool1 .lt. 0d0)) then
     ! Calculate gradient and output
     metal_tot = cool1
     ! T2 = T*(1+eps), so T2-T == eps*T
     metal_prime = (cool2 - cool1) / (Tin * mu * eps)
     ! NOTE !!!! NEED TO MULTIPLY BY nH*ne AFTER THIS IS OVER!!!!
     ! EXCLAMATION MARK EXCLAMATION MARK
  !else
     ! Prevent runaway cooling below 10K
   !  metal_tot = 0d0
   !  metal_prime = 0d0
  !endif

  if(isnan(metal_tot)) then
     write(*,*) 'metal_tot rt_metal_cool',metal_tot
  endif

  if(isnan(metal_prime)) then
     write(*,*) 'metal_prime rt_metal_cool',metal_prime
  endif

END SUBROUTINE rt_metal_cool

!************************************************************************
! Mixes Patrick Hennebelle's cooling function with Alex Riching's table
! Uses a sigmoid function centred at x=0.1 with a +/-0.05 spread to switch
SUBROUTINE rt_metal_cool_mashup(T,N,x,mu,cool,coeff_chi,XH2)

  ! Taken from the equilibrium cooling_module of RAMSES
  ! Compute cooling enhancement due to metals
  ! T            => Temperature in Kelvin *with mu included*
  ! N            => Hydrogen number density (H/cc)
  ! F            => Photon flux in lowest energy group (erg /cm^2/s)
  !              => Can be calculated as Np_i * c_red * e_group
  ! x            => Hydrogen ionisation fraction (0->1)
  ! ne           => Electron number density
  ! cool         <=  Metal cooling [erg s-1 cm-3]
  ! XH2          => fraction of H2

  real(dp),intent(in)::T,N,x,mu,XH2
  real(dp)::logT,logN,logF,sig,coolph,coolphoto,dummy,drefdt
  real(dp),intent(out)::cool
  real(dp),parameter::scaleup=1d30

  real(dp):: coeff_chi

!!  coeff_chi=1.

  cool = 0d0
  coolph = 0d0
  coolphoto = 0d0

  ! Get equilibrium metal cooling
  if (T < 10035.d0) then
     ! Patrick's low-temperature cooling function
!     call cooling_low(T,N,coolph)
     !note dRefDT and coeff_chi not used here
     call hot_cold_2(T,N,coolph,dRefDT,coeff_chi,XH2)    

     cool = -coolph
  else
     ! HACK - set a_exp to 1d0
     call rt_cmp_metals(T/mu,N,mu,cool,dRefdT,1d0)
     ! Leave this out for now until thinking about it. Thoughts:
     ! 1) The is in CIE, not NEQ (see Sutherland & Dopita, 1993)
     ! 2) This seems to include hydrogen, which we already have in RAMSES-RT
     ! 3) Pretty close agreement > 10^6 with rt_cmp_cooling anyway
     !call hot_cold_2(T,N,coolph,dRefdT)
     !cool = -coolph
  end if
  ! Handle photoionisation in range where it matters (based on Ferland 2003)
  ! Add a threshold in x to make sure neutral gas is actually treated properly
  ! This is because sometimes the multiplier truncates cooling for low values
!change made after Sam's advice : PH - 9/06
!  if ((T .lt. 1d5).and.(x .gt.1d-6)) then
  if ((T .lt. 1d5).and.(T .gt. 5000d0) .and.(x .gt.1d-2) .and. (N .lt. 1.d5) ) then
!  if ((T .lt. 1d5).and.(x .gt.1e-1)) then
     ! Prevent floating point underflows by scaling up
     cool = cool*scaleup
     call cool_ferlandlike(T/mu,N,coolphoto)
     ! If the cooling is above this value just use this anyway
     if (coolphoto*scaleup .gt.cool) then
        cool = cool*(1d0-x) + coolphoto*x*scaleup
     endif
     ! Scale back down again to the physical value
     cool = cool/scaleup
  endif

END SUBROUTINE rt_metal_cool_mashup

SUBROUTINE cool_osterbrock(T,N,cool)
  ! Taken from the equilibrium cooling_module of RAMSES
  ! Compute cooling enhancement due to metals
  ! T            => Temperature in Kelvin *with mu included*
  ! N            => Hydrogen number density (H/cc)
  ! x            => Hydrogen ionisation fraction (0->1)
  ! cool         <=  Metal cooling [erg s-1 cm-3]

  real(dp),intent(in)::T,N
  real(dp),intent(out)::cool
  ! Now set up the hard-coded linear interpolation approximation
  ! DO LOG(T)-LOG(cool) INTERPOLATION FOR BETTER FIT???
  real(dp),parameter::x0=log10(5d3)
  real(dp),parameter::x1=log10(10d3)
  real(dp),parameter::y0=log10(7.5d-25)
  real(dp),parameter::y1=log10(2.6d-24)
  cool = (log10(T) - x0) * (y1-y0) / (x1-x0) + y0
  cool = 10d0**cool ! recast to linear space
  cool = cool*N*N ! N*Ne (fully ionised)

END SUBROUTINE cool_osterbrock

SUBROUTINE cool_ferlandlike(T,N,cool)
  ! Linear fit to Ferland 2003
  ! Similar to Osterbrock may with a floor below 10^3 K (assume no photoequilibrium < 1000 K...)
  ! Modified to meet our neq_chem metal cooling peak in rt_cmp_metals
  ! Compute cooling enhancement due to metals
  ! T            => Temperature in Kelvin *with mu included*
  ! N            => Hydrogen number density (H/cc)
  ! x            => Hydrogen ionisation fraction (0->1)
  ! cool         <=  Metal cooling [erg s-1 cm-3]

  real(dp),intent(in)::T,N
  real(dp),intent(out)::cool
  ! First piece: flat cooling @ 3d-24
  real(dp),parameter::cool0=3d-24
  real(dp),parameter::T0=9000d0
  ! Second piece: linear fit to meet rt_cmp_metals @ 1e5
  real(dp),parameter::cool1=2.2d-22
  real(dp),parameter::T1=1d5
  if (T < T0) then
     cool = cool0
  else
     cool = (log10(T) - log10(T0)) * (log10(cool1)-log10(cool0)) / &
          & (log10(T1)-log10(T0)) + log10(cool0)
     cool = 10d0**cool
  end if
  cool = cool*N*N ! N*Ne (fully ionised)

END SUBROUTINE cool_ferlandlike

! HACK - SHIFTED HERE FROM rt_cooling_module TO PREVENT CIRCULAR IMPORTS
!=========================================================================
subroutine rt_cmp_metals(T2,nH,mu,metal_tot,metal_prime,aexp)
! Taken from the equilibrium cooling_module of RAMSES
! Compute cooling enhancement due to metals
! T2           => Temperature in Kelvin, divided by mu
! nH           => Hydrogen number density (H/cc)
! mu           => Average mass per particle in terms of mH
! metal_tot   <=  Metal cooling contribution to de/dt [erg s-1 cm-3]
! metal_prime <=  d(metal_tot)/dT2 [erg s-1 cm-3 K-1]
!=========================================================================
  implicit none
  real(dp) ::T2,nH,mu,metal_tot,metal_prime,aexp
  ! Cloudy at solar metalicity
  real(dp),dimension(1:91),parameter :: temperature_cc07 = (/ &
       & 3.9684,4.0187,4.0690,4.1194,4.1697,4.2200,4.2703, &
       & 4.3206,4.3709,4.4212,4.4716,4.5219,4.5722,4.6225, &
       & 4.6728,4.7231,4.7734,4.8238,4.8741,4.9244,4.9747, &
       & 5.0250,5.0753,5.1256,5.1760,5.2263,5.2766,5.3269, &
       & 5.3772,5.4275,5.4778,5.5282,5.5785,5.6288,5.6791, &
       & 5.7294,5.7797,5.8300,5.8804,5.9307,5.9810,6.0313, &
       & 6.0816,6.1319,6.1822,6.2326,6.2829,6.3332,6.3835, &
       & 6.4338,6.4841,6.5345,6.5848,6.6351,6.6854,6.7357, &
       & 6.7860,6.8363,6.8867,6.9370,6.9873,7.0376,7.0879, &
       & 7.1382,7.1885,7.2388,7.2892,7.3395,7.3898,7.4401, &
       & 7.4904,7.5407,7.5911,7.6414,7.6917,7.7420,7.7923, &
       & 7.8426,7.8929,7.9433,7.9936,8.0439,8.0942,8.1445, &
       & 8.1948,8.2451,8.2955,8.3458,8.3961,8.4464,8.4967 /)
  ! Cooling from metals only (without the contribution of H and He)
  ! log cooling rate in [erg s-1 cm3]
  ! S. Ploeckinger 06/2015
  real(kind=8),dimension(1:91) :: excess_cooling_cc07 = (/ &
       &  -24.9082, -24.9082, -24.5503, -24.0898, -23.5328, -23.0696, -22.7758, &
       &  -22.6175, -22.5266, -22.4379, -22.3371, -22.2289, -22.1181, -22.0078, &
       &  -21.8992, -21.7937, -21.6921, -21.5961, -21.5089, -21.4343, -21.3765, &
       &  -21.3431, -21.3274, -21.3205, -21.3142, -21.3040, -21.2900, -21.2773, &
       &  -21.2791, -21.3181, -21.4006, -21.5045, -21.6059, -21.6676, -21.6877, &
       &  -21.6934, -21.7089, -21.7307, -21.7511, -21.7618, -21.7572, -21.7532, &
       &  -21.7668, -21.7860, -21.8129, -21.8497, -21.9035, -21.9697, -22.0497, &
       &  -22.1327, -22.2220, -22.3057, -22.3850, -22.4467, -22.4939, -22.5205, &
       &  -22.5358, -22.5391, -22.5408, -22.5408, -22.5475, -22.5589, -22.5813, &
       &  -22.6122, -22.6576, -22.7137, -22.7838, -22.8583, -22.9348, -23.0006, &
       &  -23.0547, -23.0886, -23.1101, -23.1139, -23.1147, -23.1048, -23.1017, &
       &  -23.0928, -23.0969, -23.0968, -23.1105, -23.1191, -23.1388, -23.1517, &
       &  -23.1717, -23.1837, -23.1986, -23.2058, -23.2134, -23.2139, -23.2107 /)
  real(dp),dimension(1:91),parameter :: excess_prime_cc07 = (/           & 
       &   2.0037,  4.7267, 12.2283, 13.5820,  9.8755,  4.8379,  1.8046, &
       &   1.4574,  1.8086,  2.0685,  2.2012,  2.2250,  2.2060,  2.1605, &
       &   2.1121,  2.0335,  1.9254,  1.7861,  1.5357,  1.1784,  0.7628, &
       &   0.1500, -0.1401,  0.1272,  0.3884,  0.2761,  0.1707,  0.2279, &
       &  -0.2417, -1.7802, -3.0381, -2.3511, -0.9864, -0.0989,  0.1854, &
       &  -0.1282, -0.8028, -0.7363, -0.0093,  0.3132,  0.1894, -0.1526, &
       &  -0.3663, -0.3873, -0.3993, -0.6790, -1.0615, -1.4633, -1.5687, &
       &  -1.7183, -1.7313, -1.8324, -1.5909, -1.3199, -0.8634, -0.5542, &
       &  -0.1961, -0.0552,  0.0646, -0.0109, -0.0662, -0.2539, -0.3869, &
       &  -0.6379, -0.8404, -1.1662, -1.3930, -1.6136, -1.5706, -1.4266, &
       &  -1.0460, -0.7244, -0.3006, -0.1300,  0.1491,  0.0972,  0.2463, &
       &   0.0252,  0.1079, -0.1893, -0.1033, -0.3547, -0.2393, -0.4280, &
       &  -0.2735, -0.3670, -0.2033, -0.2261, -0.0821, -0.0754,  0.0634 /)
  real(dp),dimension(1:50),parameter::z_courty=(/                         &
       & 0.00000,0.04912,0.10060,0.15470,0.21140,0.27090,0.33330,0.39880, &
       & 0.46750,0.53960,0.61520,0.69450,0.77780,0.86510,0.95670,1.05300, &
       & 1.15400,1.25900,1.37000,1.48700,1.60900,1.73700,1.87100,2.01300, &
       & 2.16000,2.31600,2.47900,2.64900,2.82900,3.01700,3.21400,3.42100, &
       & 3.63800,3.86600,4.10500,4.35600,4.61900,4.89500,5.18400,5.48800, &
       & 5.80700,6.14100,6.49200,6.85900,7.24600,7.65000,8.07500,8.52100, &
       & 8.98900,9.50000 /)
  real(dp),dimension(1:50),parameter::phi_courty=(/                             &
       & 0.0499886,0.0582622,0.0678333,0.0788739,0.0915889,0.1061913,0.1229119, &
       & 0.1419961,0.1637082,0.1883230,0.2161014,0.2473183,0.2822266,0.3210551, &
       & 0.3639784,0.4111301,0.4623273,0.5172858,0.5752659,0.6351540,0.6950232, &
       & 0.7529284,0.8063160,0.8520859,0.8920522,0.9305764,0.9682031,1.0058810, &
       & 1.0444020,1.0848160,1.1282190,1.1745120,1.2226670,1.2723200,1.3231350, &
       & 1.3743020,1.4247480,1.4730590,1.5174060,1.5552610,1.5833640,1.5976390, &
       & 1.5925270,1.5613110,1.4949610,1.3813710,1.2041510,0.9403100,0.5555344, & 
       & 0.0000000 /)
  real(dp)::TT,lTT,deltaT,lcool,lcool1,lcool2,lcool1_prime,lcool2_prime
  real(dp)::ZZ,deltaZ
  real(dp)::c1=0.4,c2=10.0,TT0=1d5,TTC=1d6,alpha1=0.15
  real(dp)::ux,g_courty,f_courty=1d0,g_courty_prime,f_courty_prime
  integer::iT,iZ
!-------------------------------------------------------------------------
  ZZ=1d0/aexp-1d0
  TT=T2*mu
  lTT=log10(TT)
  ! This is a simple model to take into account the ionization background
  ! on metal cooling (calibrated using CLOUDY). 
  iZ=1+int(ZZ/z_courty(50)*49.)
  iZ=min(iZ,49)
  iZ=max(iZ,1)
  deltaZ=z_courty(iZ+1)-z_courty(iZ)
  ZZ=min(ZZ,z_courty(50))
  ux=1d-4*(phi_courty(iZ+1)*(ZZ-z_courty(iZ))/deltaZ & 
       & + phi_courty(iZ)*(z_courty(iZ+1)-ZZ)/deltaZ )/nH
  g_courty=c1*(TT/TT0)**alpha1+c2*exp(-TTC/TT)
  g_courty_prime=(c1*alpha1*(TT/TT0)**alpha1+c2*exp(-TTC/TT)*TTC/TT)/TT
  f_courty=1d0/(1d0+ux/g_courty)
  f_courty_prime=ux/g_courty/(1d0+ux/g_courty)**2*g_courty_prime/g_courty

  if(lTT.ge.temperature_cc07(91))then
     metal_tot=0d0 !1d-100
     metal_prime=0d0
  else if(lTT.ge.1.0)then
     lcool1=-100d0
     lcool1_prime=0d0
      if(lTT.ge.temperature_cc07(1))then
        iT=1+int((lTT-temperature_cc07(1)) /                             &
             (temperature_cc07(91)-temperature_cc07(1))*90.0)
        iT=min(iT,90)
        iT=max(iT,1)
        deltaT = temperature_cc07(iT+1) - temperature_cc07(iT)
        lcool1 = &
             excess_cooling_cc07(iT+1)*(lTT-temperature_cc07(iT))/deltaT &
           + excess_cooling_cc07(iT)*(temperature_cc07(iT+1)-lTT)/deltaT 
        lcool1_prime  =                                                  &
             excess_prime_cc07(iT+1)*(lTT-temperature_cc07(iT))/deltaT   &
           + excess_prime_cc07(iT)*(temperature_cc07(iT+1)-lTT)/deltaT 
     endif
     ! Fine structure cooling from infrared lines
     lcool2=-31.522879+2.0*lTT-20.0/TT-TT*4.342944d-5
     lcool2_prime=2d0+(20d0/TT-TT*4.342944d-5)*log(10d0)
     ! Total metal cooling and temperature derivative
     metal_tot=10d0**lcool1+10d0**lcool2
     metal_prime=(10d0**lcool1*lcool1_prime+10d0**lcool2*lcool2_prime)/metal_tot
     metal_prime=metal_prime*f_courty+metal_tot*f_courty_prime
     metal_tot=metal_tot*f_courty
  else
     metal_tot=0d0 !1d-100
     metal_prime=0d0
  endif

  metal_tot=metal_tot*nH**2
  metal_prime=           &   ! Convert from DlogLambda/DlogT to DLambda/DT
       metal_prime * metal_tot/TT * mu

end subroutine rt_cmp_metals

END MODULE
