! by Jacques Masson, Benoit Commercon and Neil Vaytet
! refactored by Tine Colman

!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine compute_bemf(u,q,ngrid,bemfx,bemfy,bemfz)
   USE amr_parameters
   use hydro_commons
   implicit none
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar+3),intent(in)::u
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar),intent(in)::q
   integer,intent(in)::ngrid
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(out)::bemfx,bemfy,bemfz
   !-------------------------------------------
   ! Interpolates the magnetic field at location of EMF
   !-------------------------------------------
   integer ::i, j, k, l

   bemfx=0d0
   bemfy=0d0
   bemfz=0d0

   !!!!!!!!!!!!!!!!!!
   ! EMF x
   !!!!!!!!!!!!!!!!!!

   do k=min(1,ku1+1),ku2
      do j=min(1,ju1+1),ju2
         do i=iu1,iu2
            do l=1,ngrid
               bemfx(l,i,j,k,1)=0.25d0*( q(l,i,j,k,6)+q(l,i,j-1,k,6)+q(l,i,j,k-1,6)+q(l,i,j-1,k-1,6) )
            end do
         end do
      end do
   end do

   do k=min(1,ku1+1),ku2
      do j=ju1,ju2
         do i=iu1,iu2
            do l=1,ngrid
               bemfx(l,i,j,k,2)=0.5d0*( u(l,i,j,k,7)+u(l,i,j,k-1,7) )
            end do
         end do
      end do
   end do

   do k=ku1,ku2
      do j=min(1,ju1+1),ju2
         do i=iu1,iu2
            do l=1,ngrid
               bemfx(l,i,j,k,3)=0.5d0*(u(l,i,j,k,8)+u(l,i,j-1,k,8))
            end do
         end do
      end do
   end do

   !!!!!!!!!!!!!!!!!!
   ! EMF y
   !!!!!!!!!!!!!!!!!!

   do k=min(1,ku1+1),ku2
      do j=ju1,ju2
         do i=iu1,iu2
            do l=1,ngrid
               bemfy(l,i,j,k,1)=0.5d0*(u(l,i,j,k,6)+u(l,i,j,k-1,6))
            end do
         end do
      end do
   end do

   do k=min(1,ku1+1),ku2
      do j=ju1,ju2
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               bemfy(l,i,j,k,2)=0.25d0*(q(l,i,j,k,7)+q(l,i-1,j,k,7)+q(l,i,j,k-1,7)+q(l,i-1,j,k-1,7))
            end do
         end do
      end do
   end do

   do k=ku1,ku2
      do j=ju1,ju2
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               bemfy(l,i,j,k,3)=0.5d0*(u(l,i-1,j,k,8)+u(l,i,j,k,8))
            end do
         end do
      end do
   end do

   !!!!!!!!!!!!!!!!!!
   ! EMF z
   !!!!!!!!!!!!!!!!!!

   do k=ku1,ku2
      do j=min(1,ju1+1),ju2
         do i=iu1,iu2
            do l=1,ngrid
               bemfz(l,i,j,k,1)=0.5d0*(u(l,i,j,k,6)+u(l,i,j-1,k,6))
            end do
         end do
      end do
   end do

   do k=ku1,ku2
      do j=ju1,ju2
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               bemfz(l,i,j,k,2)=0.5d0*(u(l,i,j,k,7)+u(l,i-1,j,k,7))
            end do
         end do
      end do
   end do

   do k=ku1,ku2
      do j=min(1,ju1+1),ju2
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               bemfz(l,i,j,k,3)=0.25d0*(q(l,i,j,k,8)+q(l,i-1,j,k,8)+q(l,i,j-1,k,8)+q(l,i-1,j-1,k,8))
            end do
         end do
      end do
   end do

end subroutine compute_bemf
!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine compute_bmagij(u,q,ngrid,bmagij)
   USE amr_parameters
   use hydro_commons
   implicit none
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar+3),intent(in)::u
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar),intent(in)::q
   integer,intent(in)::ngrid
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3,1:3),intent(out)::bmagij
   !-----------------------------------------------------------------
   ! Compute the value of the magnetic field Bi where Bj is naturally defined;
   ! For example, bmagij(l,i,j,k,1,2) is Bx at i,j-1/2,k
   ! and we can name it Bx,y
   !-----------------------------------------------------------------
   integer ::i, j, k, l, m

   bmagij=0d0

   ! Diagonal: Bx x, By y, Bz z
   do k=ku1,ku2
      do j=ju1,ju2
         do i=iu1,iu2
            do l=1,ngrid
               bmagij(l,i,j,k,1,1)=u(l,i,j,k,6)
               bmagij(l,i,j,k,2,2)=u(l,i,j,k,7)
               bmagij(l,i,j,k,3,3)=u(l,i,j,k,8)
            end do
         end do
      end do
   end do

   ! case Bx,y
   do k=ku1,ku2
      do j=min(1,ju1+1),ju2
         do i=iu1,max(1,iu2-1)
            do l=1,ngrid
               bmagij(l,i,j,k,1,2)=0.5d0*(q(l,i,j,k,6)+q(l,i,j-1,k,6))
            end do
         end do
      end do
   end do

   ! case Bx,z
   do k=min(1,ku1+1),ku2
      do j=ju1,ju2
         do i=iu1,max(1,iu2-1)
            do l=1,ngrid
               bmagij(l,i,j,k,1,3)=0.5d0*(q(l,i,j,k,6)+q(l,i,j,k-1,6))
            end do
         end do
      end do
   end do

   ! case By,x
   do k=ku1,ku2
      do j=ju1,max(1,ju2-1)
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               bmagij(l,i,j,k,2,1)=0.5d0*(q(l,i,j,k,7)+q(l,i-1,j,k,7))
            end do
         end do
      end do
   end do

   ! case By,z
   do k=min(1,ku1+1),ku2
      do j=ju1,max(1,ju2-1)
         do i=iu1,iu2
            do l=1,ngrid
               bmagij(l,i,j,k,2,3)=0.5d0*(q(l,i,j,k,7)+q(l,i,j,k-1,7))
            end do
         end do
      end do
   end do

   ! case Bz,x
   do k=ku1,max(1,ku2-1)
      do j=ju1,ju2
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               bmagij(l,i,j,k,3,1)=0.5d0*(q(l,i,j,k,8)+q(l,i-1,j,k,8))
            end do
         end do
      end do
   end do

   ! case Bz,y
   do k=ku1,max(1,ku2-1)
      do j=min(1,ju1+1),ju2
         do i=iu1,iu2
            do l=1,ngrid
               bmagij(l,i,j,k,3,2)=0.5d0*(q(l,i,j,k,8)+q(l,i,j-1,k,8))
            end do
         end do
      end do
   end do

