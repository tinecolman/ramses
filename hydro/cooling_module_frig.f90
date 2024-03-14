!! Cooling from frig version (Audit & Hennebelle 2005)
!! solve_cooling_ism is used if there is no RT
!! rt_metal_cool is used to solve metal cooling with RT
!! Authors: Valeska Valdivia, Patrick Hennebelle, Benjamin Godard
!###########################################################
!###########################################################
!###########################################################
!###########################################################
!! ph 11/2010 
!! estimate the column density through the box in 6 directions
!! from the edges of a grid using the tree structure of RAMSES. 
!! To get the full column density one must add the contribution 
!! of the cells within the oct. All information is local 
!! and do not require communication between cpus
!! VV 2012 
!! Modified version in order to take into account the contribution
!! of all the cells contained in the cubic shells. It considers 
!! directions based on spherical projections. 

subroutine column_density(ind_grid,ngrid,ilevel,column_dens, H2column_dens)
  use amr_commons  
  use hydro_commons
  use cooling_module
  implicit none

  integer,dimension(1:nvector)                          :: ind_grid
  integer                                               :: ilevel,ngrid
  real(dp),dimension(1:nvector,1:NdirExt_m,1:NdirExt_n) :: column_dens, H2column_dens

  integer,parameter                                     :: ndir=6       
  integer                                               :: i,ind,idim 
  integer                                               :: ix,iy,iz,idir,il,twice

  real(dp),dimension(1:nvector,1:3, 1:ndir)             :: xpart
  real(dp),dimension(1:nvector,1:3)                     :: xpart_int
  real(dp)                                              :: dx,dx_loc, xgaux
  integer                                               :: nx_loc,pos_son,ind_father

  real(dp),dimension(1:twotondim,1:3)                   :: xc
  real(dp),dimension(1:nvector,1:ndim)                  :: xx,xx_check
  real(dp),dimension(1:nvector)                         :: dist

  real(dp),dimension(1:nvector,1:ndir)                  :: col_dens,col_check 
  integer,dimension(1:nvector)                          :: cell_index,cell_levl
  real(dp),dimension(3,6)                               :: shift
  integer, dimension(1:ngrid,1:ndir)                    :: ind_lim1, ind_lim2

  
  if(numbtot(1,ilevel)==0)return
  
  !define various things needed to get the distance
  
  ! Mesh size at level ilevel in coarse cell units
  dx=0.5_dp**ilevel
  
  ! Set position of cell centers relative to grid center
  do ind=1,twotondim
     iz=(ind-1)/4
     iy=(ind-1-4*iz)/2
     ix=(ind-1-2*iy-4*iz)
     if(ndim>0)xc(ind,1)=(dble(ix)-0.5_dp)*dx
     if(ndim>1)xc(ind,2)=(dble(iy)-0.5_dp)*dx
     if(ndim>2)xc(ind,3)=(dble(iz)-0.5_dp)*dx
  end do

  ! define the path direction 
  ! first index is for x,y,z while second is for direction
  ! x,-x,y,-y,z,-z in this order 
  shift(1,1) = 1. ; shift(2,1) = 0. ; shift(3,1) = 0. 
  shift(1,2) =-1. ; shift(2,2) = 0. ; shift(3,2) = 0. 
  shift(1,3) = 0. ; shift(2,3) = 1. ; shift(3,3) = 0. 
  shift(1,4) = 0. ; shift(2,4) =-1. ; shift(3,4) = 0. 
  shift(1,5) = 0. ; shift(2,5) = 0. ; shift(3,5) = 1. 
  shift(1,6) = 0. ; shift(2,6) = 0. ; shift(3,6) =-1.
  
  column_dens(:,:,:) = 0.
  H2column_dens(:,:,:) = 0.
  ind_lim1(:,:)= 0
  ind_lim2(:,:)= 0

  !-----    DETERMINATION OF BOUNDS  -----    
  !  Here we calculate the limits for the cubic shells considered at each 
  !  resolution level. We obtain external and internal limits.

  do idir=1,ndir        ! loop over the 6 directions
     do idim=1,ndim
        do i=1,ngrid
           xpart(i,idim,idir)=xg(ind_grid(i),idim)+shift(idim,idir)*dx
           col_dens(i,idir)=0.
           col_check(i,idir)=0.
         end do   !i
      end do      !idim
   end do         !idir

   do il = ilevel-1,1,-1            ! loop recursively over level
      dx_loc = 0.5_dp**(il)
      do idir=1,ndir                ! loop over the 6 directions
         do i=1,ngrid
            do idim=1,ndim
               if(shift(idim,idir).NE.0) then
                  xgaux = dx_loc*(INT(xg(ind_grid(i),idim)/dx_loc) + 0.5_dp)
                  ind_lim1(i,idir)= shift(idim,idir)*INT(ABS(xpart(i,idim,idir)-xgaux)/dx_loc )                  
               end if
            end do
         end do
         
         !--- we do it twice because of oct structure           
         do twice=1,2
            do idim=1,ndim
               do i=1,ngrid
                  xpart(i,idim,idir)= xpart(i,idim,idir)+shift(idim,idir)*(dx_loc/2.)*twice
                  xpart_int(i,idim)= xpart(i,idim,idir)
               end do
            end do
            
            call get_cell_index3(cell_index,cell_levl,xpart_int,il,ngrid)
            
            !--- NOT NECESSARY ---
            do i=1,ngrid ! loop over grid to calculate the column density
               if (cell_index(i) .ne. -1) then
                  if( cell_levl(i) .ne. il) then
                     write(*,*) 'problem in the calculation of column density'
                     write(*,*)  'cell_levl(i),il,ilevel',cell_levl(i),il,ilevel
                     !stop
                  endif

                  col_dens(i,idir) = col_dens(i,idir) + dx_loc*uold(cell_index(i),1)
                  col_check(i,idir) = col_check(i,idir) + dx_loc
               end if
            end do !end loop over grid
            !----------- not necessary ---              
            
         end do        !end of do it twice

         !move the particle at the edge of the cell at level il
         do idim=1,ndim
            do i=1,ngrid

               if(shift(idim,idir) .NE. 0) then
                  xgaux = dx_loc*(INT(xg(ind_grid(i),idim)/dx_loc) + 0.5_dp)
                  ind_lim2(i,idir)= shift(idim,idir)*INT(ABS(xpart(i,idim,idir)-xgaux)/dx_loc )
               end if

               xpart(i,idim,idir)= xpart(i,idim,idir)+shift(idim,idir)*dx_loc/2.
               xpart_int(i,idim)= xpart(i,idim,idir)
                              
            end do
         end do

         !now before starting the next iteration one must check whether the particle is 
         !at the interface of a cell at level il-1 or whether one is in the center of such a cell
         !in the first case it is fine in the other case, we must jump from another
         !dx_loc to reach the next boundary of the next cell at level il-1
         
         !get cells at level il-1
         if (il .eq. 1) exit
         call get_cell_index3(cell_index,cell_levl,xpart_int,il-1,ngrid)
         
         do i=1,ngrid
            if (cell_index(i) .ne. -1)  then
               !get the father of the cell
               ind_father = mod(cell_index(i) -ncoarse,ngridmax)  !father(cell_index(i)) 
               !get the cell position in its oct
               pos_son = (cell_index(i)-ncoarse-ind_father)/ngridmax + 1
               
               !calculate the cell position
               !note that in principle pos_son is enough to get the requested information
               !here we choose to calculate the coordinate instead.            
               do idim=1,ndim           
                  xx_check(i,idim)=xg(ind_father,idim)+xc(pos_son,idim)*(0.5**(il-1-ilevel))
               enddo
            end if
         end do                             !ok

         !now calculate the distance between these cells and the particle
         !along the direction of interest
         dist=0
         do idim=1,ndim           
            do i=1,ngrid
               if (cell_index(i) .ne. -1)  dist(i) = dist(i) + (( xx_check(i,idim) - xpart(i,idim,idir) )*shift(idim,idir))**2
            end do
         end do
         do i=1,ngrid
            dist(i)=sqrt(dist(i))
         end do

         !finally if we are not at an interface, we move the particle to the next interface
         do i=1,ngrid
            if( dist(i) .lt. dx_loc/4.) then
               do idim=1,ndim
                  if (cell_index(i) .ne. -1) then
                     xpart(i,idim,idir)=xpart(i,idim,idir)+shift(idim,idir)*dx_loc
                     
                     !----------------------------------------------------------
                     ! we set the outer limit for the cubic shell
                     if(shift(idim,idir) .NE. 0) then
                        xgaux = dx_loc*(INT(xg(ind_grid(i),idim)/dx_loc) + 0.5_dp)
                        ind_lim2(i,idir)= shift(idim,idir)*INT(ABS(xpart(i,idim,idir)-xgaux)/dx_loc )
                     end if
                     !----------------------------------------------------------
                  endif
               end do
               
               !--- Check ---
               if (cell_index(i) .ne. -1) then
                  col_dens (i,idir) = col_dens (i,idir) + dx_loc*uold(cell_index(i),1)
                  col_check(i,idir) = col_check(i,idir) + dx_loc
               endif
               !--- check ---
               
            end if                          ! dist
         end do                             ! i
      end do                                ! end of loop over direction idir
      
      !-----  ADD CONTRIBUTIONS TO COLUMN DENSITY  -----------------
      ! once we have calculated the limits we call the contribution routine,
      ! that sums up to the column density

      call contribution(ind_grid, ngrid, ilevel, il, ind_lim1, ind_lim2, column_dens,H2column_dens)

   end do                                   !end of loop recursively over level

   !now check that the whole grid has been properly covered
   do i=1,ngrid !end loop over grid
      !       if(myid .eq. 1 .and. i .eq. 1) write(*,*) 'col tot x',col_check(i,1)+col_check(i,2)+dx*2. 
      if(col_check(i,1)+col_check(i,2)+dx*2. .ne. 1.) then 
         write(*,*) 'col tot x',col_check(i,1)+col_check(i,2)+dx*2. 
         write(*,*) 'col tot x',col_check(i,1),col_check(i,2),dx*2. 
         stop
      endif
      if(col_check(i,3)+col_check(i,4)+dx*2. .ne. 1.) then 
         write(*,*) 'col tot y',col_check(i,3)+col_check(i,4)+dx*2. 
         write(*,*) 'col tot y',col_check(i,3),col_check(i,4),dx*2. 
         stop
      endif
      if(col_check(i,5)+col_check(i,6)+dx*2. .ne. 1.) then 
         write(*,*) 'col tot z',col_check(i,5)+col_check(i,6)+dx*2. 
         write(*,*) 'col tot z',col_check(i,5),col_check(i,6),dx*2. 
         stop
      endif
   enddo !end loop over grid

 end subroutine column_density
!#########################################################
!#########################################################
!#########################################################
!#########################################################
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!! routine provided by Romain on July 2010 and included by PH on November 2010
subroutine get_cell_index3(cell_index,cell_levl,xpart,ilevel,np)
  use amr_commons
  implicit none
  integer                                :: np,ilevel
  integer,dimension(1:nvector)           :: cell_index,cell_levl
  real(dp),dimension(1:nvector,1:3)      :: xpart
  ! This function returns the index of the cell, at maximum level
  ! ilevel, in which the input particle sits
  real(dp)                               :: xx,yy,zz
  integer                                :: i,j,ii,jj,kk,ind,iskip,igrid,ind_cell,igrid0
  
  if ((nx.eq.1).and.(ny.eq.1).and.(nz.eq.1)) then
  else if ((nx.eq.3).and.(ny.eq.3).and.(nz.eq.3)) then
  else
     write(*,*)"nx=ny=nz != 1,3 is not supported."
     call clean_stop
  end if
  
  igrid0=son(1+icoarse_min+jcoarse_min*nx+kcoarse_min*nx*ny)
  do i=1,np
     xx = xpart(i,1) + (nx-1)/2.0
     yy = xpart(i,2) + (ny-1)/2.0
     zz = xpart(i,3) + (nz-1)/2.0
     
     if( ((xx .le. 0) .or. (xx .ge. 1.)) .or. ((yy .le. 0) .or. (yy .ge. 1.)) .or. ((zz .le. 0) .or. (zz .ge. 1.)) ) then 
        cell_index(i)=-1.
     else 
        igrid=igrid0
        do j=1,ilevel
           ii=1; jj=1; kk=1
           if(xx<xg(igrid,1))ii=0
           if(yy<xg(igrid,2))jj=0
           if(zz<xg(igrid,3))kk=0
           ind=1+ii+2*jj+4*kk
           iskip=ncoarse+(ind-1)*ngridmax
           ind_cell=iskip+igrid
           igrid=son(ind_cell)
           if(igrid==0.or.j==ilevel)  exit
        end do
        cell_index(i)=ind_cell
        cell_levl(i)=j
     endif
  end do

