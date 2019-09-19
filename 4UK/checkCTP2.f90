! for GRIB2
! check grid point of CTP mean value before and after grid 45 conversion

program main

  use grib_mod
  implicit none

  type(gribfield) :: gfld
  integer :: j,jpdtn,jgdtn
  integer,dimension(200) :: jids,jpdt,jgdt
  logical :: unpack=.true.
  integer :: jdisc                  ! discipline#, table 0.0(met:0 hydro:1 land:2)
  ! values of product def template needed to read data from GRIB 2 file
  type pdt_t
     integer :: npdt   ! number of template 4
     integer :: icat   ! catogory
     integer :: iprm   ! parameter
     integer :: ilev   ! type of level (code table 4.5)
  end type pdt_t
!  type(pdt_t), parameter ::  pdt_o = pdt_t(15,19,22,100) ! CAT
!  type(pdt_t), parameter ::  pdt_o = pdt_t(15,19,20,100) ! ICIP
  type(pdt_t), parameter ::  pdt_o = pdt_t(15,19,21,100) ! CTP
!   type(pdt_t), parameter ::  pdt_o = pdt_t(0,3,3,11) ! CB bottom
!   type(pdt_t), parameter ::  pdt_o = pdt_t(0,3,3,12) ! CB top
!   type(pdt_t), parameter ::  pdt_o = pdt_t(0,6,25,10) ! CB bottom

  integer :: day,month,year,hour,fhour

  integer, parameter :: nz=5 ! vertical layers
!  integer :: pds12(nz) = (/ 150, 200, 250,300,350, 400 /)  ! CAT
  integer :: pds12(nz) = (/ 300,400,500,600,700 /)  ! CTP
!  integer :: pds12(nz) = (/ 300,400,500,600,700,800 /)  ! ICIP
!  integer :: pds12(nz) = (/ 0 /)  ! CB

  character(len=256) :: datafile_m,datafile_45, datafile(2)
  integer :: unit, nx,ny, iret, i,k, n,ncount

  real, allocatable :: var(:,:)

  if ( COMMAND_ARGUMENT_COUNT() /= 2) then
     write(*,*) "Inputs: dataFileName_master dataFileName_45"
     stop
  end if

  ! parse file name from command line
  call GET_COMMAND_ARGUMENT(1, datafile_m)
  ! parse grid from command line
  call GET_COMMAND_ARGUMENT(2, datafile_45)
  datafile(1)=datafile_m
  datafile(2)=datafile_45

  unit = 100

!=========================================
  do n = 1, 2
!=========================================

  call BAOPENR(unit, datafile(n), iret)
  write(*,*) "check file= ", trim(datafile(n))

  if(allocated(var)) deallocate(var)

!-- set grid def template
  jgdtn = -1
!-- set product def array
  jgdt = -9999

! Set GRIB2 field identification values to search for
  jdisc = 0       ! discipline#, table 0.0(met:0 hydro:1 land:2)
!-- set id section
  jids  = -9999
!-- set product def array
  jpdt  = -9999

  lp_k: do k = 1, nz
     j = 0
     jpdtn    = pdt_o%npdt
     jpdt(1)  = pdt_o%icat
     jpdt(2)  = pdt_o%iprm
     jpdt(10) = pdt_o%ilev
     jpdt(12) = pds12(k)*100 ! pressure in Pa
     call getgb2(unit,0,j,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,  &
                 unpack,j,gfld,iret)
     if (iret /= 0) then
        write(*,*) k, "reading file iret=", iret
        stop
     end if

     nx = gfld%igdtmpl(8)
     ny = gfld%igdtmpl(9)
     if(.not. allocated(var)) allocate(var(nx,ny))
     var(:,:) = reshape(gfld%fld(:),[nx,ny])

     write(*,*) "layer, nx,ny=",pds12(k),nx,ny

     ! print out abnormal value
     do j = 1,ny
     do i = 1,nx
        if( var(i,j) < 0. .and. var(i,j) /= -0.002 .and. var(i,j) /= -0.004) then ! CTP
!        if( var(i,j) < 0. .and. var(i,j) /= -0.1) then ! CB ext
!        if( var(i,j) < 0. ) then
           write(*,*) "i,j,k var=",i,j,pds12(k),var(i,j)
        end if
     end do
     end do

  end do lp_k

!- date
  year  = gfld%idsect(6)
  month = gfld%idsect(7)
  day   = gfld%idsect(8)
  hour  = gfld%idsect(9)
!- forecast hour
  fhour=gfld%ipdtmpl(9)

  deallocate(var)
  call gf_free(gfld)

  call BACLOSE(unit, iret)

!=========================================
  end do
!=========================================
end program main
