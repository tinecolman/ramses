#if NDIM==3
module tsc
   use amr_parameters, only:dp,nvector,ndim,twotondim
   implicit none

   !--------------------------------------------------------------------
   !  (TSC)
   ! This technique is used for calculating the particle density on the grid,
   ! and is an alternative to CIC. Here it is onlz supported in 3D.
   ! In this scheme, a particle contributes to 3 cells in each direction.
   !--------------------------------------------------------------------

contains

   pure function tsc_cloud_volumes(wl,wc,wr) result(vol)
      implicit none
      ! wl: weighting function for leftmost cell
      ! wc: weighting function for central cell
      ! wr: weighting function for rightmost cell
      real(dp),dimension(1:ndim),intent(in)::wl,wc,wr
      ! cloud sub-volumes
      real(dp),dimension(1:threetondim)::vol
      !-----------------------------------------------------------------
      ! Calculate the 3**ndim overlapping sub-volumes of the particle 
      ! cloud with each of the covered cells.
      !-----------------------------------------------------------------
      vol(1 )=wl(1)*wl(2)*wl(3)
      vol(2 )=wc(1)*wl(2)*wl(3)
      vol(3 )=wr(1)*wl(2)*wl(3)
      vol(4 )=wl(1)*wc(2)*wl(3)
      vol(5 )=wc(1)*wc(2)*wl(3)
      vol(6 )=wr(1)*wc(2)*wl(3)
      vol(7 )=wl(1)*wr(2)*wl(3)
      vol(8 )=wc(1)*wr(2)*wl(3)
      vol(9 )=wr(1)*wr(2)*wl(3)
      vol(10)=wl(1)*wl(2)*wc(3)
      vol(11)=wc(1)*wl(2)*wc(3)
      vol(12)=wr(1)*wl(2)*wc(3)
      vol(13)=wl(1)*wc(2)*wc(3)
      vol(14)=wc(1)*wc(2)*wc(3)
      vol(15)=wr(1)*wc(2)*wc(3)
      vol(16)=wl(1)*wr(2)*wc(3)
      vol(17)=wc(1)*wr(2)*wc(3)
      vol(18)=wr(1)*wr(2)*wc(3)
      vol(19)=wl(1)*wl(2)*wr(3)
      vol(20)=wc(1)*wl(2)*wr(3)
      vol(21)=wr(1)*wl(2)*wr(3)
      vol(22)=wl(1)*wc(2)*wr(3)
      vol(23)=wc(1)*wc(2)*wr(3)
      vol(24)=wr(1)*wc(2)*wr(3)
      vol(25)=wl(1)*wr(2)*wr(3)
      vol(26)=wc(1)*wr(2)*wr(3)
      vol(27)=wr(1)*wr(2)*wr(3)

   end function tsc_cloud_volumes
   !###########################################################
   pure function tsc_cloud_3cube_grid_indices(igl,igc,igr) result(kg)
      implicit none
      ! index of the cell in the local 3x3x3 grid-cube (0 to 5), for left and right overlap
      integer,dimension(1:ndim),intent(in)::igl,igc,igr
      ! 
      integer,dimension(1:threetondim)::kg
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
      kg(1 ) = 1 + igl(1) + 3*igl(2) + 9*igl(3)
      kg(2 ) = 1 + igc(1) + 3*igl(2) + 9*igl(3)
      kg(3 ) = 1 + igr(1) + 3*igl(2) + 9*igl(3)
      kg(4 ) = 1 + igl(1) + 3*igc(2) + 9*igl(3)
      kg(5 ) = 1 + igc(1) + 3*igc(2) + 9*igl(3)
      kg(6 ) = 1 + igr(1) + 3*igc(2) + 9*igl(3)
      kg(7 ) = 1 + igl(1) + 3*igr(2) + 9*igl(3)
      kg(8 ) = 1 + igc(1) + 3*igr(2) + 9*igl(3)
      kg(9 ) = 1 + igr(1) + 3*igr(2) + 9*igl(3)
      kg(10) = 1 + igl(1) + 3*igl(2) + 9*igc(3)
      kg(11) = 1 + igc(1) + 3*igl(2) + 9*igc(3)
      kg(12) = 1 + igr(1) + 3*igl(2) + 9*igc(3)
      kg(13) = 1 + igl(1) + 3*igc(2) + 9*igc(3)
      kg(14) = 1 + igc(1) + 3*igc(2) + 9*igc(3)
      kg(15) = 1 + igr(1) + 3*igc(2) + 9*igc(3)
      kg(16) = 1 + igl(1) + 3*igr(2) + 9*igc(3)
      kg(17) = 1 + igc(1) + 3*igr(2) + 9*igc(3)
      kg(18) = 1 + igr(1) + 3*igr(2) + 9*igc(3)
      kg(19) = 1 + igl(1) + 3*igl(2) + 9*igr(3)
      kg(20) = 1 + igc(1) + 3*igl(2) + 9*igr(3)
      kg(21) = 1 + igr(1) + 3*igl(2) + 9*igr(3)
      kg(22) = 1 + igl(1) + 3*igc(2) + 9*igr(3)
      kg(23) = 1 + igc(1) + 3*igc(2) + 9*igr(3)
      kg(24) = 1 + igr(1) + 3*igc(2) + 9*igr(3)
      kg(25) = 1 + igl(1) + 3*igr(2) + 9*igr(3)
      kg(26) = 1 + igc(1) + 3*igr(2) + 9*igr(3)
      kg(27) = 1 + igr(1) + 3*igr(2) + 9*igr(3)

   end function tsc_cloud_3cube_grid_indices
   !###########################################################
   pure function tsc_cloud_cell_positions(icl,icc,icr) result(icell)
      implicit none
      ! left, center, right 
      integer,dimension(1:ndim),intent(in)::icl,icc,icr
      ! position of the overlap cell in its grid (ind)
      integer,dimension(1:threetondim)::icell
      !------------------------------------------------------------------
      ! Compute the position ind of the cell in its grid (1 to twotondim)
      ! for each of the 27 overlapping cells.
       !------------------------------------------------------------------
      icell(1 ) = 1 + icl(1) + 2*icl(2) + 4*icl(3)
      icell(2 ) = 1 + icc(1) + 2*icl(2) + 4*icl(3)
      icell(3 ) = 1 + icr(1) + 2*icl(2) + 4*icl(3)
      icell(4 ) = 1 + icl(1) + 2*icc(2) + 4*icl(3)
      icell(5 ) = 1 + icc(1) + 2*icc(2) + 4*icl(3)
      icell(6 ) = 1 + icr(1) + 2*icc(2) + 4*icl(3)
      icell(7 ) = 1 + icl(1) + 2*icr(2) + 4*icl(3)
      icell(8 ) = 1 + icc(1) + 2*icr(2) + 4*icl(3)
      icell(9 ) = 1 + icr(1) + 2*icr(2) + 4*icl(3)
      icell(10) = 1 + icl(1) + 2*icl(2) + 4*icc(3)
      icell(11) = 1 + icc(1) + 2*icl(2) + 4*icc(3)
      icell(12) = 1 + icr(1) + 2*icl(2) + 4*icc(3)
      icell(13) = 1 + icl(1) + 2*icc(2) + 4*icc(3)
      icell(14) = 1 + icc(1) + 2*icc(2) + 4*icc(3)
      icell(15) = 1 + icr(1) + 2*icc(2) + 4*icc(3)
      icell(16) = 1 + icl(1) + 2*icr(2) + 4*icc(3)
      icell(17) = 1 + icc(1) + 2*icr(2) + 4*icc(3)
      icell(18) = 1 + icr(1) + 2*icr(2) + 4*icc(3)
      icell(19) = 1 + icl(1) + 2*icl(2) + 4*icr(3)
      icell(20) = 1 + icc(1) + 2*icl(2) + 4*icr(3)
      icell(21) = 1 + icr(1) + 2*icl(2) + 4*icr(3)
      icell(22) = 1 + icl(1) + 2*icc(2) + 4*icr(3)
      icell(23) = 1 + icc(1) + 2*icc(2) + 4*icr(3)
      icell(24) = 1 + icr(1) + 2*icc(2) + 4*icr(3)
      icell(25) = 1 + icl(1) + 2*icr(2) + 4*icr(3)
      icell(26) = 1 + icc(1) + 2*icr(2) + 4*icr(3)
      icell(27) = 1 + icr(1) + 2*icr(2) + 4*icr(3)
 
   end function tsc_cloud_cell_positions
   !###########################################################

end module tsc
#endif