end subroutine get_cell_index3
!#########################################################
!#########################################################
!#########################################################
!#########################################################
!! 2012 VV 
!! Modified version of get_cell_index:
!! This subroutine gives the cell index of just one cell
!! This function returns the index of one cell, at maximum level
!! ilevel, in which the input particle sits
subroutine get_cell_index2(cell_index2,cell_levl2,xpart2,ilevel)
  use amr_commons
  implicit none

  integer                  ::cell_index2,cell_levl2,ilevel
  real(dp),dimension(1:3)  ::xpart2
  real(dp)                 ::xx,yy,zz
  integer                  ::j,ii,jj,kk,ind,iskip,igrid,ind_cell,igrid0
  
  if ((nx.eq.1).and.(ny.eq.1).and.(nz.eq.1)) then
  else if ((nx.eq.3).and.(ny.eq.3).and.(nz.eq.3)) then
  else
     write(*,*)"nx=ny=nz != 1,3 is not supported."
     call clean_stop
  end if
  
  igrid0=son(1+icoarse_min+jcoarse_min*nx+kcoarse_min*nx*ny)
  
  xx = xpart2(1) + (nx-1)/2.0
  yy = xpart2(2) + (ny-1)/2.0
  zz = xpart2(3) + (nz-1)/2.0
  
  if( ((xx .le. 0) .or. (xx .ge. 1.)) .or. ((yy .le. 0) .or. (yy .ge. 1.)) .or. ((zz .le. 0) .or. (zz .ge. 1.)) ) then
     cell_index2=-1.
  else
     igrid=igrid0
     do j=1,ilevel
        ii=1; jj=1; kk=1
        if(xx<xg(igrid,1))ii=0
        if(yy<xg(igrid,2))jj=0
        if(zz<xg(igrid,3))kk=0
        ind=1+ii+2*jj+4*kk
        iskip=ncoarse+(ind-1)*ngridmax
        ind_cell=iskip+igrid
        igrid=son(ind_cell)
        if(igrid==0.or.j==ilevel)  exit
     end do
     cell_index2=ind_cell
     cell_levl2=j
  endif
  
end subroutine get_cell_index2
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! 02.04.2012 VV
!! Contribution to directions. Calculation of "column_dens" used in
!! subroutine column_density
!! It is here where we actually add the contributions of the cells in the shell
!! to the column densities
!! PH 20/09/2021 adapted it to ramses RT with H2 formation 
subroutine contribution(ind_grid, ngrid, ilevel, il, ind_lim1, ind_lim2, column_dens, H2column_dens)
  use amr_commons
  use hydro_commons
  use cooling_module

#ifdef RT
  use rt_parameters,only: isH2,iIons
#endif

  implicit none

  integer,parameter                                                   :: ndir=6  
  integer, intent (in)                                                :: ilevel, il,ngrid
  integer,dimension(1:nvector)                                        :: ind_grid
  integer, dimension(1:ngrid,1:ndir), intent (in)                     :: ind_lim1, ind_lim2
  real(dp),dimension(1:nvector,1:NdirExt_m,1:NdirExt_n),intent(inout) :: column_dens, H2column_dens

  !!take care "nener" should be added here. It is fine if it is 0 of course 
  integer                                               :: neulS=8+nextinct

  integer                                               :: i, inx,iny,inz, deltam
  integer                                               :: m, n, mloop, nloop, nl, mn
  real(dp)                                              :: dx_loc, dx_cross_ext, halfdx, quartdx
  integer, dimension(1:NdirExt_n)                       :: deltan1, deltan2
  real(dp),dimension(1:3)                               :: xgcoarse, xoct
  integer, dimension(1:3)                               :: indaux, indaux2
  integer                                               :: ind_oct, ind_oct1, ind_oct2, reg
  real(dp),dimension(1:3)                               :: xpart2, xzero
  real(dp)                                              :: xg_il, yg_il, zg_il     !xg at level il
  integer                                               :: cell_ind2, cell_levl2
  integer,dimension(1:6,1:3)                            :: l_inf, l_sup

  integer                                               :: ix, iy,iz

  real(dp)                                              :: dist_grid , weight

  
  !---  m, n loop limits  ------------------------------------------
  ! here we define the limits for the loops around the direction to the cell center
  ! For the vertical directions (m =0, NdirExt_m), the azimuthal angle covers 2*pi,
  ! for other directions we use +/- 1/8 of the total directions
  !----------------------------------------------------------------
  do m = 1, NdirExt_m
     ! for the vertical directions 
     if(m .EQ. 1 .OR. m .EQ. NdirExt_m) then
        deltan1(m) = INT(NdirExt_n/2.0_dp)
        deltan2(m) = deltan1(m) -1
     else
        deltan1(m) = INT(NdirExt_n/8)
        deltan2(m) = deltan1(m)
     end if
  end do
  deltam = INT((NdirExt_m-1)/4.)

  dx_loc = 0.5_dp**(il)
  halfdx  = dx_loc/2_dp
  quartdx = dx_loc/4.0_dp

  !-------------------------------------------------!
  !       CONTRIBUTION TO DIRECTIONS                !
  !-------------------------------------------------!

  !THETA AND PHI   
  
  !LOOP over cells
  do i=1,ngrid
     
     xzero(1) = xg(ind_grid(i),1)       ! xzero is the grid center 
     xzero(2) = xg(ind_grid(i),2)  
     xzero(3) = xg(ind_grid(i),3)  
     
     !! we have to determine in which configuration the target cell and the treated cell are
     !! in order to use the precalculated values for the geometrical corrections.
     !! the configuration depends on the difference of levels and their relative positions in the octs

     !-----  OBTAINING ind within the oct   -----         
     if(il .EQ. ilevel-1) then
        ind_oct = 73
        
     else if(il .EQ. ilevel -2) then
        do inx =1, 3
           xoct(inx)     = (INT(xzero(inx)/dx_loc) +0.5_dp)*dx_loc
           indaux(inx)   = INT((xzero(inx)-xoct(inx))/halfdx +0.5_dp)
        end do
        ind_oct = indaux(1) + 1 + 2*indaux(2) + 4*indaux(3)
        ind_oct = ind_oct + 64
        
     else         !if(il .GE. ilevel -3) then
        
        do inx =1, 3
           xgcoarse(inx) = (INT(xzero(inx)/halfdx) +0.5_dp)*halfdx
           xoct(inx)     = (INT(xzero(inx)/dx_loc) +0.5_dp)*dx_loc
           indaux2(inx)  = INT((xzero(inx)-xgcoarse(inx))/quartdx +0.5_dp)
           indaux(inx)   = INT((xgcoarse(inx)-xoct(inx))/halfdx +0.5_dp)
        end do
        ind_oct1 = indaux(1) + 1 + 2*indaux(2) + 4*indaux(3)    !coarse level
        ind_oct2 = indaux2(1) + 1 + 2*indaux2(2) + 4*indaux2(3)    !fine level
        ind_oct = (ind_oct1-1)*8 + ind_oct2
        
     end if

     !-----   SPLITTED LOOPS to avoid the "if" for skipping treated cells   -----
     ! we cut the cubic shell in 6 regions
     ! here we define the limits for the splitted regions and we integrate the column density.
     ! 6 REGIONS :

     l_inf(1,3) = ind_lim2(i,6)  
     l_sup(1,3) = ind_lim1(i,6)-1
     l_inf(1,2) = ind_lim2(i,4)
     l_sup(1,2) = ind_lim2(i,3)
     l_inf(1,1) = ind_lim2(i,2)
     l_sup(1,1) = ind_lim2(i,1)

     l_inf(2,3) = ind_lim1(i,5)+1
     l_sup(2,3) = ind_lim2(i,5)
     l_inf(2,2) = ind_lim2(i,4)
     l_sup(2,2) = ind_lim2(i,3)
     l_inf(2,1) = ind_lim2(i,2)
     l_sup(2,1) = ind_lim2(i,1)

     l_inf(3,3) = ind_lim1(i,6)
     l_sup(3,3) = ind_lim1(i,5)
     l_inf(3,2) = ind_lim2(i,4)
     l_sup(3,2) = ind_lim1(i,4)-1
     l_inf(3,1) = ind_lim2(i,2)
     l_sup(3,1) = ind_lim2(i,1)

     l_inf(4,3) = ind_lim1(i,6)
     l_sup(4,3) = ind_lim1(i,5)
     l_inf(4,2) = ind_lim1(i,3)+1
     l_sup(4,2) = ind_lim2(i,3)
     l_inf(4,1) = ind_lim2(i,2)
     l_sup(4,1) = ind_lim2(i,1)

     l_inf(5,3) = ind_lim1(i,6)
     l_sup(5,3) = ind_lim1(i,5)
     l_inf(5,2) = ind_lim1(i,4)
     l_sup(5,2) = ind_lim1(i,3)
     l_inf(5,1) = ind_lim2(i,2)
     l_sup(5,1) = ind_lim1(i,2)-1

     l_inf(6,3) = ind_lim1(i,6)
     l_sup(6,3) = ind_lim1(i,5)
     l_inf(6,2) = ind_lim1(i,4)
     l_sup(6,2) = ind_lim1(i,3)
     l_inf(6,1) = ind_lim1(i,1)+1
     l_sup(6,1) = ind_lim2(i,1)
     

     xg_il = dx_loc*(INT( xg(ind_grid(i),1)/dx_loc) + 0.5_dp)
     yg_il = dx_loc*(INT( xg(ind_grid(i),2)/dx_loc) + 0.5_dp)
     zg_il = dx_loc*(INT( xg(ind_grid(i),3)/dx_loc) + 0.5_dp)

     do reg=1,6

        do inz=l_inf(reg,3), l_sup(reg,3)
           iz = inz + 6                   ! +6 : respect to the center of the cubic shell 
           xpart2(3)= zg_il + dx_loc*inz 

           do iny=l_inf(reg,2), l_sup(reg,2)    
              iy = iny + 6
              xpart2(2)= yg_il + dx_loc*iny

              do inx=l_inf(reg,1), l_sup(reg,1) 
                 ix = inx +6
                 xpart2(1)= xg_il + dx_loc*inx

                 !+++  04/02/2013  ++++++++++++++++++++
                 ! here we obtain the direction to the center of the cell in the shell

                 mn = dirMN_ext(ind_oct, ix, iy, iz)

                 if(Mdx_ext_logical(ind_oct, ix, iy, iz, mn)) then
                    
                    call get_cell_index2(cell_ind2,cell_levl2,xpart2,il)

                    !PH 29/11/2019
                    !calculate the distance of the cells from the grid
                    dist_grid = sqrt( (xzero(1)-xpart2(1))**2 + (xzero(2)-xpart2(2))**2 + (xzero(3)-xpart2(3))**2 ) 
                    !if above a threshold, then we put the weigth of this cells to zero
                    weight=0.
                    if(dist_grid .lt. dist_screen)  weight=1. 

                    if (cell_ind2 .NE. -1) then  
                       m = dirM_ext(ind_oct, ix, iy, iz)
                       n = dirN_ext(ind_oct, ix, iy, iz)
                       
                       !! and then we iterate around this direction.
                       do mloop = max(1, m-deltam), min(NdirExt_m, m+deltam)
                          do nloop = -deltan1(mloop) -1, deltan2(mloop) -1
                             nl = 1+ mod(n+ nloop+ NdirExt_n, NdirExt_n)       !cyclic value
                             mn = (mloop -1)*NdirExt_n + nl                                 
                             dx_cross_ext = dx_loc*Mdx_ext(ind_oct, ix, iy, iz, mn)   !!! ajouter true/false
                             column_dens(i,mloop,nl) = column_dens(i,mloop,nl) + dx_cross_ext*uold(cell_ind2,1) * weight   
!                             column_dens(i,m,n) = column_dens(i,m,n) + dx_cross_ext*uold(cell_ind2,1)   
!#if NSCHEM != 0
                             !if(myid .EQ. 1) write(*,*) "***VAL: Calculating H2column_dens, neulS+1=", neulS+1, "nH2=", uold(cell_ind2,neulS+1)

!                             H2column_dens(i,mloop,nl) = H2column_dens(i,mloop,nl) + dx_cross_ext*uold(cell_ind2,neulS+1)

                             !PH adapted for the RT with H2 - H2 abundance is : 0.5 ( 1 - XHI -XHII)
                             !question : check about uold(*,1) density or H total abundance (possible issue with He)

#ifdef RT
                              if(isH2) then 
                                 H2column_dens(i,mloop,nl) = H2column_dens(i,mloop,nl) + dx_cross_ext*(uold(cell_ind2,1)-uold(cell_ind2,iIons)-uold(cell_ind2,iIons+1)) / 2.  * weight
                              endif
                             if(isnan(H2column_dens(i,mloop,nl))) write(*,*) "WARNING: CONT",uold(cell_ind2,neulS+1), Mdx_ext(ind_oct, ix, iy, iz, mn), dx_loc, mloop, nloop, nl, mn, m, n, ind_oct
