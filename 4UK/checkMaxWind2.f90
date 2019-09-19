! for GRIB2
! check wind profile against max wind speed
! for grid octants 37-44, grid 45, and master file
program main

  use grib_mod
  implicit none

!  integer :: igrid, grid(8) = (/ 37,38,39,40,41,42,43,44 /)

  type(gribfield) :: gfld
  integer :: j,jpdtn,jgdtn
  integer,dimension(200) :: jids,jpdt,jgdt
  logical :: unpack=.true.

  integer :: jdisc                  ! discipline#, table 0.0(met:0 hydro:1 land:2)
  ! integer :: pds1                 ! category#,   table 4.1
  integer :: pds2(2) = (/ 2, 3 /)   ! name#,       table 4.2
  integer :: pds10 = 100, pds10max=6! level ID,    table 4.5

  integer :: day,month,year,hour,fhour

  integer, pointer :: pds12(:)      ! level value, pressure in Pa
  integer, parameter :: nz=13 ! octants have only 12 vertical wind layers
  integer, target :: pds12_octants(nz-1) = (/ 70,100,150,200,250,300,400,500,600,700,850,1000 /), pds12max=0
  integer, target :: pds12_45(nz) = (/ 100, 150, 200, 225, 250, 275, 300, 350, 400, 500, 600, 700, 850 /)

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
     pds12 => pds12_45
     nxy = nxy_45
  else if(cgrid=="ms") then
     nnz = 13
     pds12 => pds12_45
     nxy = nxy_master
  else
     nnz = 12
     pds12 => pds12_octants
     nxy = nxy_octants
  end if
  allocate(u(nxy))
  allocate(v(nxy))
  allocate(speed(nxy))
  allocate(speedmax(nxy))

!-- set grid def template
  jgdtn = -1
!-- set product def array
  jgdt = -9999

! Set GRIB2 field identification values to search for
  jdisc = 0       ! discipline#, table 0.0(met:0 hydro:1 land:2)
!-- set id section
  jids  = -9999
!-- set product def template, using template 4.0
  jpdtn = 0
!-- set product def array
  jpdt  = -9999
!- For pdt, define catogory, name and level
  jpdt(1) = 2     ! category#,   table 4.1

  ! wind max u
  j  = 0               ! search from 0
  jpdt(2)  = pds2(1)   ! name#,       table 4.2
  jpdt(10) = pds10max  ! level ID,    table 4.5
  jpdt(12)  = pds12max ! level value

!- Get field from file
  call getgb2(unit,0,j,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,  &
              unpack,j,gfld,iret)
  if (iret /= 0) then
     write(*,*)"reading file max u iret=", iret
     stop
  end if
  u(:) = gfld%fld(:)

  ! wind max v
  j = 0
  jpdt(2)  = pds2(2)
  jpdt(10) = pds10max
  jpdt(12)  = pds12max
  call getgb2(unit,0,j,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,  &
              unpack,j,gfld,iret)
  if (iret /= 0) then
     write(*,*)"reading file max v iret=", iret
     stop
  end if
  v(:) = gfld%fld(:)

  ! wind speed
  speedmax(:) = sqrt(u*u+v*v)

!- date
  year  = gfld%idsect(6)
  month = gfld%idsect(7)
  day   = gfld%idsect(8)
  hour  = gfld%idsect(9)
!- forecast hour
  fhour=gfld%ipdtmpl(9)

  write(*,"(a11,a2,a8,I4,3I2.2,a,I2.2)")"GRIB2 GRID=",cgrid, "   date=",year,month,day,hour,"f",fhour
  write(*,*)"i       pressure    diff     speed(i)  speedmax(i)"
  lp_k: do k = 1, nnz
     ! wind u
     j = 0  
     jpdt(2)  = pds2(1)
     jpdt(10) = pds10
     jpdt(12) = pds12(k)*100 ! pressure in Pa
     call getgb2(unit,0,j,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,  &
                 unpack,j,gfld,iret)
     if (iret /= 0) then
        write(*,*) k, "reading file p u iret=", iret
        stop
     end if
     u(:) = gfld%fld(:)
     ! wind v
     j = 0
     jpdt(2)  = pds2(2)
     jpdt(10) = pds10
     jpdt(12) = pds12(k)*100 ! pressure in Pa
     call getgb2(unit,0,j,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,  &
                 unpack,j,gfld,iret)
     if (iret /= 0) then
        write(*,*) k, "reading file p v iret=", iret
        stop
     end if
     v(:) = gfld%fld(:)

     ! wind speed
     speed(:) = sqrt(u*u+v*v)

     ! compare to wind max speed
     lp_i: do i = 1, nxy
        diff = speed(i) - speedmax(i)
        if( diff > 1.0) then
           if(pds12(k) > 100 .and. pds12(k) < 500) then
              write(*,"(I7,I7,A3,F8.2,F10.2,F10.2, a15)") i, pds12(k), "hPa", diff, speed(i), speedmax(i), "     --warning"
           else
              write(*,"(I7,I7,A3,F8.2,F10.2,F10.2)") i, pds12(k), "hPa", diff, speed(i), speedmax(i)
           end if
        end if
     end do lp_i

  end do lp_k

  deallocate(u)
  deallocate(v)
  deallocate(speed)
  deallocate(speedmax)

  call BACLOSE(unit, iret)
end program main
