module amr_constants
  use amr_parameters, only:twotondim,threetondim,dp
  implicit none

  integer, dimension(1:3,1:2,1:8),parameter :: iii=reshape( (/ &
                                              1,0,1,0,1,0,1,0, &
                                              0,2,0,2,0,2,0,2, &
                                              3,3,0,0,3,3,0,0, &
                                              0,0,4,4,0,0,4,4, &
                                              5,5,5,5,0,0,0,0, &
                                              0,0,0,0,6,6,6,6  &
                                       /), shape=(/3,2,8/), order=(/3,2,1/))
  integer, dimension(1:3,1:2,1:8),parameter :: jjj=reshape( (/ &
                                              2,1,4,3,6,5,8,7, &
                                              2,1,4,3,6,5,8,7, &
                                              3,4,1,2,7,8,5,6, &
                                              3,4,1,2,7,8,5,6, &
                                              5,6,7,8,1,2,3,4, &
                                              5,6,7,8,1,2,3,4  &
                                       /), shape=(/3,2,8/), order=(/3,2,1/))

  ! ------------------ neighbor finding ------------------

#if NDIM==1
  integer,dimension(1:threetondim,1:twotondim),parameter::lll=reshape( (/ &
                                                                   2,1,1, &  !ind=1
                                                                   1,1,2  &  !ind=2
                                               /), shape=(/threetondim,twotondim/))

  integer,dimension(1:threetondim,1:twotondim),parameter::mmm=reshape( (/ &
                                                                   2,1,2, &  !ind=1
                                                                   1,2,1  &  !ind=2
                                               /), shape=(/threetondim,twotondim/))

#elif NDIM==2
  integer,dimension(1:threetondim,1:twotondim),parameter::lll=reshape( (/ &
                                                       4,3,3,2,1,1,2,1,1, &  !ind=1
                                                       3,3,4,1,1,2,1,1,2, &  !ind=2
                                                       2,1,1,2,1,1,4,3,3, &  !ind=3
                                                       1,1,2,1,1,2,3,3,4  &  !ind=4
                                               /), shape=(/threetondim,twotondim/))

  integer,dimension(1:threetondim,1:twotondim),parameter::mmm=reshape( (/ &
                                                       4,3,4,2,1,2,4,3,4, &  !ind=1
                                                       3,4,3,1,2,1,3,4,3, &  !ind=2
                                                       2,1,2,4,3,4,2,1,2, &  !ind=3
                                                       1,2,1,3,4,3,1,2,1  &  !ind=4
                                               /), shape=(/threetondim,twotondim/))

#elif NDIM==3
  integer,dimension(1:threetondim,1:twotondim),parameter::lll=reshape( (/ &
                   8,7,7,6,5,5,6,5,5,4,3,3,2,1,1,2,1,1,4,3,3,2,1,1,2,1,1, &  !ind=1
                   7,7,8,5,5,6,5,5,6,3,3,4,1,1,2,1,1,2,3,3,4,1,1,2,1,1,2, &  !ind=2
                   6,5,5,6,5,5,8,7,7,2,1,1,2,1,1,4,3,3,2,1,1,2,1,1,4,3,3, &  !ind=3
                   5,5,6,5,5,6,7,7,8,1,1,2,1,1,2,3,3,4,1,1,2,1,1,2,3,3,4, &  !ind=4
                   4,3,3,2,1,1,2,1,1,4,3,3,2,1,1,2,1,1,8,7,7,6,5,5,6,5,5, &  !ind=5
                   3,3,4,1,1,2,1,1,2,3,3,4,1,1,2,1,1,2,7,7,8,5,5,6,5,5,6, &  !ind=6
                   2,1,1,2,1,1,4,3,3,2,1,1,2,1,1,4,3,3,6,5,5,6,5,5,8,7,7, &  !ind=7
                   1,1,2,1,1,2,3,3,4,1,1,2,1,1,2,3,3,4,5,5,6,5,5,6,7,7,8  &  !ind=8
                                               /), shape=(/threetondim,twotondim/))

  integer,dimension(1:threetondim,1:twotondim),parameter::mmm=reshape( (/ &
                   8,7,8,6,5,6,8,7,8,4,3,4,2,1,2,4,3,4,8,7,8,6,5,6,8,7,8, &  !ind=1
                   7,8,7,5,6,5,7,8,7,3,4,3,1,2,1,3,4,3,7,8,7,5,6,5,7,8,7, &  !ind=2
                   6,5,6,8,7,8,6,5,6,2,1,2,4,3,4,2,1,2,6,5,6,8,7,8,6,5,6, &  !ind=3
                   5,6,5,7,8,7,5,6,5,1,2,1,3,4,3,1,2,1,5,6,5,7,8,7,5,6,5, &  !ind=4
                   4,3,4,2,1,2,4,3,4,8,7,8,6,5,6,8,7,8,4,3,4,2,1,2,4,3,4, &  !ind=5
                   3,4,3,1,2,1,3,4,3,7,8,7,5,6,5,7,8,7,3,4,3,1,2,1,3,4,3, &  !ind=6
                   2,1,2,4,3,4,2,1,2,6,5,6,8,7,8,6,5,6,2,1,2,4,3,4,2,1,2, &  !ind=7
                   1,2,1,3,4,3,1,2,1,5,6,5,7,8,7,5,6,5,1,2,1,3,4,3,1,2,1  &  !ind=8
                                               /), shape=(/threetondim,twotondim/))
#endif

  ! ------------------ interpolation ------------------

  ! Sampling positions in the 3x3x3 father cell cube
  integer,dimension(1:8,1:8),parameter::ccc=reshape( (/ &
                               1 ,2 ,4 ,5 ,10,11,13,14, &
                               3 ,2 ,6 ,5 ,12,11,15,14, &
                               7 ,8 ,4 ,5 ,16,17,13,14, &
                               9 ,8 ,6 ,5 ,18,17,15,14, &
                               19,20,22,23,10,11,13,14, &
                               21,20,24,23,12,11,15,14, &
                               25,26,22,23,16,17,13,14, &
                               27,26,24,23,18,17,15,14  &
                               /), shape=(/8,8/))

  ! CIC method constants
  !   a = 1d0/4d0**ndim
  !   b = 3*a
  !   c = 9*a
  !   d = 27*a
  !   bbb(:)  =(/a ,b ,b ,c ,b ,c ,c ,d/)
#if NDIM==1
  real(dp),dimension(1:8),parameter::bbb=(/0.25d0, 0.75d0, 0.75d0, 2.25d0, &
                                           0.75d0, 2.25d0, 2.25d0, 6.75d0/)
#elif NDIM==2
  real(dp),dimension(1:8),parameter::bbb=(/0.0625d0, 0.1875d0, 0.1875d0, 0.5625d0, &
                                           0.1875d0, 0.5625d0, 0.5625d0, 1.6875d0/)
#elif NDIM==3
  real(dp),dimension(1:8),parameter::bbb=(/0.015625d0, 0.046875d0, 0.046875d0, 0.140625d0, &
                                           0.046875d0, 0.140625d0, 0.140625d0, 0.421875d0/)
#endif

end module amr_constants