#endif
!#endif
                          end do
                       end do
                    end if                                               ! cell_ind2 .ne. -1
                 end if
                 !++++++++++++++++++++++++++++++++++++++
              end do                 !x
           end do                    !y
        end do                       !z
     end do                          !reg
     
  end do                             !i
  
end subroutine contribution
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! This routine has been modified in order to include the effect of the extinction
!! due to the presence of matter

!PH modifies the name to avoid conflict with calc_temp from previous SAm/frig version
!which does not take into account extinction 
!19/01/2017
!subroutine  calc_temp_extinc(NN,TT,dt_tot_unicode,vcolumn_dens,coeff_chi) 
!modified by PH 3/07/2018 coeff_chi is now stored and is not recalculated 
subroutine  calc_temp_extinc(NN,TT,dt_tot_unicode,coeff_chi) 
  use amr_parameters
  use hydro_commons
  use constants, only:kB
  implicit none
  
  real(dp)                                                   :: NN,TT, dt_tot_unicode,coeff_chi
!  real(dp), dimension(1:NdirExt_m,1:NdirExt_n),intent(inout) :: vcolumn_dens
  
  integer             :: n,i,j,k,idim, iter               
  real(dp)            :: dt, dt_tot, temps, dt_max,extinct
  real(dp)            :: rho,temp
  real(dp)            :: mm,uma, alpha1,mu,kb_mm
  real(dp)            :: TTold, ref,dRefdT, eps, vardt,varrel, dTemp
  real(dp)            :: rhoutot2
  real(dp)            :: scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2
  
  
  ! cgs units are used here
  ! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
  
  if( TT .le. 0.) then 
     TT = 50. / scale_T2
     return
  endif

  vardt = 10.**(1./10.); varrel = 0.2
  
  dt_tot = dt_tot_unicode * scale_t ! * 3.08d18 / sqrt(kb_mm)
  TT     = TT * scale_T2
  
  if (NN .le. smallr) then 
     if( NN .le. 0)  write(*,*) 'prob dens',NN
     NN = smallr  !max(NN,smallr)
  endif
  
  alpha1 = NN*kb/(gamma-1.)
  
  iter = 0 ; temps = 0.
  do while ( temps < dt_tot)

     if (TT .lt.0) then
        write(*,*) 'prob Temp',TT, NN
        !         write(*,*) 'repair assuming isobariticity'
        NN = max(NN,smallr)
        TT = min(4000./NN,8000.)  !2.*4000. / NN 
     endif
     
     TTold = TT       
     
     !NN is assumed to be in cc and TT in Kelvin

     !! here we pass the value of the column density
     
     !PH modifies this as coeff_chi is now stored
     !The '0' represents XH2 which is 0 because H2 is not treated when called from this routine
     call hot_cold_2(TT,NN,ref,dRefDT,coeff_chi,0.d0)    
     !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     
     if (iter == 0) then
        if (dRefDT .ne. 0.) then 
           dt = abs(1.0E-1 * alpha1/dRefDT) 
        else 
           dt = 1.0E-1 * dt_tot 
        endif
        dt_max = dt_tot - temps
        if (dt > 0.7*dt_max) dt = dt_max*(1.+1.0E-12)
     endif
     
     dTemp = ref/(alpha1/dt - dRefdT) 
     
     eps = abs(dTemp/TT)
     if (eps > 0.2) dTemp = 0.2*TTold*dTemp/abs(dTemp)
     
     TT = TTold + dTemp
     if (TT < 0.) then
        write(*,*) 'Temperature negative !!!'
        write(*,*) 'TTold,TT   = ',TTold,TT
        write(*,*) 'rho   = ',rho 
        TT = 100.  !*kelvin
     endif

     iter = iter + 1
     
     temps = temps + dt
     
     dt = vardt*varrel*dt/Max(vardt*eps, varrel)
     
     dt_max = dt_tot - temps
     if (dt > 0.7*dt_max) dt = dt_max*(1.+1.0E-12)
  enddo

  !!now convert temperature in code units
  TT = TT / scale_T2

  return
end subroutine calc_temp_extinc
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! 2012 VV
!! This routine gives the value of the distance crossed inside a cell
!! centered at xcel, of side dx0 in the direction m,n 
!! defined with respect to x0

subroutine get_dx(x0,xcel,m,n,dx0,dx_cross)
  use amr_commons
  use hydro_commons
  use cooling_module
  implicit none

  real(dp),dimension(1:3), intent (in)  :: x0, xcel
  integer, intent (in)                  :: m,n
  real(dp), intent (in)                 :: dx0
  real(dp), intent (out)                :: dx_cross

  real(dp), dimension(3,2)              :: xplane
  real(dp), dimension(2,3)              :: sol                  ! 2 solutions and 2 coordinates per solution
  real(dp), dimension(3)                :: xx

  real(dp)                              :: dx_2,xal1, xal2, solaux
  real(dp), dimension(3)                :: delx
  integer                               :: nfound, i, j, indnf, mod1,mod2


  nfound  = 0
  sol(:,:)= 0.0_dp
  dx_2    = dx0/2.0_dp

  do i=1, 3
     delx(i)     = xcel(i) - x0(i)     ! position of the crossed cell relative to x0(the target)
     xplane(i,1) = delx(i) + dx_2      ! faces of crossed cell 
     xplane(i,2) = delx(i) - dx_2
  end do
    
  ! we write the equations in a cyclic manner in order to have
  ! the same structure. The equation system comes from:
  ! ycos(theta) - zsin(theta)sin(phi) = 0
  ! xcos(theta) - zsin(theta)cos(phi) = 0
  ! xsin(theta)sin(phi) - ysin(theta)cos(phi) = 0
 
  iloop: do i=1, 3
     mod1 = mod13(i)              !just the value of i+1 in modulo 3 (cyclic values)
     mod2 = mod23(i)
     xal1 = xalpha(m,n,i,1)
     xal2 = xalpha(m,n,i,2)

     do j=1, 2                   !Loop for both planes (+/-dx/2)
        xx(i)    = xplane(i,j)   !we set the position in the plane of one of the cell faces 
        xx(mod1) = xal1*xx(i)    !we look for the intersection with the other planes.
        xx(mod2) = xal2*xx(i)
        
        !! we look for any of the 6 planes if the line that passes through the 
        !! point x0 in the direction defined by m,n intersects the cell in the shell.   
        if( (abs( xx(mod1) - delx(mod1) ) .LE. dx_2) .AND. (abs(xx(mod2) - delx(mod2) ) .LE. dx_2) ) then 
           nfound = nfound + 1
           do indnf=1, 3
              sol(nfound, indnf) = xx(indnf)
           end do
        end if
        if(nfound .EQ. 2) EXIT iloop   ! if we have found 2 points we stop
 
     end do
  end do iloop
   
  dx_cross = 0.0_dp

  !! if we find two intersection points we calculate the length of the 
  !! segment crossed through the cell in the shell
  if(nfound .EQ. 2) then
     do i=1, 3
        solaux = (sol(1,i)-sol(2,i))
        dx_cross = dx_cross + solaux*solaux
     end do
  end if
  dx_cross = sqrt(dx_cross)

end subroutine get_dx


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! 2012 VV
!! This routine gives the closest direction m,n to the direction from x0 to x1

subroutine get_mn(x0,x1,m,n)
  use amr_commons
  use hydro_commons
  use cooling_module
  use constants, only:pi
  implicit none

  real(kind= dp),dimension(1:3), intent (in)  :: x0, x1
  integer, intent (out)                       :: m,n
  real(kind= dp)                              :: rr, r, phi, cos_theta, cos_phi, sin_phi

  !! we define the values of the spherical coordinates

  rr= (x1(1)-x0(1))**2 + (x1(2)-x0(2))**2  
  r= rr+(x1(3)-x0(3))**2
  rr = max(sqrt(rr),1.d-20)
  r  = max(sqrt(r),1.d-20)
  cos_theta= (x1(3)-x0(3))/r

  ! the calculation of m is straightforward
  m = min(INT((1.0-cos_theta)*NdirExt_m/2.0) + 1,NdirExt_m)
  
  ! for the calculation of n we have to analyze each case
  if(rr .EQ. 0) then 
     n = 1                       ! the vertical directions are degenerated in phi, then we use 1.
   
  else                           ! otherwise it depends on the values of sin and cos
     cos_phi= (x1(1)-x0(1))/rr
     sin_phi= (x1(2)-x0(2))/rr
     
     if(sin_phi .GE. 0) then
        phi = acos(cos_phi)
     else
        phi = 2.*pi - acos(cos_phi)
     end if

     n =  mod(INT(phi*NdirExt_n/(2.0*pi)+0.5),NdirExt_n) + 1

  end if
  
end subroutine get_mn

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! 2012 VV
!! initialisation for extinction calculation (Valdivia & Hennebelle 2014).
!! This routine precalculates the correction factors.
!! It is called from "adaptative_loop.f90" if in the namelist radiative=.true.
!! Note PH 20/09/2021 changed the name form init_radiative in init_extinction

