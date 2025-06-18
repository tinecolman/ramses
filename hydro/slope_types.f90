module slope_types
   use amr_parameters, only:dp
   use const
   implicit none

   interface
      pure function slope_func(dlft, drgt,ngrid) result(slope)
         use amr_parameters, only:dp,nvector
         implicit none
         real(dp),dimension(1:nvector),intent(in)::dlft,drgt
         real(dp),dimension(1:nvector)::slope
         integer,intent(in)::ngrid
      end function slope_func
   end interface

contains

   !#######################################################
   pure function slope_minmod(dlft,drgt,ngrid) result(slope)
      real(dp),dimension(1:nvector),intent(in)::dlft,drgt
      real(dp),dimension(1:nvector)::slope
      integer,intent(in)::ngrid
      ! slope_type==1
      integer::l
 
      do l = 1, ngrid
         if((dlft(l)*drgt(l))<=zero) then
            slope(l) = zero
         else if(dlft(l)>0) then
            slope(l) = min(dlft(l),drgt(l))
         else
            slope(l) = max(dlft(l),drgt(l))
         end if
      end do
 
   end function slope_minmod
   !#######################################################
   pure function slope_moncen(dlft,drgt,ngrid) result(slope)
      real(dp),dimension(1:nvector),intent(in)::dlft,drgt
      real(dp),dimension(1:nvector)::slope
      integer,intent(in)::ngrid
      ! slope_type==2
      integer::l
      real(dp)::dcen,dsgn,dlim

      do l = 1, ngrid
         dcen = half*(dlft(l)+drgt(l))
         dsgn = sign(one, dcen)
         dlim = 2*min(abs(dlft(l)),abs(drgt(l)))
         if((dlft(l)*drgt(l))<=zero)dlim=zero
         slope(l) = dsgn*min(dlim,abs(dcen))
      end do
   
   end function slope_moncen
   !#######################################################
   pure function slope_vanLeer(dlft,drgt,ngrid) result(slope)
      real(dp),dimension(1:nvector),intent(in)::dlft,drgt
      real(dp),dimension(1:nvector)::slope
      integer,intent(in)::ngrid
      ! slope_type==7
      integer::l

       do l = 1, ngrid
         if((dlft(l)*drgt(l))<=zero) then
            slope(l)=zero
         else
            slope(l)=(2*dlft(l)*drgt(l)/(dlft(l)+drgt(l)))
         end if
      end do
   
   end function slope_vanLeer
   !#######################################################
   pure function slope_vanLeer_bis(dlft,drgt,ngrid) result(slope)
      real(dp),dimension(1:nvector),intent(in)::dlft,drgt
      real(dp),dimension(1:nvector)::slope
      integer,intent(in)::ngrid
      ! generalized moncen/minmod parameterisation (van Leer 1979)
      ! slope_type==8
      integer::l
      real(dp)::dcen,dsgn,dlim
      real(dp),parameter::slope_theta=1.5d0

      do l = 1, ngrid
         dcen = half*(dlft(l)+drgt(l))
         dsgn = sign(one, dcen)
         dlim = min(slope_theta*abs(dlft(l)),slope_theta*abs(drgt(l)))
         if((dlft(l)*drgt(l))<=zero)dlim=zero
         slope(l) = dsgn*min(dlim,abs(dcen))
      end do
   
   end function slope_vanLeer_bis
   !#######################################################

end module slope_types