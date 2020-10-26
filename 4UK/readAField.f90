! for GRIB2
program main

  use grib_mod
  implicit none


  type(gribfield) :: gfld
  integer :: j,jpdtn,jgdtn
  integer,dimension(200) :: jids,jpdt,jgdt
  logical :: unpack=.true.

  integer :: jdisc                  ! discipline#, table 0.0(met:0 hydro:1 land:2)
  ! integer :: pds1                 ! category#,   table 4.1
  integer :: pds(2) = (/ 1, 32 /)   ! name# (for temperature),       table 4.2
  integer :: pds10 = 100 ! level ID,    table 4.5

  integer, parameter :: nz=37
  integer :: pds12(nz)      ! level value, pressure in Pa

  character(len=256) :: datafile
  character(len=2) :: cgrid
  integer :: unit, nxy, iret, i, k

  real, allocatable :: t(:)

  nxy=1440*721
  do k =1, nz
     pds12(k) = 100. + (k-1)*25.
  end do

  if ( COMMAND_ARGUMENT_COUNT() /= 1) then
     write(*,*) "Inputs: dataFileName Grid#"
     stop
  end if

  ! parse file name from command line
  call GET_COMMAND_ARGUMENT(1, datafile)

  unit = 100
  call BAOPENR(unit, datafile, iret)

  allocate(t(nxy))

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
  jpdt(1) = pds(1)     ! category#,   table 4.1

  j  = 0               ! search from 0
  jpdt(2)  = pds(2)   ! name#,       table 4.2
  jpdt(10) = pds10  ! level ID,    table 4.5

  lp_k: do k = 2, nz
     ! temperature
     j = 0  
     jpdt(12) = pds12(k)*100 ! pressure in Pa
     call getgb2(unit,0,j,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,  &
                 unpack,j,gfld,iret)
     if (iret /= 0) then
        write(*,*) k, "reading file iret=", iret
        stop
     end if
     t(:) = gfld%fld(:)
     call gf_free(gfld)

     print *, t(10000)

  end do lp_k


  deallocate(t)

  call BACLOSE(unit, iret)
end program main