end subroutine compute_bmagij
!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine compute_bmagijbis(u,ngrid,bmagijbis)
   use amr_parameters
   use hydro_commons
   implicit none
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar+3),intent(in)::u
   integer,intent(in)::ngrid
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(out)::bmagijbis
   !-----------------------------------------------------------------
   ! Compute the value of the magnetic field component at i-1/2,j-1/2,k-1/2
   ! Used by compute_jemf
   ! Only fills the values that are actually used by compute_jemf
   !-----------------------------------------------------------------
   integer ::i, j, k, l

   bmagijbis=0d0

   ! case Bx for Lorentz force EMF
   do k=min(1,ku1+1),ku2
      do j=min(1,ju1+1),ju2
         do i=min(1,iu1+1),max(1,iu2-1)
            do l=1,ngrid
               bmagijbis(l,i,j,k,1)=0.25d0*(u(l,i,j,k,6)+u(l,i,j-1,k,6)+u(l,i,j,k-1,6)+u(l,i,j-1,k-1,6))
            end do
         end do
      end do
   end do

   ! case By for Lorentz force EMF
   do k=min(1,ku1+1),ku2
      do j=min(1,ju1+1),max(1,ju2-1)
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               bmagijbis(l,i,j,k,2)=0.25d0*(u(l,i,j,k,7)+u(l,i-1,j,k,7)+u(l,i,j,k-1,7)+u(l,i-1,j,k-1,7))
            end do
         end do
      end do
   end do

   ! case Bz for Lorentz force EMF
   do k=min(1,ku1+1),max(1,ku2-1)
      do j=min(1,ju1+1),ju2
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               bmagijbis(l,i,j,k,3)=0.25d0*(u(l,i,j,k,8)+u(l,i-1,j,k,8)+u(l,i,j-1,k,8)+u(l,i-1,j-1,k,8))
            end do
         end do
      end do
   end do

end subroutine compute_bmagijbis
!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine compute_jemf(u,ngrid,dx,dy,dz,bmagij,jemfx,jemfy,jemfz)
   use amr_parameters
   use hydro_commons
   use nimhd_parameters
   implicit none
   ! inputs
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar+3),intent(in)::u
   integer,intent(in)::ngrid
   real(dp),intent(in)::dx,dy,dz
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3,1:3),intent(in)::bmagij
   ! outputs
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(out)::jemfx,jemfy,jemfz
   !-----------------------------------------------------------------
   ! Computes the current density J at the EMF edges
   ! jemfx(l,i,j,k,n) is the component Jn at i,j-1/2,k-1/2
   !-----------------------------------------------------------------
   integer ::i, j, k, l, m, n
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::bmagijbis
   real(dp):: oneoverdx

   ! We optimize by calculating the division only once,
   ! and using the fact that dx=dy=dz in RAMSES
   oneoverdx = 1d0/dx

   jemfx=0d0
   jemfy=0d0
   jemfz=0d0

   call compute_bmagijbis(u,ngrid,bmagijbis)

   do k=min(1,ku1+1),max(1,ku2-1)
      do j=min(1,ju1+1),max(1,ju2-1)
         do i=min(1,iu1+1),max(1,iu2-1)
            do l=1,ngrid
               jemfx(l,i,j,k,1) = ((u(l,i,j,k,8)-u(l,i,j-1,k,8))                 - (u(l,i,j,k,7)-u(l,i,j,k-1,7))                ) * oneoverdx
               jemfx(l,i,j,k,2) = ((bmagij(l,i,j,k,1,2)-bmagij(l,i,j,k-1,1,2))   - (bmagijbis(l,i+1,j,k,3)-bmagijbis(l,i,j,k,3))) * oneoverdx
               jemfx(l,i,j,k,3) = ((bmagijbis(l,i+1,j,k,2)-bmagijbis(l,i,j,k,2)) - (bmagij(l,i,j,k,1,3)-bmagij(l,i,j-1,k,1,3))  ) * oneoverdx

               jemfy(l,i,j,k,1) = ((bmagijbis(l,i,j+1,k,3)-bmagijbis(l,i,j,k,3)) - (bmagij(l,i,j,k,2,1) - bmagij(l,i,j,k-1,2,1) )) * oneoverdx
               jemfy(l,i,j,k,2) = ((u(l,i,j,k,6)-u(l,i,j,k-1,6))                 - (u(l,i,j,k,8)-u(l,i-1,j,k,8))                 ) * oneoverdx
               jemfy(l,i,j,k,3) = ((bmagij(l,i,j,k,2,3)-bmagij(l,i-1,j,k,2,3))   - (bmagijbis(l,i,j+1,k,1)-bmagijbis(l,i,j,k,1)) ) * oneoverdx

               jemfz(l,i,j,k,1) = ((bmagij(l,i,j,k,3,1) -bmagij(l,i,j-1,k,3,1))  - (bmagijbis(l,i,j,k+1,2)-bmagijbis(l,i,j,k,2)) ) * oneoverdx
               jemfz(l,i,j,k,2) = ((bmagijbis(l,i,j,k+1,1)-bmagijbis(l,i,j,k,1)) - (bmagij(l,i,j,k,3,2)-bmagij(l,i-1,j,k,3,2))   ) * oneoverdx
               jemfz(l,i,j,k,3) = ((u(l,i,j,k,7)-u(l,i-1,j,k,7))                 - (u(l,i,j,k,6)-u(l,i,j-1,k,6))                 ) * oneoverdx
            end do
         end do
      end do
   end do

