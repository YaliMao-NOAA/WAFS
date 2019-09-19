! for GRIB2
! check how many grid points with CAT mean/max greater than 0. and  less than 3.5

program main

  use grib_mod
  implicit none

  real, parameter :: CAT3D5 = 3.5

  type(gribfield) :: gfld
  integer :: j,jpdtn,jgdtn
  integer,dimension(200) :: jids,jpdt,jgdt
  logical :: unpack=.true.

  integer :: jdisc                  ! discipline#, table 0.0(met:0 hydro:1 land:2)
  ! integer :: pds1                 ! category#,   table 4.1
  integer :: pds2(2) = (/ 19, 22 /) ! name#,       table 4.2
  integer :: pds10 = 100            ! level ID,    table 4.5

  integer, parameter :: nz=6        ! 6 vertical CAT layers
  integer :: pds12(nz) = (/ 150, 200, 250, 300, 350, 400 /)     ! level value, pressure in Pa

  integer, parameter :: nxy = 288 * 145

  character(len=256) :: datafile
  integer :: unit, iret, i, k

  real, allocatable :: catmn(:), catmax(:)
  integer :: nmn, nmax

  if ( COMMAND_ARGUMENT_COUNT() /= 1) then
     write(*,*) "Inputs: dataFileName "
     stop
  end if

  ! parse file name from command line
  call GET_COMMAND_ARGUMENT(1, datafile)

  unit = 100
  call BAOPENR(unit, datafile, iret)

  allocate(catmn(nxy))
  allocate(catmax(nxy))

  j        = 0          ! search from 0
  jdisc    = 0          ! for met field:0 hydro: 1, land: 2
  jids(:)  = -9999
  !-- set product defination template 4
  jpdtn    = -1         ! number of product defination template 4
  jpdt(:)  = -9999
  jpdt(1)  = pds2(1)   ! category
  jpdt(2)  = pds2(2)   ! parameter number
  jpdt(10) = pds10   ! type of level (code table 4.5)
!   jpdt(12) = pres_level ! level value
  !-- set grid defination template/section 3
  jgdtn    = -1
  jgdt(:)  = -9999

  nmn = 0
  nmax = 0
  lp_k: do k = 1, nz
     jpdt(12) = pds12(k)*100 ! pressure in Pa
     ! cat mean
     jpdt(16) = 0
     call getgb2(unit,0,j,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,  &
                 unpack,j,gfld,iret)
     if (iret /= 0) then
        write(*,*) k, "reading file cat mean iret=", iret
 print *, jpdt(:16)
       stop
     end if
     catmn(:) = gfld%fld(:)
     ! cat max 
     jpdt(16) = 2
     call getgb2(unit,0,j,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,  &
                 unpack,j,gfld,iret)
     if (iret /= 0) then
        write(*,*) k, "reading file cat max iret=", iret
        stop
     end if
     catmax(:) = gfld%fld(:)

     ! search for max mean <= CAT3D5
     lp_i: do i = 1, nxy
        if( catmn(i) > 0. .and. catmn(i) <= CAT3D5) nmn = nmn + 1
        if( catmax(i) > 0. .and. catmax(i) <= CAT3D5) nmax = nmax + 1
     end do lp_i

  end do lp_k

  print *,  nmn, "grid points of CAT mean",  nmax, "grid points of CAT max"

  deallocate(catmn)
  deallocate(catmax)

  call BACLOSE(unit, iret)
end program main
