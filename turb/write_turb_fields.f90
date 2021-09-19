#if USE_TURB==1
subroutine write_turb_fields(output_dir)
   use turb_commons
   implicit none

   integer                      :: ilun        ! File I/O unit
   character(len=*), intent(in) :: output_dir  ! Output directory
   character(len=8)             :: file_ext    ! String version of nturbtemp
   character(len=50000)         :: file_buffer ! Buffer for header file
   character(len=1)             :: c           ! Mostly pointless variable
   character(len=17)            :: turb_last_time_z ! turb_last_time in hex
   character(len=17)            :: turb_next_time_z ! turb_next_time in hex
   character(len=256)           :: turb_file_spectrum  ! filename for power spectrum
   integer       :: i, j, k                ! Loop variables
   integer       :: k_vec(1:3)             ! Wavevector

   write(file_ext,"(I0)") 0 ! For compatibility with Seren

   ilun = myid+10

   turb_file_last = 'turb_last.'//trim(file_ext)//'.dat'
   turb_file_next = 'turb_next.'//trim(file_ext)//'.dat'
   turb_file_header = trim(output_dir)//'turb_fields.dat'
   turb_file_spectrum = trim(output_dir)//'turb_power_spectrum.dat'

   write(turb_last_time_z, '(X,Z16)') turb_last_time
   write(turb_next_time_z, '(X,Z16)') turb_next_time

   ! Write turbulent fields
   open(ilun,file=trim(output_dir)//trim(turb_file_last),status="unknown",&
        &access="stream",form="unformatted")
   write(ilun) turb_last
   close(ilun)

   open(ilun,file=trim(output_dir)//trim(turb_file_next),status="unknown",&
        access="stream",form="unformatted")
   write(ilun) turb_next
   close(ilun)

   ! Write header file of important information
   write(file_buffer,*) 0, NEW_LINE(c),&
                      & precision_str, NEW_LINE(c),&
                      & trim(turb_file_last), NEW_LINE(c),&
                      & turb_last_time, turb_last_time_z, NEW_LINE(c),&
                      & trim(turb_file_next), NEW_LINE(c),&
                      & turb_next_time, turb_next_time_z, NEW_LINE(c),&
                      & TURB_GS, TURB_GS, TURB_GS, NEW_LINE(c),&
                      & (/0.d0, 0.d0, 0.d0/), NEW_LINE(c),&      ! turb_min
                      & (/1.d0, 1.d0, 1.d0/), NEW_LINE(c),&      ! turb_max
                      & turb_T, turb_dt, NEW_LINE(c),&
                      & comp_frac, sol_frac, NEW_LINE(c),&
                      & kiss64_state, NEW_LINE(c)                ! random number state

   ! Now write atomically (safest)
   open(ilun,file=turb_file_header,status="unknown",access='stream',&
        &form="formatted")
   write(ilun,*) trim(file_buffer)
   close(ilun)

   ! write turbulence power spectrum
   open(ilun,file=turb_file_spectrum,status="unknown",access='stream',&
        &form="formatted")
   write(ilun,*) "# k_x, k_y, k_z, P(k)"

   do k=0,TGRID_Z
     if (k > TURB_GS / 2) then
       k_vec(3) = k - TURB_GS
     else
       k_vec(3) = k
     end if
     do j=0,TGRID_Y
       if (j > TURB_GS / 2) then
         k_vec(2) = j - TURB_GS
       else
         k_vec(2) = j
       end if
       do i=0,TGRID_X
         if (i > TURB_GS / 2) then
           k_vec(1) = i - TURB_GS
         else
           k_vec(1) = i
         end if
         write(ilun,*) k_vec, power_spec(i,j,k)
       end do
     end do
   end do
   close(ilun)

end subroutine write_turb_fields
#endif