subroutine init_extinction
  use amr_commons
  use hydro_commons
  use cooling_module
  use constants, only:pi
  implicit none

  ! geometrical corrections
  real(dp)                            :: phi, cos_theta, sin_theta, cos_phi, sin_phi, cos_theta2
  real(dp)                            :: dx_factor
  real(dp), dimension(1:3)            :: xzer, xpar
  integer                             :: m, n, ix, iy, iz, mn
  integer                             :: ind, ind1, ind2, ii, i
  real(dp),dimension(1:twotondim,1:3) :: xc

  allocate(xalpha(1:NdirExt_m, 1:NdirExt_n, 1:3, 1:2) )
  allocate(Mdirection(1:twotondim,1:twotondim),Ndirection(1:twotondim,1:twotondim))
  allocate(Mdx_cross_int(1:NdirExt_m, 1:NdirExt_n), Mdx_cross_loc(1:twotondim,1:twotondim, 1:NdirExt_m, 1:NdirExt_n))
  allocate(Mdx_ext(1:73, 1:11, 1:11, 1:11, 1:(NdirExt_m*NdirExt_n) ))
  allocate(Mdx_ext_logical(1:73, 1:11, 1:11, 1:11, 1:(NdirExt_m*NdirExt_n) ))
  allocate(dirM_ext(1:73, 1:11, 1:11, 1:11), dirN_ext(1:73, 1:11, 1:11, 1:11), dirMN_ext(1:73, 1:11, 1:11, 1:11) )

  Mdx_ext(:,:,:,:,:)=0
  Mdx_ext_logical(:,:,:,:,:)= .false.  
  dirM_ext(:,:,:,:) = 0
  dirN_ext(:,:,:,:) = 0
  dirMN_ext(:,:,:,:) = 0

  do ind=1,twotondim
     iz=(ind-1)/4
     iy=(ind-1-4*iz)/2
     ix=(ind-1-2*iy-4*iz)
     if(ndim>0)xc(ind,1)=(dble(ix)-0.5_dp)
     if(ndim>1)xc(ind,2)=(dble(iy)-0.5_dp)
     if(ndim>2)xc(ind,3)=(dble(iz)-0.5_dp)
  end do

  !----- xalpha for  GET_DX   -----
  do n=1, NdirExt_n
     phi       = 2.0_dp*pi*(n-1)/NdirExt_n
     cos_phi   =  dsign(max(abs(cos(phi)),1D-10),cos(phi))
     sin_phi   =  dsign(max(abs(sin(phi)),1D-10),sin(phi))
     
     do m=1, NdirExt_m
        cos_theta = (1.0_dp-2.0_dp*m)/NdirExt_m +1.0_dp
        cos_theta = dsign(max(abs(cos_theta),1D-10),cos_theta)
        sin_theta = sqrt(1.0_dp -cos_theta**2)

        xalpha(m,n,1,1) = sin_phi/cos_phi
        xalpha(m,n,1,2) = cos_theta/(cos_phi*sin_theta)
        xalpha(m,n,2,1) = cos_theta/(sin_phi*sin_theta)
        xalpha(m,n,2,2) = cos_phi/sin_phi
        xalpha(m,n,3,1) = cos_phi*sin_theta/cos_theta
        xalpha(m,n,3,2) = sin_phi*sin_theta/cos_theta

     end do
  end do

  ! Precalculation of function modulo 3
  do i=0, 2
     mod13(i+1)    = 1 + mod(i+1,3)
     mod23(i+1)    = 1 + mod(i+2,3)
  end do

  !-----   CALCULATION OF GEOMETRICAL CORRECTIONS   -----
  ! the correction factors are calculated for a cell of side 1
  ! the value of dx_crossed at each level can be calculated by
  ! multiplying the correction factor by dx
  
  ! Internal and Local corrections----------------------------
  do ind=1,twotondim
     xzer(1) = xc(ind,1)
     xzer(2) = xc(ind,2)
     xzer(3) = xc(ind,3)
     do n = 1,NdirExt_n
        do m = 1,NdirExt_m
           call get_dx(xzer,xzer,m,n,1.0_dp,dx_factor)        
           Mdx_cross_int(m,n) = dx_factor/2.0_dp   
        end do
     end do
     do ii=1,twotondim
        if(ii .NE. ind) then
           xpar(1) = xc(ii,1)
           xpar(2) = xc(ii,2)
           xpar(3) = xc(ii,3)
           call get_mn(xzer,xpar, m,n)
           Mdirection(ind,ii) = m
           Ndirection(ind,ii) = n
           do n=1,NdirExt_n
              do m=1,NdirExt_m  
                 call get_dx(xzer,xpar,m,n,1.0_dp,dx_factor)
                 Mdx_cross_loc(ind,ii,m,n) = dx_factor
              end do
           end do
        end if
     end do
  end do
  
  ! External corrections
  !xzer is the cell position where we want to calculate the contribution
  !to the screening caused by the surrounding cells
  !ind  1 to 64 : position of a cell in a ilevel -3 configuration
  !ind 65 to 72 :                         ilevel -2
  !ind     = 73 :                         ilevel -1

  do ind1=1, 9
     ind = 64 + ind1
     ! if(myid .EQ. 1)write(*,*) ind1, ind
     if(ind1 .EQ. 9) then
        xzer(:) = 0.0_dp      !position of the center of the oct
     else
        xzer(1) = 0.5_dp*xc(ind1,1)  !position of a cell in the oct
        xzer(2) = 0.5_dp*xc(ind1,2)  !xc=0.5 et xzer=0.25
        xzer(3) = 0.5_dp*xc(ind1,3)
     end if

     !Here we take into account the surrounding cells. We consider
     !+-5 cells from xzer in each direction. -6 is to avoid negative index
     do iz=1, 11
        xpar(3) = REAL(iz) - 6.0_dp        !-5,...,+5
        do iy=1, 11
           xpar(2) = REAL(iy) - 6.0_dp
           do ix=1, 11
              xpar(1) = REAL(ix) - 6.0_dp

              !+++ 04/02/2013
              call get_mn(xzer,xpar, m,n)
              dirM_ext(ind,ix,iy,iz) = m
              dirN_ext(ind,ix,iy,iz) = n
              dirMN_ext(ind,ix,iy,iz) = (m -1)*NdirExt_n + n

              do n=1, NdirExt_n
                 do m=1, NdirExt_m
                    call get_dx(xzer, xpar, m, n, 1.0_dp,dx_factor)
                    mn = (m-1)*NdirExt_n + n
                    Mdx_ext(ind,ix,iy,iz,mn) = dx_factor
                    if(dx_factor .GT. 0) Mdx_ext_logical(ind,ix,iy,iz,mn) = .true.
                    ! if (myid .EQ. 1)write(*,*)ind, ix,iy,iz,m,n, dx_factor
                 end do
              end do
           end do
        end do
     end do
  end do

  do ind1=1,8
     do ind2=1,8

        ind = (ind1-1)*8 + ind2    !ind 1 to 64

        !position of a cell in a grid of level ilevel-3
        xzer(1) = 0.5_dp*xc(ind1,1) + 0.25_dp*xc(ind2,1)
        xzer(2) = 0.5_dp*xc(ind1,2) + 0.25_dp*xc(ind2,2)
        xzer(3) = 0.5_dp*xc(ind1,3) + 0.25_dp*xc(ind2,3)
        do iz=1, 11
           xpar(3) = REAL(iz) - 6.0_dp
           do iy=1, 11
              xpar(2) = REAL(iy) - 6.0_dp
              do ix=1, 11
                 xpar(1) = REAL(ix) - 6.0_dp

                 !+++ 04/02/2013: 
                 call get_mn(xzer,xpar, m,n)
                 dirM_ext(ind,ix,iy,iz) = m
                 dirN_ext(ind,ix,iy,iz) = n
                 dirMN_ext(ind,ix,iy,iz) = (m -1)*NdirExt_n + n
 

                 do n=1, NdirExt_n
                    do m=1, NdirExt_m
                       call get_dx(xzer, xpar, m, n, 1.0_dp,dx_factor)
                       mn = (m-1)*NdirExt_n + n
                       Mdx_ext(ind,ix,iy,iz,mn) = dx_factor
                       if(dx_factor .GT. 0) Mdx_ext_logical(ind,ix,iy,iz,mn) = .true.
                    end do   !m
                 end do      !n
              end do         !ix
           end do            !iy
        end do               !iz
     end do                  !ind2
  end do                     !ind1

end subroutine init_extinction
!=====================================================================================================
!=====================================================================================================
!=====================================================================================================
!=====================================================================================================
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!! 2012 VV Modified to include the extinction
!subroutine hot_cold_2(T,n,ref,dRefDT,vcolumn_dens,sc_l,coeff_chi)    
!PH modifies this as coeff_chi is now stored 
!these routines have been modified by Benjamin Godard
subroutine hot_cold_2(T,n,ref,dRefDT,coeff_chi,XH2)    
  use amr_parameters
#ifdef RT
  use rt_parameters,only: isH2,iIons
#endif
  implicit none
  
  real(dp), intent (in)    :: T,n
  real(dp), intent (inout) :: coeff_chi
  real(dp), intent (out)   :: ref,dRefDT

  real(dp)                 :: G0,zeta_p,phi_pah,x_cp,x_o,eps
  real(dp)                 :: T_1,T_2,ne_1,ne_2,x_1,x_2
  real(dp)                 :: cold_cII_1,cold_o_1,cold_h_1,cold_rec_1,cold_1
  real(dp)                 :: cold_cII_2,cold_o_2,cold_h_2,cold_rec_2,cold_2
  real(dp)                 :: hot_ph_1,hot_ph_2,hot_cr,hot_1,hot_2
  real(dp)                 :: ref_1,ref_2

  real(dp)                 :: XH2
  real(dp)                 :: x_cO=0.,cold_mol_1=0.,cold_mol_2=0.

  ! ======================================================================================
  ! 1 - Definition of the local UV field 
  !                       local C+ and O fraction
  !                       local electronic fraction 
  !     UV field is expressed in Habing unit (1.274e-4 erg cm-2 s-1 sr-1)
  !     p_UV is a scaling parameter defined in the namelist
  !     the shielding coefficient is computed using Valeska's method
  ! ======================================================================================
  G0 = 1.0_dp * p_UV

  ! uncomment the following line to remove the shielding from
  ! computation of the electron fraction and photoelectric effect
  !PH commented this 1/03/2019
  !coeff_chi  = 1.0_dp

  IF (extinction) THEN
     G0 = G0*coeff_chi
  ENDIF

  ! ---------------------------------------------------
  ! C+ and O fraction
  ! - We assume that all Carbon is in ionized form 
  !   with a depletion onto grains of 0.40 => 1.4e-4 (Wolfire et al. 2003, Tab. 1)
  ! - We assume that all Oxygen is in atomic  form 
  !   with a depletion onto grains of 0.37 => 3.2e-4 (Wolfire et al. 2003, Tab. 1)
  ! ---------------------------------------------------
  x_cp = 3.5e-4_dp * 0.40_dp
  x_o  = 8.6e-4_dp * 0.37_dp

#ifdef RT
  if(isH2) then
     !calculate CO abundance using a simple prescription and recalculate the x_cp abundance
     CALL compute_Cp_CO_NL(n,XH2,G0,x_o,x_cp,x_co)
  endif
#endif

  ! ---------------------------------------------------
  ! ionization and PAH recombination parameter
  ! set to use the formalism of Wolfire et al. (2003)
  ! ---------------------------------------------------
  zeta_p  = 2.0_dp
  phi_pah = 0.5_dp

  ! ---------------------------------------------------
  ! temperatures at which cooling & heating are estimated 
  ! ---------------------------------------------------
  T_1 = T
  eps = 1.0e-5_dp
  T_2 = T * (1.0_dp + eps)

  ! ---------------------------------------------------
  ! electron density and electronic fraction
  ! ---------------------------------------------------
  CALL ELEC_DENS(zeta_p, G0, T_1, phi_pah, x_cp, N, ne_1)
  CALL ELEC_DENS(zeta_p, G0, T_2, phi_pah, x_cp, N, ne_2)
  x_1 = ne_1 / N
  x_2 = ne_2 / N

  ! ======================================================================================
  ! 2 - set the cooling functions
  !     a - hyperfine transitions at small temperature of CII and OI
  !         metastable lines of CII and OI (NOT USED)
  !     b - H cooling by excitation of its electronic lines
  !     c - cooling by recombination on positively charged grains
  ! ======================================================================================

  CALL COOL_CP(T_1, x_cp, x_1, cold_cII_1)
  CALL COOL_CP(T_2, x_cp, x_2, cold_cII_2)

  CALL COOL_O(T_1, x_o, cold_o_1)
  CALL COOL_O(T_2, x_o, cold_o_2)

  cold_h_1 = 0d0
  cold_h_2 = 0d0
  !if rt this cooling is taken into account in the rt module
  if (.not. rt) then
     CALL COOL_H(T_1, x_1, cold_h_1)
     CALL COOL_H(T_2, x_2, cold_h_2)
  endif

  CALL COOL_REC(G0, T_1, phi_pah, x_1, N, cold_rec_1)
  CALL COOL_REC(G0, T_2, phi_pah, x_2, N, cold_rec_2)

#ifdef RT
  if(isH2) then
  !calculate molecular cooling - in principle no need for RT and isH2 but for the sake of coherence
  !it is required for now - can be changed
  CALL cool_goldsmith(T_1,N,cold_mol_1)
  CALL cool_goldsmith(T_2,N,cold_mol_2)
  endif
#endif

  if(isnan(cold_cII_1) .or. isnan(cold_cII_2) ) then
     write(*,*) 'cold_cII',cold_cII_1,cold_cII_2
  endif

  if(isnan(cold_o_1) .or. isnan(cold_o_2) ) then
     write(*,*) 'cold_o',cold_o_1,cold_o_2
  endif

  if(isnan(cold_rec_1) .or. isnan(cold_rec_2) ) then
     write(*,*) 'cold_rec',cold_rec_1,cold_rec_2
  endif

  if(isnan(cold_mol_1) .or. isnan(cold_mol_2) ) then
     write(*,*) 'cold_mol',cold_mol_1,cold_mol_2
  endif  
  ! Sum all cooling functions
  cold_1 = cold_cII_1  + cold_o_1 + cold_h_1 + cold_rec_1 + cold_mol_1
  cold_2 = cold_cII_2  + cold_o_2 + cold_h_2 + cold_rec_2 + cold_mol_2

  ! ======================================================================================
  ! 3 - set the heating rates
  !     a - photoelectric effect
  !     b - cosmic rays (for dark cloud cores, Goldsmith 2001, Eq. 3)
  ! ======================================================================================

  CALL HEAT_PH (G0, T_1, phi_pah, x_1, N, hot_ph_1)
  CALL HEAT_PH (G0, T_2, phi_pah, x_2, N, hot_ph_2)

  if(isnan(hot_ph_1) .or. isnan(hot_ph_2) ) then
     write(*,*) 'hot_ph',hot_ph_1,hot_ph_2
  endif  

  
  !corrected CR as value seems to be much higher than orif-ginally estimated (McCall+2003)
  hot_cr = 5.0E-27_dp

  ! Sum all heating functions
  hot_1 = hot_ph_1 + hot_cr
  hot_2 = hot_ph_2 + hot_cr

  ! ======================================================================================
  ! 4 - compute the net heating rate (in erg cm-3 s-1) and the output variables
  ! ======================================================================================
  ref_1 = n * hot_1 - n**2.0_dp * cold_1
  ref_2 = n * hot_2 - n**2.0_dp * cold_2

  ref    = ref_1
  dRefDT = (ref_2-ref_1) / T / eps

end subroutine hot_cold_2