end subroutine compute_jemf
!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine computejb2(u,q,ngrid,dx,dy,dz,dt,bemfx,bemfy,bemfz,bmagij,fluxmd,fluxad)

   USE amr_parameters
   use hydro_commons
   use nimhd_parameters
   IMPLICIT NONE

   ! inputs
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar+3)::u 
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar)::q 
   INTEGER ::ngrid
   REAL(dp)::dx,dy,dz,dt

   ! outputs
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::bemfx,bemfy,bemfz
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3,1:3)::bmagij
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::fluxmd,fluxad

   ! declare local variables
   INTEGER ::i, j, k, l, m
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::bmagijbis
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3,1:3)::jface
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::bcenter
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3,1:3)::fluxbis,fluxter,fluxquat
   real(dp)::bsquare
   real(dp)::computdxbis,computdybis,computdzbis

   fluxmd=0d0
   fluxad=0d0

   ! magnetic field at center of cells
   do k=ku1,ku2
      do j=ju1,ju2
         do i=iu1,iu2
            do l=1,ngrid
               bcenter(l,i,j,k,1)=q(l,i,j,k,6)
               bcenter(l,i,j,k,2)=q(l,i,j,k,7)
               bcenter(l,i,j,k,3)=q(l,i,j,k,8)
            end do
         end do
      end do
   end do

   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   ! computation of the component of j at center of cell
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


   ! computation of current on faces

   ! face at i-1/2,j,k

   do k=min(1,ku1+1),max(1,ku2-1)
      do j=min(1,ju1+1),max(1,ju2-1)           
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               jface(l,i,j,k,1,1)=computdybis(bemfz,3,l,i,j,k,dy)-computdzbis(bemfy,2,l,i,j,k,dz)
            end do
         end do
      end do
   end do

   do k=min(1,ku1+1),max(1,ku2-1)
      do j=ju1,ju2       
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               jface(l,i,j,k,2,1)=computdzbis(bemfy,1,l,i,j,k,dz)-computdxbis(bcenter,3,l,i-1,j,k,dx)
            end do
         end do
      end do
   end do
  
   do k=ku1,ku2
      do j=min(1,ju1+1),max(1,ju2-1)       
         do i=min(1,iu1+1),iu2
            do l=1,ngrid
               jface(l,i,j,k,3,1)=computdxbis(bcenter,2,l,i-1,j,k,dx)-computdybis(bemfz,1,l,i,j,k,dy)
            end do
         end do
      end do
   end do
  
   ! face at i,j-1/2,k

   do k=min(1,ku1+1),max(1,ku2-1) 
      do j=min(1,ju1+1),ju2       
         do i=iu1,iu2
            do l=1,ngrid
               jface(l,i,j,k,1,2)=computdybis(bcenter,3,l,i,j-1,k,dy)-computdzbis(bemfx,2,l,i,j,k,dz)
            end do
         end do
      end do
   end do

   do k=min(1,ku1+1),max(1,ku2-1) 
      do j=min(1,ju1+1),ju2       
         do i=min(1,iu1+1),max(1,iu2-1) 
            do l=1,ngrid
               jface(l,i,j,k,2,2)=computdzbis(bemfx,1,l,i,j,k,dz)-computdxbis(bemfz,3,l,i,j,k,dx)
            end do
         end do
      end do
   end do
  
   do k=ku1,ku2
      do j=min(1,ju1+1),ju2       
         do i=min(1,iu1+1),max(1,iu2-1) 
            do l=1,ngrid
               jface(l,i,j,k,3,2)=computdxbis(bemfz,2,l,i,j,k,dx)-computdybis(bcenter,1,l,i,j-1,k,dy)
            end do
         end do
      end do
   end do

   ! face at i,j,k-1/2
  
   do k=min(1,ku1+1),ku2
      do j=min(1,ju1+1),max(1,ju2-1)        
         do i=iu1,iu2
            do l=1,ngrid
               jface(l,i,j,k,1,3)=computdybis(bemfx,3,l,i,j,k,dy)-computdzbis(bcenter,2,l,i,j,k-1,dz)             
            end do
         end do
      end do
   end do

   do k=min(1,ku1+1),ku2
      do j=ju1,ju2       
         do i=min(1,iu1+1),max(1,iu2-1)
            do l=1,ngrid
               jface(l,i,j,k,2,3)=computdzbis(bcenter,1,l,i,j,k-1,dz)-computdxbis(bemfy,3,l,i,j,k,dx)             
            end do
         end do
      end do
   end do
  
   do k=min(1,ku1+1),ku2
      do j=min(1,ju1+1),max(1,ju2-1)      
         do i=min(1,iu1+1),max(1,iu2-1)
            do l=1,ngrid
               jface(l,i,j,k,3,3)=computdxbis(bemfy,2,l,i,j,k,dx)-computdybis(bemfx,1,l,i,j,k,dx)            
            end do
         end do
      end do
   end do


   do k=min(1,ku1+1),max(1,ku2-1)
      do j=min(1,ju1+1),max(1,ju2-1)
         do i=min(1,iu1+1),max(1,iu2-1)
            do l = 1, ngrid
               call crossprodbis(jface,bmagij,fluxbis,l,i,j,k)
               fluxmd(l,i,j,k,1)=fluxbis(l,i,j,k,1,1)
               fluxmd(l,i,j,k,2)=fluxbis(l,i,j,k,2,2)
               fluxmd(l,i,j,k,3)=fluxbis(l,i,j,k,3,3)
            end do
         end do
      end do
   end do

   if(nambipolar) then
      do k=min(1,ku1+1),max(1,ku2-1)
         do j=min(1,ju1+1),max(1,ju2-1)
            do i=min(1,iu1+1),max(1,iu2-1)
               do l = 1, ngrid
                  call crossprodbis(fluxbis,bmagij,fluxter,l,i,j,k)
                  call crossprodbis(fluxter,bmagij,fluxquat,l,i,j,k)
                  fluxad(l,i,j,k,1)=fluxquat(l,i,j,k,1,1)
                  fluxad(l,i,j,k,2)=fluxquat(l,i,j,k,2,2)
                  fluxad(l,i,j,k,3)=fluxquat(l,i,j,k,3,3)
               end do
            end do
         end do
      end do
   endif

