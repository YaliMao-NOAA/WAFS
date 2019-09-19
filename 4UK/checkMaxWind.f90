! for GRIB1
! check wind profile against max wind speed
! for grid octants 37-44, grid 45, and master file
program main

  implicit none

!  integer :: igrid, grid(8) = (/ 37,38,39,40,41,42,43,44 /)

  integer :: jpds(200), jgds(200), kpds(200), kgds(200), kf, kk
  integer :: pds5(2) = (/ 33, 34 /)
  integer :: pds6 = 100, pds6max=6

  integer :: day,month,year,hour,fhour

  integer, parameter :: nz=13 ! octants have only 12 vertical wind layers
  integer, target :: pds7_octants(nz-1) = (/ 70,100,150,200,250,300,400,500,600,700,850,1000 /), pds7max=0
  integer, target :: pds7_45(nz) = (/ 100, 150, 200, 225, 250, 275, 300, 350, 400, 500, 600, 700, 850 /)
  integer, pointer :: pds7(:)

  integer :: npoints(73) =(/ 2,3,5,6,8,9,11,12,14,16,17,19,20,22,23,25,26,28,29,30, &
       32,33,35,36,38,39,40,42,43,44,45,47,48,49,50,51,52,54,55,56,57,58,59,60,60,&
       61,62,63,64,65,65,66,67,67,68,69,69,70,70,71,71,71,72,72,72,73,73,73,73,73,&
       73,73,73 /)
  integer, parameter :: nxy_octants = 3447, nxy_45=288*145, nxy_master=1760*880

  character(len=256) :: datafile
  character(len=2) :: cgrid
  integer :: unit, nnz, nxy, iret, i, k

  real, allocatable :: u(:), v(:), speed(:), speedmax(:)
  real :: diff

  logical, allocatable :: bitmap(:)

  if ( COMMAND_ARGUMENT_COUNT() /= 2) then
     write(*,*) "Inputs: dataFileName Grid#"
     stop
  end if

  ! parse file name from command line
  call GET_COMMAND_ARGUMENT(1, datafile)
  ! parse grid from command line
  call GET_COMMAND_ARGUMENT(2, cgrid)

  unit = 100
  call BAOPENR(unit, datafile, iret)

  if(cgrid == "45") then
     nnz = 13
     pds7 => pds7_45
     nxy = nxy_45
  else if(cgrid=="ms") then
     nnz = 13
     pds7 => pds7_45
     nxy = nxy_master
  else
     nnz = 12
     pds7 => pds7_octants
     nxy = nxy_octants
  end if
  allocate(u(nxy))
  allocate(v(nxy))
  allocate(speed(nxy))
  allocate(speedmax(nxy))
  allocate(bitmap(nxy))

  jpds(:) = -1
  jgds(:) = -1
!  lp_igrid: do igrid=1, size(grid)
!     jgds(3) = grid(igrid)

  ! wind max u
  jpds(5) = pds5(1)
  jpds(6) = pds6max
  jpds(7) = pds7max
  bitmap = .false.
  call GETGB(unit, 0, nxy, 0, jpds, jgds, kf, kk, kpds, kgds, bitmap, u, iret)
  if (iret /= 0) then
     write(*,*)"reading file max u iret=", iret
     stop
  end if
  ! wind max v
  jpds(5) = pds5(2)
  jpds(6) = pds6max
  jpds(7) = pds7max
  bitmap = .false.
  call GETGB(unit, 0, nxy, 0, jpds, jgds, kf, kk, kpds, kgds, bitmap, v, iret)
  if (iret /= 0) then
     write(*,*)"reading file max v iret=", iret
     stop
  end if
  ! wind speed max
  speedmax(:) = sqrt(u*u+v*v)

!- date
  year  = kpds(8)
  if (year < 100) year = year + 2000
  month = kpds(9)
  day   = kpds(10)
  hour  = kpds(11)
!- forecast hour
  fhour = kpds(14)

  write(*,"(a11,a2,a8,I4,3I2.2,a,I2.2)")"GRIB1 GRID=",cgrid, "   date=",year,month,day,hour,"f",fhour
  write(*,*)"i       pressure    diff     speed(i)  speedmax(i)"
  lp_k: do k = 1, nnz
     ! wind u
     jpds(5) = pds5(1)
     jpds(6) = pds6
     jpds(7) = pds7(k)
     bitmap = .false.
     call GETGB(unit, 0, nxy, 0, jpds, jgds, kf, kk, kpds, kgds, bitmap, u, iret)
     if (iret /= 0) then
        write(*,*) k, "reading file p u iret=", iret
        stop
     end if
     ! wind v
     jpds(5) = pds5(2)
     jpds(6) = pds6
     jpds(7) = pds7(k)
     bitmap = .false.
     call GETGB(unit, 0, nxy, 0, jpds, jgds, kf, kk, kpds, kgds, bitmap, v, iret)
     if (iret /= 0) then
        write(*,*) k, "reading file p v iret=", iret
        stop
     end if
     ! wind speed
     speed(:) = sqrt(u*u+v*v)

     ! compare to wind max speed
     lp_i: do i = 1, nxy
        diff = speed(i) - speedmax(i)
        if( diff > 1.0) then
           if(pds7(k) > 100 .and. pds7(k) < 500) then
              write(*,"(I7,I7,A3,F8.2,F10.2,F10.2, a15)") i, pds7(k), "hPa", diff, speed(i), speedmax(i), "     --warning"
           else
              write(*,"(I7,I7,A3,F8.2,F10.2,F10.2)") i, pds7(k), "hPa", diff, speed(i), speedmax(i)
           end if
        end if
     end do lp_i

  end do lp_k

!  end do lp_igrid

  deallocate(u)
  deallocate(v)
  deallocate(speed)
  deallocate(speedmax)
  deallocate(bitmap)

  call BACLOSE(unit, iret)
end program main