SUBROUTINE ELEC_DENS(zeta_p, G0_p, T, phi, xcp, nH, ne)
    !---------------------------------------------------------------------------
    ! Compute the local electron density based on Wolfire et al. (2003, eq. C9) 
    ! and adding to this equation the abundance of C+
    ! input variables :
    !     zeta_p -> ionization parameter (in units of 1.3e-16 s-1)
    !     G0_p   -> local UV radiation field (in Habing unit)
    !     T      -> local temperature
    !     phi    -> PAH recombination factor
    !     xcp    -> C+ abundance (relative to nH)
    !     nH     -> proton density
    ! output variables :
    !     ne     -> electron density (in cm-3)
    !---------------------------------------------------------------------------
    USE amr_parameters, only:dp
    IMPLICIT none

    REAL (KIND=dp), INTENT(IN)  :: zeta_p,G0_p,T,phi,xcp,nH
    REAL (KIND=dp), INTENT(OUT) :: ne

    ! Careful. The formula of Wolfire is given as functions of parameters which 
    ! are scaling of those used in their standard model of the solar neighbourghood 
    ! ===> in this model G0 = 1.7 (in Habing units)
    ne = 2.4e-3_dp * (zeta_p)**0.5_dp * (T/100_dp)**0.25_dp * (G0_p/1.7)**0.5_dp / phi + xcp * nH

    ! limit the electron fraction to 0.1 to get closer to Wolfire results (Fig. 10 top panels)
    ne = min(ne,0.1*nH)

END SUBROUTINE ELEC_DENS

SUBROUTINE COOL_CP(T, xcp, xe, cool)
    !---------------------------------------------------------------------------
    ! Compute the cooling rate due to the hyperfine 
    ! (and metastable - NOT USED HERE) lines of C+
    ! input variables :
    !     T    -> local temperature
    !     xcp  -> C+ abundance (relative to nH)
    !     xe   -> e- abundance (relative to nH)
    ! output variables :
    !     cool -> cooling rate (erg cm3 s-1) 
    !---------------------------------------------------------------------------
    USE amr_parameters, only:dp
    IMPLICIT none

    REAL (KIND=dp), INTENT(IN)  :: T,xcp,xe
    REAL (KIND=dp), INTENT(OUT) :: cool

    ! Ref : Wolfire et al. (2003, Eq. C1 & C2)
    cool = ( 2.25e-23_dp + 1.0e-20_dp * (T/100.0_dp)**(-0.5_dp) * xe ) * exp(-92.0_dp / T) * xcp

END SUBROUTINE COOL_CP

SUBROUTINE COOL_O(T, xo, cool)
    !---------------------------------------------------------------------------
    ! Compute the cooling rate due to the hyperfine 
    ! (and metastable - NOT USED HERE) lines of O
    ! input variables :
    !     T    -> local temperature
    !     xo   -> O abundance (relative to nH)
    ! output variables :
    !     cool -> cooling rate (erg cm3 s-1) 
    !---------------------------------------------------------------------------
    USE amr_parameters, only:dp
    IMPLICIT none

    REAL (KIND=dp), INTENT(IN)  :: T,xo
    REAL (KIND=dp), INTENT(OUT) :: cool

    ! Ref : Wolfire et al. (2003, Eq. C3)
    cool = 7.81e-24_dp * (T/100.0_dp)**(0.4_dp) * exp(-228.0_dp/T) * xo

END SUBROUTINE COOL_O

SUBROUTINE COOL_H(T, xe, cool)
    !---------------------------------------------------------------------------
    ! Compute the cooling rate due to the electronic lines of H
    ! Ref : taken from Spitzer (1978)
    ! input variables :
    !     T    -> local temperature
    !     xe   -> e- abundance (relative to nH)
    ! output variables :
    !     cool -> cooling rate (erg cm3 s-1) 
    !---------------------------------------------------------------------------
    USE amr_parameters, only:dp
    IMPLICIT none

    REAL (KIND=dp), INTENT(IN)  :: T,xe
    REAL (KIND=dp), INTENT(OUT) :: cool

    cool = 7.3e-19_dp * xe * exp(-118400.0_dp / T)

END SUBROUTINE COOL_H