end subroutine computejb2
!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine computdifmag(u,ngrid,dx,dt,bemfx,bemfy,bemfz,jemfx,jemfy,jemfz,emfohmdiss)
   use amr_parameters
   use hydro_commons
   use nimhd_parameters
   implicit none
   integer,intent(in)::ngrid
   real(dp),intent(in)::dx,dt
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar+3),intent(in)::u
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(in)::jemfx,jemfy,jemfz
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(in)::bemfx,bemfy,bemfz
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(out)::emfohmdiss
   !-----------------------------------------------------------------
   ! Computes the Ohmic contribution to the EMF,
   !   emfohmdiss = -eta * J   (from dB/dt = -curl(eta*J)),
   ! evaluated at the EMF edges.
   !-----------------------------------------------------------------
   integer ::i,j,k,l,h
   real(dp),dimension(1:nvector,1:3)::etaohm
   real(dp),dimension(1:nvector)::B2x,B2y,B2z
   emfohmdiss = 0d0

   do k=min(1,ku1+1),max(1,ku2-1)
      do j=min(1,ju1+1),max(1,ju2-1)
         do i=min(1,iu1+1),max(1,iu2-1)

            do l=1,ngrid
               B2x(l)=bemfx(l,i,j,k,1)**2+bemfx(l,i,j,k,2)**2+bemfx(l,i,j,k,3)**2
               B2y(l)=bemfy(l,i,j,k,1)**2+bemfy(l,i,j,k,2)**2+bemfy(l,i,j,k,3)**2
               B2z(l)=bemfz(l,i,j,k,1)**2+bemfz(l,i,j,k,2)**2+bemfz(l,i,j,k,3)**2
            end do

            call resistivities_etaohm(u,B2x,B2y,B2z,ngrid,i,j,k,dt,dx,etaohm,1,.true.)

            do l=1,ngrid
               ! WARNING dB/dt=-curl(eta*J)
               emfohmdiss(l,i,j,k,1)=-etaohm(l,1)*jemfx(l,i,j,k,1)
               emfohmdiss(l,i,j,k,2)=-etaohm(l,2)*jemfy(l,i,j,k,2)
               emfohmdiss(l,i,j,k,3)=-etaohm(l,3)*jemfz(l,i,j,k,3)
            end do
         end do
      end do
   end do

end subroutine computdifmag
!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine compute_heating_difmag(u,ngrid,bmagij,fluxmd,fluxohm)
   use amr_parameters
   use hydro_commons
   use nimhd_parameters
   implicit none
   integer,intent(in)::ngrid
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar+3),intent(in)::u
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(in)::fluxmd
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3,1:3),intent(in)::bmagij
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(out)::fluxohm
   !-----------------------------------------------------------------
   ! Compute the Ohmic energy flux (fluxohm = eta * fluxmd) on the faces.
   ! Expects fluxmd from computejb2.
   !-----------------------------------------------------------------
   integer ::i,j,k,l,h
   real(dp),dimension(1:nvector,1:3)::etaohm
   real(dp),dimension(1:nvector)::B2x,B2y,B2z

   fluxohm = 0d0
   do k=min(1,ku1+1),max(1,ku2-1)
      do j=min(1,ju1+1),max(1,ju2-1)
         do i=min(1,iu1+1),max(1,iu2-1)

            do l=1,ngrid
               B2x(l)=bmagij(l,i,j,k,1,1)**2+bmagij(l,i,j,k,2,1)**2+bmagij(l,i,j,k,3,1)**2
               B2y(l)=bmagij(l,i,j,k,1,2)**2+bmagij(l,i,j,k,2,2)**2+bmagij(l,i,j,k,3,2)**2
               B2z(l)=bmagij(l,i,j,k,1,3)**2+bmagij(l,i,j,k,2,3)**2+bmagij(l,i,j,k,3,3)**2
            end do

            call resistivities_etaohm(u,B2x,B2y,B2z,ngrid,i,j,k,0d0,0d0,etaohm,2,.false.)

            do l=1,ngrid
               fluxohm(l,i,j,k,1)=etaohm(l,1)*fluxmd(l,i,j,k,1)
               fluxohm(l,i,j,k,2)=etaohm(l,2)*fluxmd(l,i,j,k,2)
               fluxohm(l,i,j,k,3)=etaohm(l,3)*fluxmd(l,i,j,k,3)
            enddo
         end do
      end do
   end do

