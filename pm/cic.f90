module cic
   use amr_parameters, only:dp,nvector,ndim,twotondim
   implicit none

   ! This module contains helper functions for the Cloud-in-cell scheme

contains

   pure function cic_cloud_volumes(dg,dd) result(vol)
      implicit none
      ! left and right distance to the cell boundary of the particle
      real(dp),dimension(1:ndim),intent(in)::dg,dd
      ! cloud sub-volumes
      real(dp),dimension(1:twotondim)::vol
      !-----------------------------------------------------------------
      ! Calculate the twotondim overlapping sub-volumes of the particle 
      ! cloud with each of the covered cells using the cloud-in-cell (CIC)
      ! scheme. In this scheme, the cloud is a cubic volume of size dx**ndim.
      ! The sub-volumes are calculated as rectangles, using the distances 
      ! to the cell boundaries dd and dg.
      !-----------------------------------------------------------------
#if NDIM==1
      vol(1)=dg(1)
      vol(2)=dd(1)
#elif NDIM==2
      vol(1)=dg(1)*dg(2)
      vol(2)=dd(1)*dg(2)
      vol(3)=dg(1)*dd(2)
      vol(4)=dd(1)*dd(2)
#elif NDIM==3
      vol(1)=dg(1)*dg(2)*dg(3)
      vol(2)=dd(1)*dg(2)*dg(3)
      vol(3)=dg(1)*dd(2)*dg(3)
      vol(4)=dd(1)*dd(2)*dg(3)
      vol(5)=dg(1)*dg(2)*dd(3)
      vol(6)=dd(1)*dg(2)*dd(3)
      vol(7)=dg(1)*dd(2)*dd(3)
      vol(8)=dd(1)*dd(2)*dd(3)
#endif

   end function cic_cloud_volumes
   !###########################################################
   pure function cic_cloud_3cube_grid_indices(igg,igd) result(kg)
      implicit none
      ! index of the cell in the local 3x3x3 grid-cube (0 to 5), for left and right overlap
      integer,dimension(1:ndim),intent(in)::igg,igd
      ! 
      integer,dimension(1:twotondim)::kg
      !------------------------------------------------------------------
      ! For each dimension, the particle cloud (of size dx**ndim) overlaps with
      ! a cell boundary, dividing the cloud into a left and right part. 
      ! (d = droit (FR) = right, g = gauche (FR) = left)
      ! This routine determines the indices in the overlap zone needed to
      ! determine the global indices of the cells and their grids that overlap
      ! with the particles in this vector sweep.
      !------------------------------------------------------------------

      ! Determine the identifying number of the cell in the 3x3x3 grid-cube.
      ! We do this by converting igg(j,idim) and igd(j,idim) to the 1D index kg(j,ind)
#if NDIM==1
      kg(1)=1+igg(1)
      kg(2)=1+igd(1)
#elif NDIM==2
      kg(1)=1+igg(1)+3*igg(2)
      kg(2)=1+igd(1)+3*igg(2)
      kg(3)=1+igg(1)+3*igd(2)
      kg(4)=1+igd(1)+3*igd(2)
#elif NDIM==3
      kg(1)=1+igg(1)+3*igg(2)+9*igg(3)
      kg(2)=1+igd(1)+3*igg(2)+9*igg(3)
      kg(3)=1+igg(1)+3*igd(2)+9*igg(3)
      kg(4)=1+igd(1)+3*igd(2)+9*igg(3)
      kg(5)=1+igg(1)+3*igg(2)+9*igd(3)
      kg(6)=1+igd(1)+3*igg(2)+9*igd(3)
      kg(7)=1+igg(1)+3*igd(2)+9*igd(3)
      kg(8)=1+igd(1)+3*igd(2)+9*igd(3)
#endif

   end function cic_cloud_3cube_grid_indices
   !###########################################################
   pure function cic_cloud_cell_positions(icg,icd) result(icell)
      implicit none
      ! left and right 
      integer,dimension(1:ndim),intent(in)::icg,icd
      ! position of the overlap cell in its grid (ind)
      integer,dimension(1:twotondim)::icell
      !------------------------------------------------------------------
      ! Compute the position ind of the cell in its grid (1 to twotondim)
      !------------------------------------------------------------------
#if NDIM==1
      icell(1)=1+icg(1)
      icell(2)=1+icd(1)
#elif NDIM==2
      icell(1)=1+icg(1)+2*icg(2)
      icell(2)=1+icd(1)+2*icg(2)
      icell(3)=1+icg(1)+2*icd(2)
      icell(4)=1+icd(1)+2*icd(2)
#elif NDIM==3
      icell(1)=1+icg(1)+2*icg(2)+4*icg(3)
      icell(2)=1+icd(1)+2*icg(2)+4*icg(3)
      icell(3)=1+icg(1)+2*icd(2)+4*icg(3)
      icell(4)=1+icd(1)+2*icd(2)+4*icg(3)
      icell(5)=1+icg(1)+2*icg(2)+4*icd(3)
      icell(6)=1+icd(1)+2*icg(2)+4*icd(3)
      icell(7)=1+icg(1)+2*icd(2)+4*icd(3)
      icell(8)=1+icd(1)+2*icd(2)+4*icd(3)
#endif

   end function cic_cloud_cell_positions
   !###########################################################
   pure function cic_cloud_cell_positions_bis(icg,icd) result(icell)
      implicit none
      ! left and right 
      integer,dimension(1:ndim),intent(in)::icg,icd
      ! position of the overlap cell in its grid (ind)
      integer,dimension(1:twotondim)::icell
      !------------------------------------------------------------------
      ! Compute the position ind of the cell in its grid (1 to twotondim)
      !------------------------------------------------------------------
#if NDIM==1
      icell(1)=1+icg(1)
      icell(2)=1+icd(1)
#elif NDIM==2
      icell(1)=1+icg(1)+3*icg(2)
      icell(2)=1+icd(1)+3*icg(2)
      icell(3)=1+icg(1)+3*icd(2)
      icell(4)=1+icd(1)+3*icd(2)
#elif NDIM==3
      icell(1)=1+icg(1)+3*icg(2)+9*icg(3)
      icell(2)=1+icd(1)+3*icg(2)+9*icg(3)
      icell(3)=1+icg(1)+3*icd(2)+9*icg(3)
      icell(4)=1+icd(1)+3*icd(2)+9*icg(3)
      icell(5)=1+icg(1)+3*icg(2)+9*icd(3)
      icell(6)=1+icd(1)+3*icg(2)+9*icd(3)
      icell(7)=1+icg(1)+3*icd(2)+9*icd(3)
      icell(8)=1+icd(1)+3*icd(2)+9*icd(3)
#endif

   end function cic_cloud_cell_positions_bis
   !###########################################################

end module cic