!TC: carefull, this is also defined in cooling_module.f90
SUBROUTINE COOL_REC(G0_p, T, phi, xe, nH, cool)
    !---------------------------------------------------------------------------
    ! Compute the cooling rate due to the recombination
    ! of electrons on positively charged PAH
    ! input variables :
    !     G0_p -> local UV radiation field (Draine's unit)
    !     T    -> local temperature
    !     phi  -> PAH recombination factor
    !     xe   -> e- abundance (relative to nH)
    !     nH   -> proton density
    ! output variables :
    !     cool -> cooling rate (erg cm3 s-1) 
    !---------------------------------------------------------------------------
    USE amr_parameters, only:dp
    IMPLICIT none

    REAL (KIND=dp), INTENT(IN)  :: G0_p,T,phi,xe,nH
    REAL (KIND=dp), INTENT(OUT) :: cool
    REAL (KIND=dp)              :: param,bet

    if(xe .ne. 0) then
       param = G0_p * sqrt(T) / (nH * xe * phi)
    else
       param = 0.
    endif
    bet   = 0.74_dp / (T**0.068_dp)

    ! Ref : Wolfire et al. (2003, Eq. 21)
    cool = 4.65e-30_dp * T**0.94_dp * param**bet * xe * phi

END SUBROUTINE COOL_REC

SUBROUTINE HEAT_PH(G0_p, T, phi, xe, nH, heat)
    !---------------------------------------------------------------------------
    ! Compute the heating rate due to the photoelectric effect
    ! Ref : Wolfire et al. (2003, Eqs. 19 & 20)
    ! input variables :
    !     G0_p -> local UV radiation field (in Habing units)
    !     T    -> local temperature
    !     phi  -> PAH recombination factor
    !     xe   -> e- abundance (relative to nH)
    !     nH   -> proton density
    ! output variables :
    !     heat -> cooling rate (erg cm3 s-1) 
    !---------------------------------------------------------------------------
    USE amr_parameters, only:dp
    IMPLICIT none

    REAL (KIND=dp), INTENT(IN)  :: G0_p,T,phi,xe,nH
    REAL (KIND=dp), INTENT(OUT) :: heat
    REAL (KIND=dp)              :: param,epsilon

    if(xe .ne. 0) then
       param = G0_p * sqrt(T) / (nH * xe * phi)
    else
       param = 0.
    endif

    epsilon = 4.9e-2_dp / ( 1.0_dp + (param / 1925.0_dp)**0.73_dp ) &
            + 3.7e-2_dp / ( 1.0_dp + (param / 5000.0_dp)          ) * (T / 1.0e4_dp)**0.7_dp

    heat = 1.3E-24 * epsilon * G0_p

END SUBROUTINE HEAT_PH
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!calculate the extinction
!! 21/11/2017
!!PH adapts the cooling_fine adapted by Benoit from Valeska's original routine
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
subroutine extinction_fine(ilevel)
  use amr_commons
  use hydro_commons
  use cooling_module

  implicit none
#ifndef WITHOUTMPI
  include 'mpif.h'
#endif
  integer::ilevel
  !-------------------------------------------------------------------
  ! Compute extinction for fine levels
  !-------------------------------------------------------------------
  integer::ncache,i,igrid,ngrid,info
  integer,dimension(1:nvector),save::ind_grid
  real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v
  ! files
  character(LEN=5)                    :: nsort, nocpu
  character(LEN = 80)                 :: filenamex,filenamey,filenamez
  integer::uleidx,uleidy,uleidz

  if(numbtot(1,ilevel)==0)return
  if(verbose)write(*,111)ilevel

  ! Valeska
  !--------------------------------------------------------------------
  ! The write option permits us to construct a column density map projected 
  ! in x, y, and z by calculating the column densities along positive and 
  ! negative directions with respect to a slice that passes through the 
  ! respective mid planes.
  !--------------------------------------------------------------------
  if(writing) then
     call title(ifout-1, nsort)
     call title(myid, nocpu)
     filenamex= TRIM(nsort)//'_test_densX_'//TRIM(nocpu)//'.dat'        !ex.:00001_test_densX_00010.dat
     filenamey= TRIM(nsort)//'_test_densY_'//TRIM(nocpu)//'.dat'
     filenamez= TRIM(nsort)//'_test_densZ_'//TRIM(nocpu)//'.dat'
     
     uleidx = myid + 100                                                !integer
     uleidy = myid + 200
     uleidz = myid + 300
     
     open(unit=uleidx, file=filenamex, form='formatted', status='unknown',position='append')
     open(unit=uleidy, file=filenamey, form='formatted', status='unknown',position='append')
     open(unit=uleidz, file=filenamez, form='formatted', status='unknown',position='append')
  end if
  !--------------------------------------------------------------------
  ! Valeska

  ! Operator splitting step for cooling source term
  ! by vector sweeps
  ncache=active(ilevel)%ngrid
  do igrid=1,ncache,nvector
     ngrid=MIN(nvector,ncache-igrid+1)
     do i=1,ngrid
        ind_grid(i)=active(ilevel)%igrid(igrid+i-1)
     end do
     call extinctionfine1(ind_grid,ngrid,ilevel)
  end do

  
111 format('   Entering extinction_fine for level',i2)

end subroutine extinction_fine
!###########################################################
!###########################################################
!###########################################################
!###########################################################
subroutine extinctionfine1(ind_grid,ngrid,ilevel)
  use amr_commons
  use hydro_commons
  use cooling_module
  use hydro_parameters

#ifdef RT
  use rt_parameters,only: isH2,iIons
#endif 
  
  implicit none
#ifndef WITHOUTMPI
  include 'mpif.h'
#endif
  integer::ilevel,ngrid
  integer,dimension(1:nvector)::ind_grid
  !-------------------------------------------------------------------
  !-------------------------------------------------------------------
  integer::i,ind,iskip,idim,nleaf,nx_loc,ix,iy,iz,info
  real(dp)::scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v
  real(kind=8)::dtcool,nISM,nCOM,damp_factor,cooling_switch,t_blast
  real(dp)::polytropic_constant
  integer,dimension(1:nvector),save::ind_cell,ind_leaf,ind_leaf_loc
  real(kind=8),dimension(1:nvector),save::nH,T2,T2_new,delta_T2,ekk,err,emag
  real(kind=8),dimension(1:nvector),save::T2min,Zsolar,boost
  real(dp),dimension(1:3)::skip_loc
  real(kind=8)::dx,dx_loc,scale,vol_loc
  integer::irad

  real(dp) :: barotrop1D,mincolumn_dens
  real(dp)                                   :: x0, y0, z0,coeff_chi,coef
  double precision                           :: v_extinction,extinct
  integer::uleidx,uleidy,uleidz,uleidh,igrid,ii,indc2,iskip2,ind_ll

  real(dp),dimension(1:twotondim,1:3)        :: xc                                               !xc: coordinates of center/center grid

  !-------------- SPHERICAL DIRECTIONS ------------------------------------------------!
!  real(dp),dimension(1:nvector,1:ndir)                 :: col_dens                     !
  real(dp),dimension(1:nvector,1:NdirExt_m,1:NdirExt_n):: column_dens,column_dens_loc  !
  real(dp),dimension(1:nvector,1:NdirExt_m,1:NdirExt_n):: H2column_dens,H2column_dens_loc  ! H2 column density
!  real(dp),dimension(ndir)                             :: vcol_dens                    !
  real(dp),dimension(1:NdirExt_m,1:NdirExt_n)          :: vcolumn_dens
  real(dp),dimension(1:3)                              :: xpos
  real(dp)                                             :: dx_cross_int, dx_cross_loc
  integer                                              :: index_m,index_n, mmmm,nnnn
  integer                                              :: m, n, mloop, nloop, nl   
  integer, dimension(1:NdirExt_n)                      :: deltan1, deltan2
  integer                                              :: deltam
  !-----   simple_chem   --------------------------------------------------------------!
  real(dp)                                             :: xshield, fshield, kph, m_kph, b5   ! cgs                                                 
  real(dp)                                             :: small_exp=1d-10, e_valexp, small_arg=-20.0_dp
  real(dp)                                             :: cst1 = -8.5d-4, one=1.0, cst2, coeff, valexp
  real(dp)                                             :: mH2 = 3.347449d-24           ! g                                                         
  real(dp)                                             :: kbcgs  =  1.380658d-16       ! erg/degre                                                 
  real(dp)                                             :: bturb = 2d5    
     ! 2km/s (Maryvonne Gerin, Jacques Le Bourlot, Pierre Lesaffre) 1:Gnedin+2009 !7.1d5(Krumholz2012)
  real(kind=8),dimension(1:nvector),save::nH2
  !!take care "nener" should be added here. It is fine if it is 0 of course 
  integer                                               :: neulS=8+nextinct
  !------------------------------------------------------------------------------------!

  !Valeska
  column_dens(:,:,:) = 0.
  H2column_dens(:,:,:) = 0.
  vcolumn_dens(:,:) = 0.

  
  if(writing) then
     !---position of reference to calculate the column density maps---
     ! we add 1.0D-09 in order to avoid the exact center (there are not cells centered in 0.5L)
     x0 = 0.5D0 + 1.0D-09
     y0 = 0.5D0 + 1.0D-09
     z0 = 0.5D0 + 1.0D-09
     
     !---Units uleidx, uleidy, uleidz---
     uleidx = myid + 100
     uleidy = myid + 200
     uleidz = myid + 300
  end if
  
294 FORMAT(I10,4ES14.5) 
295 FORMAT(5ES14.5)   
296 FORMAT(I10,5ES14.5)                
  
  if(numbtot(1,ilevel)==0)return
  
  !get the column density within the box from the grid faces

  !-----   EXTERNAL CONTRIBUTION   -----
  call column_density(ind_grid,ngrid,ilevel,column_dens,H2column_dens) 
  !Valeska

  ! Mesh spacing in that level
  dx=0.5D0**ilevel
  nx_loc=(icoarse_max-icoarse_min+1)
  skip_loc=(/0.0d0,0.0d0,0.0d0/)
  if(ndim>0)skip_loc(1)=dble(icoarse_min)
  if(ndim>1)skip_loc(2)=dble(jcoarse_min)
  if(ndim>2)skip_loc(3)=dble(kcoarse_min)
  scale=boxlen/dble(nx_loc)
  dx_loc=dx*scale
  vol_loc=dx_loc**ndim

  ! Conversion factor from user units to cgs units
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

  !scaling coefficent between column density and Av 
  coef = 2.d-21 * scale_l * boxlen       !cm^2; Eq.34 Glover & Mac Low 2007


  !--- Set position of cell centers relative to grid center ---
  do ind=1,twotondim
     iz=(ind-1)/4                               !0 for ind=1,2,3,4; 1 for ind=5,6,7,8
     iy=(ind-1-4*iz)/2
     ix=(ind-1-2*iy-4*iz)
     if(ndim>0)xc(ind,1)=(dble(ix)-0.5_dp)*dx   
     if(ndim>1)xc(ind,2)=(dble(iy)-0.5_dp)*dx
     if(ndim>2)xc(ind,3)=(dble(iz)-0.5_dp)*dx
  end do

!******************************************************

  !---  PRECALCULATION of  m, n loop limits  ------------------------------------------
  ! each cell can contribute to the column density in several directions, then
  ! we define here the limits for the loop around the direction to the cell center.
  ! For the vertical directions (m =1, NdirExt_m), the azimuthal angle has to cover 2*pi,
  ! for other directions we use +/- 1/8 of the total directions 
  !-------------------------------------------------------------------------------------
     do m = 1, NdirExt_m
        if(m .EQ. 1 .OR. m .EQ. NdirExt_m) then
           deltan1(m) = INT(NdirExt_n/2.0_dp)
           deltan2(m) = deltan1(m) -1
        else
           deltan1(m) = INT(NdirExt_n/8)
           deltan2(m) = deltan1(m)
        end if
     end do
     deltam = INT((NdirExt_m-1)/4.)


  ! Loop over cells
  do ind=1,twotondim
     iskip=ncoarse+(ind-1)*ngridmax
     do i=1,ngrid
        ind_cell(i)=iskip+ind_grid(i)
     end do

     ! Gather leaf cells
     nleaf=0
     do i=1,ngrid
        if(son(ind_cell(i))==0)then
           nleaf=nleaf+1
           ind_leaf(nleaf)=ind_cell(i)
           ind_leaf_loc(nleaf)=i       !index within local group of cells
        end if
     end do
     if(nleaf.eq.0)cycle

     ! Compute rho
     do i=1,nleaf
        nH(i)=MAX(uold(ind_leaf(i),1),smallr)
     end do


#if NEXTINCT>1
#ifdef RT
     if(isH2) then 
        do i=1,nleaf
           nH2(i) = (uold(ind_leaf(i),1) - uold(ind_leaf(i),iIons) - uold(ind_leaf(i),iIons+1)) / 2.  
           nH2(i)=MAX(nH2(i),smallr)
        end do
     endif
#endif
#endif

#if NEXTINCT>1
     do i=1,nleaf                                  !loop over leaf cells 
        ind_ll=ind_leaf_loc(i)
        
        igrid=ind_grid(ind_leaf_loc(i))            !index father  
        
        xpos(1) = xg(igrid,1) + xc(ind,1)          !grid position + leaf position relative to grid center
        xpos(2) = xg(igrid,2) + xc(ind,2)
        xpos(3) = xg(igrid,3) + xc(ind,3)
               
                   
           !------     +  INTERNAL CONTRIBUTION        ------
           ! Here we sum up the contribution due to the cell itself. Its 1/2 in each direction.
           
           do index_n=1,NdirExt_n      !loop over directions to compute the screaning of half the cells on itself 
              do index_m=1,NdirExt_m 
                 
                 column_dens_loc(ind_ll,index_m,index_n) = column_dens(ind_ll,index_m,index_n) + dx*Mdx_cross_int(index_m,index_n)*nH(i)
#if NEXTINCT>1
#ifdef RT
                 !PH adapted for the RT with H2 - H2 abundance is : 0.5 ( 1 - XHI -XHII)
                 !question : check about uold(*,1) density or H total abundance (possible issue with He)
                 if(isH2) then 
                    H2column_dens_loc(ind_ll,index_m,index_n) = H2column_dens(ind_ll,index_m,index_n) + dx*Mdx_cross_int(index_m,index_n)*nH2(i)
                 endif

#endif
#endif
                 !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~         
                 ! column_dens_loc(ind_ll,index_m,index_n) = dx*Mdx_cross_int(index_m,index_n)*nH(i) !if just internal contribution is needed
                 ! column_dens_loc(ind_ll,index_m,index_n) = column_dens(ind_ll,index_m,index_n)  !if just the external component is needed
                 !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
              end do
           end do
           
           !-------     + LOCAL CONTRIBUTION     -----
           ! and here we add the contributon due to its siblings (in the same oct).
           
           do ii=1,twotondim    !1-8 the cell in the oct! 
              if(ii .NE. ind) then
                 
                 iskip2  = ncoarse+(ii-1)*ngridmax 
                 indc2   = iskip2+ ind_grid(ind_ll) !indice for the cell crossed along the direction ind_dir
                 
                 !--------------------------------------------------  
                 !  !we calculate the position of the cell crossed
                 !  xcell(1)= xg(igrid,1) + xc(ii,1)
                 !  xcell(2)= xg(igrid,2) + xc(ii,2)
                 !  xcell(3)= xg(igrid,3) + xc(ii,3)
                 !  call get_mn(xpos, xcell, m, n)
                 !  if(m .NE. Mdirection(ind,ii) .OR. n .NE. Ndirection(ind,ii)) write(*,*) ind,ii
                 !  if(myid .EQ.1 .AND. ii .EQ. 8  ) write(*,*) ind, i, ii, "     m,n:", m, n
                 !-------------------------------------------------

                 ! knowing the index of the target cell and the sibling cell we can find 
                 ! the closest direction from the target cell center to the sibling cell center.
                
                 m = Mdirection(ind,ii)
                 n = Ndirection(ind,ii)
                 
                 ! Here we make a loop around the direction m,n in order to treat all the 
                 ! concerned directions by the sibling cell
                 
                 do mloop = max(1, m-deltam), min(NdirExt_m, m+deltam)  !avoid forbidden intervals
                    do nloop = -deltan1(mloop) -1, deltan2(mloop) -1
                       ! the value of nloop is cyclic
                       nl = 1+ mod(n+ nloop+ NdirExt_n, NdirExt_n)
                       
                       ! Here we sum up the contribution to the column density. The distance crossed
                       ! through the cell can be found using the corrective factor Mdx_cross_loc, that
                       ! depends on the relative positions in the oct and on the direction
                       
                       column_dens_loc(ind_ll,mloop,nl) = column_dens_loc(ind_ll,mloop,nl) + dx*Mdx_cross_loc(ind,ii,mloop,nl)*uold(indc2,1)        
#if NEXTINCT>1
#ifdef RT

                       if(isH2) then 
                          H2column_dens_loc(ind_ll,mloop,nl) = H2column_dens_loc(ind_ll,mloop,nl) + dx*Mdx_cross_loc(ind,ii,mloop,nl)*(uold(indc2,1)- uold(indc2,iIons)- uold(indc2,iIons+1))*0.5
                       endif
#endif
#endif
                    end do
                 end do
                 
              end if      !ii ne ind
           end do         !ii
  
           !--- HERE THE VALUE IN COLUMN_DENS_LOC IS THE TOTAL VALUE ---

           !-- WRITE FILES for a test ---        
           if(writing .and. mod(nstep_coarse,foutput)==0) then
              
              ! we calculate here the value of the extinction just to write the files. This value is not used here and its calculated after.

              v_extinction=0.
              do index_m=1,NdirExt_m
                 do index_n=1,NdirExt_n
                    v_extinction= v_extinction+ exp(-column_dens_loc(ind_ll,index_m,index_n)*coef)
                 end do
              end do
              v_extinction= v_extinction/(NdirExt_m*NdirExt_n)
              
              ! we calculate the closest directions to the +/- cartesian directions 
              mmmm=NINT((NdirExt_m-1.)/2.)+1     ! (5-1)/2 +1 = 3 ok
              nnnn=NINT(NdirExt_n/2.)+1          !     8/2 +1 = 5 ok  

              if(abs(xpos(1)-x0) .LT. 0.5*dx) write(uleidx,296) ilevel, xpos(2), xpos(3), column_dens_loc(ind_ll,mmmm,1), column_dens_loc(ind_ll,mmmm,NdirExt_n/2+1), v_extinction   !Write column density
              if(abs(xpos(2)-y0) .LT. 0.5*dx) write(uleidy,296) ilevel, xpos(1), xpos(3), column_dens_loc(ind_ll,mmmm,NdirExt_n/4+1), column_dens_loc(ind_ll,mmmm,3*NdirExt_n/4+1), v_extinction
              if(abs(xpos(3)-z0) .LT. 0.5*dx) write(uleidz,296) ilevel, xpos(1), xpos(2), column_dens_loc(ind_ll,1,1), column_dens_loc(ind_ll,NdirExt_m,nnnn), v_extinction 
              
           end if

           do index_m=1,NdirExt_m
              do index_n=1,NdirExt_n
                 vcolumn_dens(index_m,index_n)=column_dens_loc(ind_ll,index_m,index_n)          
              end do
           end do

           !---  we calculate the extinction using the column density   ----
           extinct=0.0_dp
           
           !! Loop in theta and phi 
           do index_m=1,NdirExt_m
              do index_n=1,NdirExt_n
                 ! now take the exponential and sum over directions 
                 extinct = extinct + exp(-vcolumn_dens(index_m,index_n)*coef) 
              end do
           end do
           coeff_chi  = extinct/(NdirExt_m*NdirExt_n)

           !it is assumed (see init_hydro and output_hydro that extinction variables are stored between
           ! nvar-nextinct+1 and nvar 
           uold(ind_leaf(i),nvar) = coeff_chi

#if NEXTINCT>1
           cst2 = scale_l* boxlen
           coeff = -2.d-21*cst2  !-1.3d-21*cst2   
           ind_ll=ind_leaf_loc(i)
           kph = 0.0
           m_kph = 0.0
           do index_m=1,NdirExt_m
              do index_n=1,NdirExt_n
                 xshield = max(H2column_dens_loc(ind_ll,index_m,index_n)*cst2/(5d14),0.)   !Glover & MacLow 2007, Eq (32)                                  
                 if(isnan(xshield)) write(*,*) "WARNING: xshield is NaN", index_m, index_n, H2column_dens_loc(ind_ll,index_m,index_n)
                 !--------------------------------------------------------                                                                         
                 !!!-----   Now it is not possible to use bthermal   -----                                                                         
                 !!---- Doppler parameter using bturb and bthermal--------                                                                         
                 !!b5 = (2d0*kbcgs*Temp/mH2)                                                                                                       
                 !!b5 = b5 + bturb**2                                                                                                              
                 !!b5 = 1d-5*sqrt(b5)                                                                                                              
                 !---- using only bturb ---------------------------------                                                                          
                 b5 = 1d-5*bturb
                 !-------------------------------------------------------                                                                          
                 valexp = max(cst1*(one + xshield)**0.5, small_arg)
                 e_valexp = exp(valexp)
                 if(isnan(exp(valexp))) write(*,*) "WARNING: exp(valexp) is nan: valexp=", valexp
                 fshield = 0.035*e_valexp / (one + xshield)**0.5

!                 if(isnan(fshield)) write(*,*) fshield, e_valexp, one, xshield

                 fshield = fshield + 0.965/(one + xshield/b5)**2.0

!                 if(isnan(fshield)) write(*,*)  one, xshield/b5

                 valexp = max(coeff*column_dens_loc(ind_ll,index_m,index_n), small_arg)
                 kph = exp(valexp) !coeff*column_dens_loc(ind_ll,index_m,index_n))                                                                 


 !                if(isnan(kph)) then 
 !                   write(*,*) 'self-shielding is Nan',kph,fshield
 !                endif
                                           
                 kph = kph*fshield                    !kph = fshield(N_H2)*exp(-tau_{d,1000}) *kph0     

                 m_kph = m_kph + kph                  !mean kph                                                                                    
              end do
           end do

           !self-schielding times dust extinction is stored in variable nvar - 1
           !futur self-schielding (e.g. CO) should be stored in nvar - NN 
           uold(ind_leaf(i),nvar-nextinct+1) = m_kph/(NdirExt_m*NdirExt_n)
!           kdest = kph0*uold(ind_leaf(i),neulS+2)
#endif

     end do
#endif

  end do
  ! End loop over cells


end subroutine extinctionfine1
!###########################################################                                          
!###########################################################                                          
!###########################################################                                          
!########################################################### 
!TC: not used?
!###########################################################
!!! VAL (09/07/2014)
!!! VAL (update Nov 2014): I added dependence on T and the sticking coefficient for H2 formation
!
! This routine is a simple version of chem_step, but for only H2:
!
! Formation:    H + H + G(cst) -> H2 + G(cst)      
!               k1 = k1_0*sqrt(T/100K)*S(T)
!
!               k1_0 = 3*10^-17 [cm^3 s^-1]      (Kaufman+1999, Sternberg+2014)
!               S(T) = 1/(1 + (T/464K)^1.5) sticking coefficient (Le Bourlot+2012, Bron+2014, Meudon PDR code)
!
! Destruction:  H2 + hv -> 2 H 
!               k2 = kph = fshield( N(H2) ) * exp(-tau_{d,1000} ) * kph,0
!               kph,0 = 3.3*10^-11*factG0 [s^-1] (Glover & Mac Low2007, Draine & Bertoldi1996,  Sternberg+2014)
!###########################################################
SUBROUTINE simple_chem(ilevel)
  use amr_commons
  use hydro_commons
  implicit none
#ifndef WITHOUTMPI
  include 'mpif.h'
#endif
  integer::ilevel
  !-------------------------------------------------------------------
  ! Compute cooling for fine levels
  !-------------------------------------------------------------------
  integer::ncache,i,igrid,ngrid,info,isink
  integer,dimension(1:nvector),save::ind_grid

  if(numbtot(1,ilevel)==0)return
  if(verbose)write(*,111)ilevel

  ! Operator splitting step for cooling source term
  ! by vector sweeps
  ncache=active(ilevel)%ngrid
  do igrid=1,ncache,nvector
     ngrid=MIN(nvector,ncache-igrid+1)
     do i=1,ngrid
        ind_grid(i)=active(ilevel)%igrid(igrid+i-1)
     end do
     if(verbose)write(*,*) '***VAL: Ready to call simple_chemostep1' ! : ind_grid,ngrid,ilevel=',ind_grid,ngrid,ilevel
     call simple_chemostep1(ind_grid,ngrid,ilevel)
  end do

111 format('   Entering simple_chem for level',i2)

end subroutine simple_chem
!###########################################################                                          
!###########################################################                                          
!###########################################################                                          
!########################################################### 
subroutine simple_chemostep1(ind_grid,ngrid,ilevel) !
  use cooling_module,ONLY: kB,mH
  use amr_commons
  use hydro_commons
  implicit none
  integer                      :: ilevel,ngrid
  integer,dimension(1:nvector) :: ind_grid
  !
  ! variables as in cooling.f90
  integer                      :: i,j,ind,ind2,iskip,idim,nleaf
  real(dp)                     :: scale_nH,scale_T2,scale_l,scale_d,scale_t,scale_v, dt_ilev
  real(kind=8)                 :: nH=0.0_dp, nH2=0.0, ntot=0.0
  real(kind=8)                 :: k1_0=0.0_dp, k1=0.0_dp, k2=0.0, kph0, G0, fshield = 1.0 
  integer,dimension(1:nvector),save::ind_cell,ind_leaf

  real(kind=8),dimension(1:nvector),save     :: ekin,emag,T2,erad_loc
  integer                      :: neulS=8+nextinct, neulP=5
  real(dp)                     :: testf = 1.d-8
  real(dp)                     :: TT, coeff_chi

  logical:: once

  once=.true.

  !!! FIRST ATTEMPT TO FORM H2 USING SIMPLE K
  ! As in cooling_fine:
  !
  ! G0 is the UV field (in units of Habing field - 1.274e-4 erg cm-2 s-1 sr-1)
  G0 = 1.0_dp
  G0 = G0*p_UV              ! p_UV: parameter of variation of UV
                            ! defined in the namelist
  k1_0 = 3.0d-17            ! cm3 s-1 Formation (Kaufman+1999) 3d-17/sqrt(100)
  kph0 = 3.3d-11*G0         ! s-1 Photodissociation (Eq 29 Glover&MacLow2007)
                            ! This value is coherent with what is obtained with the Meudon PDR code (see tests - BG)

  ! Loop over cells
  !if(myid .EQ. 1) write(*,*) '***VAL: Entering SIMPLE_CHEMOSTEP1, starting loop over cells'
  do ind=1,twotondim
     iskip=ncoarse+(ind-1)*ngridmax
     do i=1,ngrid
        ind_cell(i)=iskip+ind_grid(i)
     end do

     ! Gather leaf cells
     nleaf=0
     do i=1,ngrid
        if(son(ind_cell(i))==0)then
           nleaf=nleaf+1
           ind_leaf(nleaf)=ind_cell(i)
        end if
     end do
     ! Conversion factor from user units to cgs units
     call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
 
     dt_ilev = dtnew(ilevel)

!======================================================================
!VAL: I calculate pressure and then temperature (19/11/2014)

     ! Compute pressure                                                                                                                                                                                                                                                                                                      
     do i=1,nleaf
        T2(i)=uold(ind_leaf(i),neulP)
     end do
     do i=1,nleaf
        ekin(i)=0.0d0
     end do
     do idim=1,3
        do i=1,nleaf
           ekin(i)=ekin(i)+0.5_dp*uold(ind_leaf(i),idim+1)**2/uold(ind_leaf(i),1)
        end do
     end do
     do i=1,nleaf
        emag(i)=0.0d0
     enddo
     do idim=1,3
        do i=1,nleaf
           emag(i)=emag(i)+0.125_dp*(uold(ind_leaf(i),idim+neulP)+uold(ind_leaf(i),idim+nvar))**2
        end do
     end do
     do i=1,nleaf
        erad_loc(i)=0.0d0
     end do
     !do j=1,nrad
     !   do i=1,nleaf
     !      erad_loc(i)=erad_loc(i)+uold(ind_leaf(i),8+j)
     !   enddo
     !enddo
     ! Compute temperature 
!!!!! PH attention facteur (1-x)
     do i=1,nleaf
        
!#if NSCHEM !=0                                                                                                                                                        
        !calculate temperature
        T2(i)=(gamma-1.0)*(T2(i)-ekin(i)-emag(i)-erad_loc(i))/(uold(ind_leaf(i),1) - uold(ind_leaf(i),neulS+1))

        !the last factor is the mean mass per particle - 0.4 is for helium abundance
        T2(i) = T2(i)*scale_T2 * (  0.4 + uold(ind_leaf(i),1) / (uold(ind_leaf(i),1) - uold(ind_leaf(i),neulS+1))  )
        !!!!! Test BG
        ! WRITE(*,*) "coucou ", uold(ind_leaf(i),1), uold(ind_leaf(i),neulS+1), T2(i), erad_loc(i), scale_T2

        if(isnan(T2(i))) write(*,*) "WARNING: T2(i) is NaN: P,Ekin,Emag,Erad,dens,nH2", uold(ind_leaf(i),neulP), ekin(i), emag(i), erad_loc(i), uold(ind_leaf(i),1), uold(ind_leaf(i),neulS+1)
        if(T2(i) .LE. 0 ) write(*,*) "WARNING: T2(i) < 0: P,Ekin,Emag,Erad,dens,nH2", uold(ind_leaf(i),neulP), ekin(i), emag(i), erad_loc(i), uold(ind_leaf(i),1), uold(ind_leaf(i),neulS+1)
        if(isnan(T2(i)) .OR. T2(i) .LT. 0) stop

     end do

!======================================================================

     !nH2 : just one value here
     do i=1,nleaf
        ! 1st: I read current value:
        ntot= uold(ind_leaf(i),1)             ! the ntot ???
        nH2 = uold(ind_leaf(i),neulS+1)       ! H2 density    

        if(myid .EQ. 1 .AND. nH2 .LT. 0) write(*,*) "WARNING nH2 LT 0:", ind, i, nH2, ntot

        if(isnan(uold(ind_leaf(i),firstindex_extinct+2))) write(*,*) "WARNING (simple_chemostep1 BEFORE solve) uold( ,neulS+2) is nan, i, ind_leaf(i)",i, ind_leaf(i) 
        k2 = kph0 * uold(ind_leaf(i),firstindex_extinct+2) ! kph_0*<fshield*exp(-tau_(d,1000) )> (eq 31, Glover&MacLow2006) 
        k1 = k1_0*sqrt(T2(i)/100.0_dp)/(1.0_dp + (T2(i)/464.0_dp)**1.5_dp)        ! k1 = k1_0*sqrt(T/100K)*S(T)
                        
        ! 2nd: I solve the evolution of H2 for the next step
        call solve2_H2form(nH2, ntot, k1, k2, dt_ilev)   !!! xH and xH2 must be in/out variables.

        if(nH2/ntot .GT. 0.5 .OR. nH2/ntot .LT. 0.0) write(*,*) "WARNING: xH2,nH2,ntot", nH2/ntot, nH2,ntot
        if(isnan(nH2)) write(*,*)"WARNING(simple_chemostep1 AFTER): nH2 is nan, i, ind_leaf(i)",i, ind_leaf(i)

        ! 3rd: I actualize the value in the vector
        uold(ind_leaf(i),neulS+1) = nH2

#if NEXTINCT>1
        !now calculate the cooling
        !take care it is done here and not in cooling_fine
        TT = T2(i) / scale_T2  !from physical units to code units
        !TAKE CARE here TT / scale_T2 is the true code temperature and not T/mu 
        !the extinction due to dust 
        coeff_chi = uold(ind_leaf(i),firstindex_extinct+1)
        call calc_temp_extinc(ntot,TT,dt_ilev,coeff_chi) 

        !this factor is the mean mass per particle, it goes from 1.4 to 2.4 - 0.4 is for helium abundance
        TT = TT /  (  0.4 + uold(ind_leaf(i),1) / (uold(ind_leaf(i),1) - uold(ind_leaf(i),neulS+1))  )

        !now recalculate the internal energy
        uold(ind_leaf(i),neulP) = TT / (gamma-1.0) * (uold(ind_leaf(i),1) - uold(ind_leaf(i),neulS+1)) + ekin(i)+ emag(i) + erad_loc(i)
#endif

     end do   ! leaf

  end do      ! cells

end subroutine simple_chemostep1
!###########################################################                                          
!###########################################################                                          
!###########################################################                                          
!########################################################### 
subroutine solve_H2form(nH2, ntot, k1, k2, dt_ilev)
  implicit none

  real(kind=8),intent(INOUT)  :: nH2
  real(kind=8),intent(IN)     :: ntot, k1, k2, dt_ilev

  integer                     :: Nsteps, istep
  real(kind=8)                :: dtchem, dtstep, xH, xH2, xH2new, dt_tot, temps, dt   !nH2 = nH2/ntot
  real(kind=8)            :: scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2

  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

  dt_tot = dt_ilev * scale_t ! * 3.08d18 / sqrt(kb_mm)
  dt = dt_tot/1000.0

  xH2 = nH2/ntot
  xH = 1.0 - 2.0*xH2
  dtchem = 0.8/abs(k1 - k2*xH2)
  temps = 0.0

  ! EQUATION TO SOLVE:
  ! nH2(t+dt) = nH2(t) + (k1*nH**2 - k2*nH2)dt   

  
!!! to be written
! Idea???
  Nsteps = int(dt_ilev/dtchem) + 1   !DO IT BETTER. In the future use a do while, recalculate dt_chem at each timestep and compare as in cooling_fine. 

  do while ( temps < dt_tot)
!  do istep=1, Nsteps    

     xH2new = xH2 + (k1*xH*ntot - k2*xH2)*dt !*dtchem
     xH = 1.0 - 2.0*xH2new
     xH2 = xH2new
     if(xH2new .GT. 0.5) write(*,*) "WARNING: H2 fraction GT 0.5, xH, xH2", xH, xH2new
     if(xH2new .LT. 0.0) write(*,*) "WARNING: H2 fraction LT 0, xH, xH2", xH, xH2new
     if(xH .GT. 1.0) write(*,*) "WARNING: HI fraction GT 1, xH, xH2", xH, xH2new
     if(xH .LT. 0.0) write(*,*) "WARNING: HI fraction LT 0, xH, xH2", xH, xH2new

     temps = temps + dt

  end do

  nH2 = xH2*ntot
end subroutine solve_H2form
!###########################################################                                          
!###########################################################                                          
!###########################################################                                          
!########################################################### 
subroutine solve2_H2form(nH2, ntot, k1, k2, dt_ilev)
  use amr_commons
  implicit none

  real(kind=8),intent(INOUT)  :: nH2
  real(kind=8),intent(IN)     :: ntot, k1, k2, dt_ilev

  integer                     :: Nsteps, istep
  real(kind=8)                :: dtchem, dtstep, xH, xH2, xH2new, dt_tot, temps, dt   !nH2 = nH2/ntot
  real(kind=8)                :: scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2,denom, k1ntot, dennew
  real(kind=8)                :: xH2min = 1.d-30, xH2max = 4.999d-1, xHmin = 1.d-30
  
  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)

  if(isnan(nH2) .OR. isnan(ntot) .OR. isnan(k2) .OR. isnan(k1)) write(*,*) "WARNING: solve2_H2form invalid arguments nH2, ntot, k2, k1", nH2, ntot, k2, k1

  dennew = 1.0
  dt_tot = dt_ilev * scale_t ! * 3.08d18 / sqrt(kb_mm)
  dtchem = dt

  if(myid .EQ. 1 .AND. nH2 .LT. 0.0) write(*,*) 'WARNING initial nH2 LT 0.0', nH2 
  xH2 = MAX(nH2/ntot,xH2min)
  if(myid .EQ. 1 .AND. xH2 .GT. 0.5) write(*,*) 'WARNING initial xH2 GT 0.5', xH2 
  xH2 = MIN(xH2, xH2max)
  xH = MAX(1.0 - 2.0*xH2, xHmin)
  
  k1ntot = k1*ntot
  if(isnan(k1ntot)) write(*,*) "WARNING: k1*ntot is nan, k1, ntot=", k1, ntot
  temps = 0.0

  !---------------------------------------------------------------
  ! EQUATION TO SOLVE:
  !( nH2(t+dt)- nH2(t))/dt = (k1*xH*n - k2*xH2)  
  !                        = k1*n*(1-2*xH2(t+dt)) - k2*xH2(t+dt)
  ! nH2(t+dt) =  (xH2(t) - k1*n*dt)/( 1 + (2*k1*n+k2)*dt)
  !---------------------------------------------------------------

  do while ( temps < dt_tot)

     denom= MAX((k1ntot - (2.0*k1ntot + k2)*xH2), 1./dt_tot)
     dtchem = MIN(ABS(xH2/denom), dt_tot)
     dtchem = 5d-2*MAX(1.0/(2*k1ntot + k2), dtchem)

     dt = min(dtchem, dt_tot-temps)
     temps = temps + dt

     dennew = (1.0 + (2.0*k1ntot + k2)*dt)
     if(isnan(dennew)) write(*,*) "WARNING: (IN) dennew is NaN", temps,k1ntot, k2, dt 
     xH2new = (xH2 + k1ntot*dt) / dennew              !(1.0 + (2.0*k1ntot + k2)*dt) !*dtchem
     !if(xH2new .GT. 0.5) xH2new = 0.5

     if(isnan(xH2new)) write(*,*) "WARNING: (IN) H2new fraction is NaN", temps, xH2, k1ntot, k2, dt  
     if(xH2new .GT. 0.5) write(*,*) "WARNING: (IN) xH2new GT 0.5,xH2", xH2new, MIN(MAX(xH2new,xH2min),0.5) 
     if(xH2new .LT. 0.0) write(*,*) "WARNING: (IN) xH2new LT 0,xH2", xH2new, MIN(MAX(xH2new,xH2min),0.5) 

     xH2new = MAX(xH2new,xH2min)
     xH2new = MIN(xH2new,xH2max)

     xH = 1.0 - 2.0*xH2new
     xH2 = xH2new

  end do

  if(isnan(xH2)) write(*,*) "WARNING: (OUT) H2 fraction is NaN"    
  if(xH2new .GT. 0.5 .OR. xH .LT. 0.0 ) write(*,*) "WARNING: (OUT) xH2 GT 0.5, xH, xH2", xH, xH2new
  if(xH2new .LT. 0.0 .OR. xH .GT. 1.0) write(*,*) "WARNING: (OUT) xH2 LT 0, xH, xH2", xH, xH2new

  if(isnan(xH2)) write(*,*) "WARNING: (END) xH2 is nan"
  xH2 = min(xH2, xH2max)
  xH2 = max(xH2, xH2min)
  nH2 = xH2*ntot

  if(nH2 .LT. 0.0) write(*,*) "WARNING END: ", ntot, xH2, nH2 