end subroutine compute_heating_difmag
!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine computambip(u,ngrid,dx,dy,dz,dt,bemfx,bemfy,bemfz,jemfx,jemfy,jemfz,bmagij,fluxad,emfambdiff,fluxambdiff)

   use amr_commons
   use amr_parameters
   use hydro_commons
   use nimhd_parameters
   implicit none
   ! inputs
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar+3),intent(in)::u
   integer,intent(in)::ngrid
   real(dp),intent(in)::dx,dy,dz,dt
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(in)::bemfx,bemfy,bemfz
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(in)::jemfx,jemfy,jemfz
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3,1:3),intent(in)::bmagij
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(in)::fluxad
   ! output
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3),intent(out)::emfambdiff
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)intent(out)::fluxambdiff
   !-----------------------------------------------------------------
   ! Computes the ambipolar contribution to the EMF from the Lorentz force
   !   F = J x B
   !   emfambdiff = beta * (F x B)   (from dB/dt = curl(beta*(JxB)xB)),
   !   beta = 1/(gammaAD*rho).
   ! evaluated at the EMF edges.
   !-----------------------------------------------------------------
   integer ::i, j, k, l
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::florentzx,florentzy,florentzz
   real(dp)::v1x,v1y,v1z,v2x,v2y,v2z
   real(dp)::rhox,rhoy,rhoz,rhofx,rhofy,rhofz
   real(dp)::bsquarex,bsquarey,bsquarez,bsquare
   real(dp)::bsquarexx,bsquareyy,bsquarezz
   real(dp)::betaad2,betaad
   real(dp)::rhocell,bcell,tcell
   real(dp)::crossprodx,crossprody,crossprodz

   emfambdiff=0d0
   fluxambdiff=0d0

   florentzx=0d0
   florentzy=0d0
   florentzz=0d0

   ! compute Loretz force
   do k=min(1,ku1+1),max(1,ku2-1)
      do j=min(1,ju1+1),max(1,ju2-1)
         do i=min(1,iu1+1),max(1,iu2-1)
            do l = 1, ngrid
               call crossprod(jemfx,bemfx,florentzx,l,i,j,k)
               call crossprod(jemfy,bemfy,florentzy,l,i,j,k)
               call crossprod(jemfz,bemfz,florentzz,l,i,j,k)
            end do
         end do
      end do
   end do


   !dtlim=dt!*frac_dt_cap_ad
   !dt est deja dtnew, qui a été choisi comme le dt normal (avec la condition de courant) ou le dt normal seuillé si le dtAD est trop faible(bricolo)

   do k=min(1,ku1+1),max(1,ku2-1)
      do j=min(1,ju1+1),max(1,ju2-1)
         do i=min(1,iu1+1),max(1,iu2-1)

            do l = 1, ngrid

               rhox=0.25d0*(u(l,i,j,k,1)+u(l,i,j-1,k,1)+u(l,i,j,k-1,1)+u(l,i,j-1,k-1,1))
               rhoy=0.25d0*(u(l,i,j,k,1)+u(l,i-1,j,k,1)+u(l,i,j,k-1,1)+u(l,i-1,j,k-1,1))
               rhoz=0.25d0*(u(l,i,j,k,1)+u(l,i-1,j,k,1)+u(l,i,j-1,k,1)+u(l,i-1,j-1,k,1))

               rhofx=0.5d0*(u(l,i,j,k,1)+u(l,i-1,j,k,1))
               rhofy=0.5d0*(u(l,i,j,k,1)+u(l,i,j-1,k,1))
               rhofz=0.5d0*(u(l,i,j,k,1)+u(l,i,j,k-1,1))

               rhocell = min(rhox,rhoy,rhoz,rhofx,rhofy,rhofz)

               ! Compute gas temperature in cgs

               call temperature_eos(u(l,i,j,k,1), 0d0, tcell)
               
               bsquarex=bemfx(l,i,j,k,1)**2+bemfx(l,i,j,k,2)**2+bemfx(l,i,j,k,3)**2
               bsquarey=bemfy(l,i,j,k,1)**2+bemfy(l,i,j,k,2)**2+bemfy(l,i,j,k,3)**2
               bsquarez=bemfz(l,i,j,k,1)**2+bemfz(l,i,j,k,2)**2+bemfz(l,i,j,k,3)**2

               bsquarexx=bmagij(l,i,j,k,1,1)**2+bmagij(l,i,j,k,2,1)**2+bmagij(l,i,j,k,3,1)**2
               bsquareyy=bmagij(l,i,j,k,1,2)**2+bmagij(l,i,j,k,2,2)**2+bmagij(l,i,j,k,3,2)**2
               bsquarezz=bmagij(l,i,j,k,1,3)**2+bmagij(l,i,j,k,2,3)**2+bmagij(l,i,j,k,3,3)**2

               bcell = max(bsquarex,bsquarey,bsquarez,bsquarexx,bsquareyy,bsquarezz)

               ! EMF x

               v1x=florentzx(l,i,j,k,1)
               v1y=florentzx(l,i,j,k,2)
               v1z=florentzx(l,i,j,k,3)
               v2x=bemfx(l,i,j,k,1)
               v2y=bemfx(l,i,j,k,2)
               v2z=bemfx(l,i,j,k,3)
               emfambdiff(l,i,j,k,1)=crossprodx(v1x,v1y,v1z,v2x,v2y,v2z)

               rhox=0.25d0*(u(l,i,j,k,1)+u(l,i,j-1,k,1)+u(l,i,j,k-1,1)+u(l,i,j-1,k-1,1))
               betaad2=betaad(rhocell,rhox,dt,bcell,bcell,dx,tcell,.true.)
               emfambdiff(l,i,j,k,1)=emfambdiff(l,i,j,k,1)*betaad2 

               ! EMF y

               v1x=florentzy(l,i,j,k,1)
               v1y=florentzy(l,i,j,k,2)
               v1z=florentzy(l,i,j,k,3)
               v2x=bemfy(l,i,j,k,1)
               v2y=bemfy(l,i,j,k,2)
               v2z=bemfy(l,i,j,k,3)
               emfambdiff(l,i,j,k,2)=crossprody(v1x,v1y,v1z,v2x,v2y,v2z)

               rhoy=0.25d0*(u(l,i,j,k,1)+u(l,i-1,j,k,1)+u(l,i,j,k-1,1)+u(l,i-1,j,k-1,1))
               betaad2=betaad(rhocell,rhoy,dt,bcell,bcell,dx,tcell,.true.)
               emfambdiff(l,i,j,k,2)=emfambdiff(l,i,j,k,2)*betaad2            
                    
               ! EMF z

               v1x=florentzz(l,i,j,k,1)
               v1y=florentzz(l,i,j,k,2)
               v1z=florentzz(l,i,j,k,3)
               v2x=bemfz(l,i,j,k,1)
               v2y=bemfz(l,i,j,k,2)
               v2z=bemfz(l,i,j,k,3)
               emfambdiff(l,i,j,k,3)=crossprodz(v1x,v1y,v1z,v2x,v2y,v2z)

               rhoz=0.25d0*(u(l,i,j,k,1)+u(l,i-1,j,k,1)+u(l,i,j-1,k,1)+u(l,i-1,j-1,k,1))
               betaad2=betaad(rhocell,rhoz,dt,bcell,bcell,dx,tcell,.true.)
               emfambdiff(l,i,j,k,3)=emfambdiff(l,i,j,k,3)*betaad2
               if(nimhdheating_in_flux) then
                  ! energy flux on faces

                  rhofx=0.5d0*(u(l,i,j,k,1)+u(l,i-1,j,k,1))
                  betaad2=betaad(rhocell,rhofx,dt,bcell,bcell,dx,tcell,.true.)
                  fluxambdiff(l,i,j,k,1)=-betaad2*fluxad(l,i,j,k,1)

                  rhofy=0.5d0*(u(l,i,j,k,1)+u(l,i,j-1,k,1))
                  betaad2=betaad(rhocell,rhofy,dt,bcell,bcell,dx,tcell,.true.) !TC:dy?
                  fluxambdiff(l,i,j,k,2)=-betaad2*fluxad(l,i,j,k,2)

                  rhofz=0.5d0*(u(l,i,j,k,1)+u(l,i,j,k-1,1))
                  betaad2=betaad(rhocell,rhofz,dt,bcell,bcell,dx,tcell,.true.) !TC: dz?
                  fluxambdiff(l,i,j,k,3)=-betaad2*fluxad(l,i,j,k,3)
               endif 
            end do
         end do
      end do
   end do