end subroutine solve2_H2form


subroutine sfr_update_uv()
  !---------------------------------------------------------------------------
  ! [UV_PROP_SFR] 
  ! called by :
  !     amr_step
  ! purpose :
  !     Update the p_uv parameter proportionnally to the sfr
  ! results :
  !     p_uv is updated
  !---------------------------------------------------------------------------

  use amr_commons
  use pm_commons
  use hydro_commons
  use constants, only: pc2cm, Myr2sec, yr2sec, M_sun
  implicit none

  integer :: i_old, i_new, i_last ! Index of the position of the past and current total sink mass in the array
  integer :: i, di ! General purpose indexes
  real(dp) :: sfr_timestep, time_span, ssfr, dt_last
  real(dp) :: scale_nH, scale_T2, scale_l, scale_d, scale_t, scale_v, scale_m
  character(len=:), allocatable :: uvsfr_fmt      

  call units(scale_l,scale_t,scale_d,scale_v,scale_nH,scale_T2)
  scale_m = scale_d*scale_l**3d0

  ! Safety check for high dt
  dt_last = t - sfr_time_mass_sinks(modulo_tab(sfr_ilast, uvsfr_nb_points))
  if (dt_last >= uvsfr_avg_window * (Myr2sec / scale_t) ) then
    write(*,*) "[WARNING] dt too high to compute SFR, using p_UV_min"
    p_UV = p_UV_min
    return
  end if

  ! timestep for the computation of the sfr
  sfr_timestep = uvsfr_avg_window * (Myr2sec / scale_t) / uvsfr_nb_points

  ! raw index for current time
  i_new = max(2, ceiling(t / sfr_timestep))
  ! increase since last time
  di = i_new - sfr_ilast
  ! Store for next step
  i_last = modulo_tab(sfr_ilast, uvsfr_nb_points)
  sfr_ilast = i_new    
  ! now store the corresponding index in the table
  i_new = modulo_tab(i_new, uvsfr_nb_points)
  

  ! index where to take the old sink mass for the sfr computation
  if (t < uvsfr_avg_window * (Myr2sec / scale_t)) then
     i_old = 1
  else
     i_old = modulo_tab(i_new + 1, uvsfr_nb_points)
  end if

  ! Compute current mass in sinks
  sfr_total_mass_sinks(i_new) = sum(msink(1:nsink))
  sfr_time_mass_sinks(i_new) = t

  ! In case di > 1, we have skipped some indexes. Let's fill them now.
  do i = i_last + 1, i_last + di - 1
    sfr_total_mass_sinks(modulo_tab(i, uvsfr_nb_points)) = sfr_total_mass_sinks(i_last)
    sfr_time_mass_sinks(modulo_tab(i, uvsfr_nb_points)) = sfr_time_mass_sinks(i_last)
  end do


  ! time effectively used for the average of the sfr (in year).
  time_span = (sfr_time_mass_sinks(i_new) - sfr_time_mass_sinks(i_old)) * scale_t / yr2sec
  ! SFR in the box
  ssfr = (sfr_total_mass_sinks(i_new) - sfr_total_mass_sinks(i_old)) * scale_m / M_sun / time_span
  ! Divide by the surface of the box to get the surfacic SFR (SSFR)
  ssfr = ssfr / (boxlen * scale_l / pc2cm)**2

  ! Compute the p_UV parameter, equivalent to G0' in the equation (17) in Ostriker, McKee & Leroy 2010
  p_UV = max(ssfr / ssfr_ref, p_UV_min)

  if (myid == 1 .and. uvsfr_verbose) then
     uvsfr_fmt = '("  t=",f10.3, " [Myr]", 2x, "SSFR=", es11.2, " [Msun.pc-2.yr-1]", &
     & 2x, "p_UV=", f8.3, 2x, "time_span=", f8.3, " [Myr]", 2x)' 
     write(*, uvsfr_fmt)  t * scale_t / Myr2sec, ssfr, p_uv, time_span / 1e6
  end if

  contains
   pure function modulo_tab(a, b) result(modulo_1)
      !---------------------------------------------------------------------------
      ! A simple modulo function adapted to Fortran array
      ! Give the a modulo b representent between 1 and b 
      ! instead of between 0 and b - 1
      !---------------------------------------------------------------------------
      implicit none
      integer, intent(in) :: a, b
      integer :: modulo_1

      modulo_1 = 1 + modulo(a - 1, b)
   end function modulo_tab