end subroutine computambip
!###########################################################
!###########################################################
!###########################################################
!###########################################################

! VECTOR FUNCTION

!###########################################################
double precision function computdxbis(vec,n2,l,i,j,k,dx)

   use amr_parameters,only:dp,nvector
   use hydro_parameters,only:iu1,iu2,ju1,ju2,ku1,ku2
   implicit none 
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::vec
   real(dp)::dx
   integer::n2,l,i,j,k

   computdxbis = (vec(l,i+1,j,k,n2) - vec(l,i,j,k,n2)) / dx

end function computdxbis

double precision  function computdybis(vec,n2,l,i,j,k,dx)

   use amr_parameters,only:dp,nvector
   use hydro_parameters,only:iu1,iu2,ju1,ju2,ku1,ku2
   implicit none 
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::vec
   real(dp)::dx
   integer::n2,l,i,j,k

   computdybis=(vec(l,i,j+1,k,n2) - vec(l,i,j,k,n2)) / dx

end function computdybis

double precision  function computdzbis(vec,n2,l,i,j,k,dx)

   use amr_parameters,only:dp,nvector
   use hydro_parameters,only:iu1,iu2,ju1,ju2,ku1,ku2
   implicit none
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::vec
   real(dp)::dx
   integer::n2,l,i,j,k

   computdzbis = (vec(l,i,j,k+1,n2) - vec(l,i,j,k,n2)) / dx

end function computdzbis
!###########################################################
subroutine crossprodbis(vec1,vec2,v1crossv2,l,i,j,k)

   use amr_parameters,only:dp,nvector
   use hydro_parameters,only:iu1,iu2,ju1,ju2,ku1,ku2
   implicit none
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3,1:3)::vec1,vec2,v1crossv2
   integer ::l,i,j,k 

   real(dp)::v1x,v1y,v1z,v2x,v2y,v2z,crossprodx,crossprody,crossprodz

   integer::n

   do n=1,3
      v1x=vec1(l,i,j,k,1,n)
      v1y=vec1(l,i,j,k,2,n)
      v1z=vec1(l,i,j,k,3,n)
      
      v2x=vec2(l,i,j,k,1,n)
      v2y=vec2(l,i,j,k,2,n)
      v2z=vec2(l,i,j,k,3,n)
      
      v1crossv2(l,i,j,k,1,n)=crossprodx(v1x,v1y,v1z,v2x,v2y,v2z)
      v1crossv2(l,i,j,k,2,n)=crossprody(v1x,v1y,v1z,v2x,v2y,v2z)
      v1crossv2(l,i,j,k,3,n)=crossprodz(v1x,v1y,v1z,v2x,v2y,v2z)
   end do

end subroutine crossprodbis

subroutine crossprod(vec1,vec2,v1crossv2,l,i,j,k)

   use amr_parameters,only:dp,nvector
   use hydro_parameters,only:iu1,iu2,ju1,ju2,ku1,ku2
   implicit none
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:3)::vec1,vec2,v1crossv2
   integer ::l,i,j,k 

   real(dp)::v1x,v1y,v1z,v2x,v2y,v2z,crossprodx,crossprody,crossprodz

   v1x=vec1(l,i,j,k,1)
   v1y=vec1(l,i,j,k,2)
   v1z=vec1(l,i,j,k,3)

   v2x=vec2(l,i,j,k,1)
   v2y=vec2(l,i,j,k,2)
   v2z=vec2(l,i,j,k,3)

   v1crossv2(l,i,j,k,1)=crossprodx(v1x,v1y,v1z,v2x,v2y,v2z)
   v1crossv2(l,i,j,k,2)=crossprody(v1x,v1y,v1z,v2x,v2y,v2z)
   v1crossv2(l,i,j,k,3)=crossprodz(v1x,v1y,v1z,v2x,v2y,v2z)

end subroutine crossprod
!###########################################################
double precision function  crossprodx(v1x,v1y,v1z,v2x,v2y,v2z)

   ! x component of a cross product
   use amr_parameters,only:dp
   implicit none
   real(dp)::v1x,v1y,v1z,v2x,v2y,v2z

   crossprodx=v1y*v2z-v1z*v2y

end function crossprodx

double precision function crossprody(v1x,v1y,v1z,v2x,v2y,v2z)

   ! y component of a cross product
   use amr_parameters,only:dp
   implicit none
   real(dp)::v1x,v1y,v1z,v2x,v2y,v2z

   crossprody=v1z*v2x-v1x*v2z

end function crossprody

double precision function crossprodz(v1x,v1y,v1z,v2x,v2y,v2z)

   ! z component of a cross product
   use amr_parameters,only:dp
   implicit none
   real(dp)::v1x,v1y,v1z,v2x,v2y,v2z

   crossprodz=v1x*v2y-v2x*v1y

end function crossprodz
!###########################################################
!###########################################################
!###########################################################

! NIMHD COEFFICIENTS