end subroutine sfr_update_uv


!###########################################################                                          
!###########################################################                                          
!###########################################################                                          
!########################################################### 
! Molecular cooling from table 2 of Goldsmith 2001
! Temp: temperature in K
! ndens: density in cc
! cool_mol_dust: molecular and dust cooling 
subroutine cool_goldsmith(Temp,ndens,cool_mol_dust)
  use amr_parameters, only:dp
  implicit none

  real(dp):: Temp,ndens
  real(dp)::cool_mol_dust
  integer :: i
  real(dp):: log_n,alpha,beta,cool_mol,cool_dust
  !Table from Goldsmith 2001
  real(dp),dimension(7),parameter:: logn_v= (/2.,2.5,3.,4.,5.,6.,7./)
  real(dp),dimension(7),parameter:: alpha_v=(/6.3e-26,3.2e-25,1.1e-24,5.6e-24,2.3e-23,4.9e-23,7.4e-23/)
  real(dp),dimension(7),parameter:: beta_v=(/1.4,1.8,2.4,2.7,3.,3.4,3.8/)
  !dust temperature is assumed to be 10 K 
  !need to be improved particularly if stellar radiative feedback is accounted for
  real(dp):: Tdust=10.

  !validity range 
  if(ndens <  100. .or. ndens > 1.e7) then 
     cool_mol=0.
     ! TC: this should be cool_mol_dust?
     !     What about the dust contribution below 100 H/cc?
     !return
  else

     log_n = log10(ndens)
     do i = 1, 6
        if (log_n .ge. logn_v(i) .and. log_n .le. logn_v(i+1)) exit
     ! TC: exit necesary?
     enddo

     alpha = alpha_v(i+1) * (log_n - logn_v(i)) + alpha_v(i) * (-log_n + logn_v(i+1))
     alpha = alpha / (logn_v(i+1)-logn_v(i))

     beta = beta_v(i) * (log_n - logn_v(i)) + beta_v(i) * (-log_n + logn_v(i+1))
     beta = beta / (logn_v(i+1)-logn_v(i))

     cool_mol = alpha * (Temp/10.)**beta / ndens**2 !division by n^2 because cooling works in cm^3 (rate)
                                                 !while Goldsmith expressed it in cm^-3
  endif
  !take into accound the cooling/heating through dust
  cool_dust = 2.e-33 * (Temp-Tdust) * sqrt(Temp/10.)
  cool_mol_dust = cool_mol + cool_dust

end subroutine cool_goldsmith
!###########################################################                                          
!###########################################################                                          
!###########################################################                                          
!########################################################### 
! Compute the C+/CO transition at equilibrium from Koyama & Inutuska 2000
! Taken from Nelson & Langer 1997
subroutine compute_Cp_CO_NL(ndens,XH2,G0,xO,xCp,xCO)
  use amr_parameters, only:dp
  implicit none

  real(dp):: ndens, XH2, G0, xO, xCp, xCO
  real(dp),parameter:: k0 = 5d-16 !#cm^3 s^-1
  real(dp),parameter:: k1 = 5d-10
  real(dp):: xCp_0, gamma_CO, Gamma_CHx, beta
!  real(dp):: xCp_0=3.e-4,xO=3.e-4

  xCp_0=xCp
  gamma_CO = 1d-10 * G0 !#s^-1
  Gamma_CHx = 5d-10 * G0 
  beta = k1*xO / (k1*xO+gamma_CO/(XH2*ndens))
  xCp = xCp_0 * gamma_CO / (gamma_CO + k0*beta*ndens)
  xCO = xCp_0 - xCp
    
end subroutine compute_Cp_CO_NL