!###########################################################
!###########################################################
!###########################################################
double precision function betaad(rhocelln,rhon,dt,bsquare,bsquareold,dx,temper,limit)
   use hydro_parameters
   use amr_commons
   use cooling_module
   use nimhd_parameters
   use constants
   implicit none
   real(dp) ::rhocelln,rhon,betaadtemp,dt,bsquare,bsquareold,dx,temper
   real(dp)::gammaadbis,densionbis,rhotemp,rhotemp_cell
   real(dp)::xx,dtt,bbcgs
   logical::limit

   ! function which computes the coefficient beta which
   ! appears in ambipolar diffusion dB/dt=curl(gamma(j*B)*B)+...
   ! see Duffin & Pudritz 2008, astro-ph 08/10/08 eq (5)
   ! WARNING no mu_0 needed here because F_Lorentz used

   if(resistivity_method==0)then
      ! fixed resistivity
      betaad=1d0/(gammaAD*rhon)

   elseif(resistivity_method==1)then
      ! *** put your analytic resistivity here ***
      !analytical model resitivity(rho,T), Shu?
      gammaAD = 1
      betaad=1d0/(gammaAD*rhon)

   else
      ! table
      rhotemp = MAX(rhon,rho_threshold)
      rhotemp_cell = MAX(rhocelln,rho_threshold)

      xx=gammaadbis(rhotemp_cell,bsquare,bsquareold,temper)*densionbis(rhotemp_cell)*rhotemp_cell  ! dans la cellule
      ! gammaadbis and densionbis already in user units

      if(xx.ne.0d0) then
         betaad=1d0/xx 
      else
         betaad=1d39
         if(rhotemp < 1.0d+14)then
            write(*,*)'WARNING gammaadbis(rhocelln,bsquare,bsquareold,temper)*densionbis(rhocelln)*rhocelln in the cell equals 0',gammaadbis(rhotemp_cell,bsquare,bsquareold,temper),densionbis(rhocelln),rhocelln,bsquare,bsquareold,temper
         endif
      endif

      !xx=gammaadbis(rhotemp,bsquare,bsquareold,temper)*densionbis(rhon)*rhon   ! a l'interface : cote ou coin selon les cas. A utiliser si l'on est pas dans un cas seuille
      xx=gammaadbis(rhotemp,bsquare,bsquareold,temper)*densionbis(rhotemp)*rhotemp  

      ! a l'interface : cote ou coin selon les cas. A utiliser si l'on est pas dans un cas seuille

      if(xx.ne.0d0) then
         betaadtemp=1d0/xx 
      else
         betaadtemp=1d39
         if(rhotemp < 1.0d+14)then
            write(*,*)'WARNING gammaadbis(rhon,bsquare,bsquareold,temper)*densionbis(rhon)*rhon at the interface equals 0',gammaadbis(rhotemp,bsquare,bsquareold,temper),densionbis(rhon),rhon
         endif
      endif

      ! if the timestep has been limited, the resistivity needs to be adjusted
      if(limit.and.nimhd_dt_cap) then
         if(dt.ne.0d0) then
            ! recalculate the ambipolar diffusion timestep for the current cell
            xx=bsquare*betaad
            if(xx.ne.0d0) then
               dtt=coefad*dx*dx/xx
            else
               dtt=1d39
            endif
            ! check whether it is smaller than the global timestep that has been determined
            if (dtt.le.dt) then
               ! if so, adjust the resistivity to match the timestep
               betaad=coefad*dx*dx/(dt*bsquare)
            else
               betaad=betaadtemp
            endif
         endif
      endif
   endif

end function betaad

!###########################################################
!###########################################################
!###########################################################
double precision function gammaadbis(rhon,BBcell,BBcellold,temper)
   use hydro_parameters
   use amr_parameters,only:mu_gas
   use nimhd_parameters
   use resistivity_table
   use constants
   implicit none
   real(dp),intent(in)::rhon,BBcell,temper,BBcellold
   !---------------------------------------------------------------------
   ! Compure the coefficient gamma, which appears in ambipolar diffusion
   !    dB/dt=1/(gamma*rhoi*rhon)curl*(j*B)*B)+...
   ! see Duffin & Pudritz 2008, astro-ph 08/10/08 eq (6)
   ! WARNING no mu_0 needed here
   !---------------------------------------------------------------------
   real(dp)::rhoH,inp,eta_AD_chimie
   real(dp):: sigO,sigH,sigP,densionbis,BBcgs
   real(dp),parameter::n_H_max=2.5d+17     ! cm**-3
   real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v

   call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

   ! convert density to H/cc
   rhoH=rhon*2.0d0*H2_fraction*scale_d/(mu_gas*mH)
   rhoH = min(rhoH, n_H_max)

   ! extrapolate from table[density,temperature,magnetic field]
   call interpolate_table(rhoH,temper,BBcellold,sigO,sigH,sigP)

   inp=rhoH/2d0/H2_fraction     ! inp is neutrals.cc, to fit densionbis
   eta_AD_chimie=(sigO/(sigO**2+sigH**2)-1d0/sigP)   ! resistivity in s
   BBcgs=sqrt(BBcell*(4d0*pi*scale_d*(scale_v)**2))
   eta_AD_chimie=BBcgs**2/(eta_AD_chimie*densionbis(inp)*inp*scale_d*scale_d*c_cgs**2)  ! need B in G, output is gammaadbis in cgs
   !print *, eta_AD_chimie, temper

   gammaadbis=eta_AD_chimie*scale_t*scale_d ! in code units

end function gammaadbis
!###########################################################
!###########################################################
!###########################################################
double precision function densionbis(rhon)
   use amr_parameters, only : dp
   implicit none 
   real(dp),intent(in)::rhon
   !-----------------------------
   ! Compute the density of ions
   !-----------------------------
   real(dp)::rhoncgs
   ! Mellon & Li 2009 (?) or Hennebelle & Teyssier 2007
   real(dp):: coefionis=3d-16 !in cgs !remove ! coefionis*sqrt(n_H)=n_i , empirical value from Shu book 2, p. 363
   !real(dp):: default_ionisrate=1d-17
   real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v

   call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

   ! density of neutral in g/cm3
   rhoncgs=rhon*scale_d

   ! function which computes the density in g/cm3 of ions 
   ! see Duffin & Pudritz 2008, astro-ph 08/10/08 eq (14)
   !densionbis=coefionis*sqrt(rhoncgs*default_ionisrate/1.0d-17)
   densionbis=coefionis*sqrt(rhoncgs)

   ! back in code units
   densionbis=densionbis/scale_d

end function densionbis
!###########################################################
!###########################################################
!###########################################################
subroutine resistivities_etaohm(u,B2x,B2y,B2z,ngrid,i,j,k,dt,dx,etaohm,interpol_loc,limit)
   use amr_parameters
   use hydro_commons
   use nimhd_parameters
   implicit none
   real(dp),dimension(1:nvector,iu1:iu2,ju1:ju2,ku1:ku2,1:nvar+3),intent(in)::u 
   real(dp),dimension(1:nvector),intent(in)::B2x,B2y,B2z
   integer,intent(in)::ngrid,i,j,k,interpol_loc
   real(dp),intent(in)::dt,dx
   logical,intent(in)::limit
   real(dp),dimension(1:nvector,1:3),intent(out)::etaohm
   ! TODO comment
   !
   real(dp),dimension(1:nvector)::rhox,rhoy,rhoz
   real(dp)::tcellx,tcelly,tcellz,etaohmdiss
   integer::l

   if(resistivity_method==0) then ! fixed value
      do l=1,ngrid
         etaohm(l,1)=etaMD
         etaohm(l,2)=etaMD
         etaohm(l,3)=etaMD
      end do

   else if(resistivity_method==1) then ! analytical formula
      ! TODO
      do l=1,ngrid
         etaohm(l,1)=etaMD
         etaohm(l,2)=etaMD
         etaohm(l,3)=etaMD
      end do

   else ! table

      ! Get intepolated density values
      if(interpol_loc==1) then
         do l=1,ngrid
            rhox(l)=0.25d0*(u(l,i,j,k,   1)+u(l,i  ,j-1,k,   1)+u(l,i,j  ,k-1,   1)+u(l,i  ,j-1,k-1,   1))
            rhoy(l)=0.25d0*(u(l,i,j,k,   1)+u(l,i-1,j  ,k,   1)+u(l,i,j  ,k-1,   1)+u(l,i-1,j  ,k-1,   1))
            rhoz(l)=0.25d0*(u(l,i,j,k,   1)+u(l,i-1,j  ,k,   1)+u(l,i,j-1,k  ,   1)+u(l,i-1,j-1,k  ,   1))
         end do

      else if(interpol_loc==2) then
         do l=1,ngrid
            rhox(l)=0.5d0*(u(l,i,j,k,1)+u(l,i-1,j  ,k  ,1))
            rhoy(l)=0.5d0*(u(l,i,j,k,1)+u(l,i  ,j-1,k  ,1))
            rhoz(l)=0.5d0*(u(l,i,j,k,1)+u(l,i  ,j  ,k-1,1))
         end do

      else !interpol_loc==3
         do l=1,ngrid
            rhox(l)=0.5d0*(u(l,i,j,k,1)+u(l,i-1,j  ,k  ,1))
            rhoy(l)=0.5d0*(u(l,i,j,k,1)+u(l,i  ,j-1,k  ,1))
            rhoz(l)=0.5d0*(u(l,i,j,k,1)+u(l,i  ,j  ,k-1,1))
         end do

      end if

      do l=1,ngrid
         ! TODO generalise how to get the temperature using Eint
         ! Compute gas temperature in cgs
         call temperature_eos(rhox(l), 0d0, cellx)
         call temperature_eos(rhoy(l), 0d0, tcelly)
         call temperature_eos(rhoz(l), 0d0, tcellz)

         etaohm(l,1)=etaohmdiss(rhox(l),B2x(l),tcellx,dt,dx,limit)
         etaohm(l,2)=etaohmdiss(rhoy(l),B2y(l),tcelly,dt,dx,limit)
         etaohm(l,3)=etaohmdiss(rhoz(l),B2z(l),tcellz,dt,dx,limit)
      end do

   end if

end subroutine resistivities_etaohm
!###########################################################
!###########################################################
!###########################################################
double precision function etaohmdiss(rhon,BBcell,temper,dt,dx,limit)

   use amr_parameters,    only:dp,mu_gas
   use nimhd_parameters
   use resistivity_table, only:interpolate_table
   use constants,         only:c_cgs,pi,mH
   !-----------------------------------------------------------
   ! Function which computes the coefficient eta which appears
   ! in ohmic dissipation dB/dt=-curl(eta*curl(B))+...
   ! See Machida, Inutsuka, Matsumoto, ApJ, 670,1198-1213, 2007
   !-----------------------------------------------------------
   implicit none 
   real(dp) :: rhon,BBcell,temper  ! input cell variables
   real(dp) :: dx,dt               ! input cell size and simulation time step
   logical  :: limit               ! take into account limitation of timestep or not
   real(dp) :: rhoH,BBcgs
   real(dp) :: n_H_max=2.5d+17     ! cm**-3
   real(dp) :: sigO,sigH,sigP,eta_ohm_chimie
   real(dp) :: dtt
   real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v

   call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

   if(resistivity_method==0) then ! fixed value
      etaohmdiss=etaMD

   elseif(resistivity_method==1) then ! analytical formula
      ! TODO
      etaohmdiss=etaMD

   else ! table
      ! convert to CGS
      rhoH=rhon*2.0d0*H2_fraction*scale_d/(mu_gas*mH) ! convert in H/cc
      rhoH = MAX(rhoH,rho_threshold)
      rhoH = MIN(rhoH,n_H_max)
      ! extrapolate from table[density,temperature,magnetic field]
      call interpolate_table(rhoH,temper,BBcell,sigO,sigH,sigP) 
      eta_ohm_chimie = (1d0 / sigP) * c_cgs * c_cgs / (4.0_dp*pi)
      ! Ad-hoc modification to ensure that the ohmic resistivity falls to zero when the density exceeds 1.0e15
      ! when alkali metals are ionized.
      eta_ohm_chimie = max(eta_ohm_chimie * (1.0d0-tanh(rhoH/1.0d15)), 1d-36)
      ! convert to code units
      etaohmdiss=eta_ohm_chimie*scale_t/(scale_l)**2

      ! if the timestep was limited in courant fine, we need to adjust the resistivity to make things consistent.
      if(limit.and.nimhd_dt_cap) then
         if(dt.ne.0d0) then
            if(etaohmdiss.ne.0d0) then
               ! recalculate the ohmic timestep for the cell
               dtt=coefohm*dx*dx/etaohmdiss
            else
               dtt=1d39
            endif
            if (dtt.le.dt) then
               ! if it is smaller than the global timestep, we need to adjust the resistivity
               etaohmdiss=coefohm*dx*dx/dt
            endif
         endif
      endif
   endif

end function etaohmdiss
