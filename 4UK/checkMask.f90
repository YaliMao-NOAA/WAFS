!###########################################################!
! in Grib2 version
!
!   check 2 Grib2 files have the same underground mask
!
!###########################################################!

program main

  use grib_mod
  implicit none



  ! parameter to read data
  integer :: icat, iprm, ilev, level, levels(38)
  real, allocatable :: data(:) ! data(nxy)
  integer :: iunit1, iunit2
  character(len=100) :: inputfile1, inputfile2

  integer :: nx,ny, nxy,iret, i,n

  type(gribfield) :: gfld1, gfld2
  integer j,jdisc,jpdtn,jgdtn
  integer,dimension(200) :: jids,jpdt,jgdt
  logical :: unpack

  levels(1) = 70
  do i = 1, 37
     levels(i+1) = 100+(i-1)*25
  end do

  icat = 19
  iprm = 36
!  iprm = 234

  ! ===========================================!
  ! take care of input arguments

  call GET_COMMAND_ARGUMENT(1, inputfile1)
  read(inputfile1,*) icat
  call GET_COMMAND_ARGUMENT(2, inputfile1)
  read(inputfile1,*) iprm
  call GET_COMMAND_ARGUMENT(3, inputfile1)
  call GET_COMMAND_ARGUMENT(4, inputfile2)
  print *, icat, iprm

  ! ===========================================!
  ! read, process and output data in Grib2

  iunit1 = 20
  iunit2 = 21
  call baopenr(iunit1, trim(inputfile1), iret)
  print *, "open iret1=", iret
  call baopenr(iunit2, trim(inputfile2), iret)
  print *, "open iret2=", iret

  j = 0
  jdisc = 0
  jids(:)  = -9999

  jpdtn = -1

  jpdt(:)  = -9999
  jpdt(1)  = icat
  jpdt(2)  = iprm

  jgdtn    = -1
  jgdt(:)  = -9999
  unpack=.true.

  do n = 1, 38

     jpdt(12) = levels(n) * 100

     call getgb2(iunit1, 0, j, jdisc, jids, jpdtn, jpdt, &
                jgdtn, jgdt, unpack, j, gfld1, iret)


     call getgb2(iunit2, 0, j, jdisc, jids, jpdtn, jpdt, &
                jgdtn, jgdt, unpack, j, gfld2, iret)

     nx = gfld1%igdtmpl(8)
     ny = gfld1%igdtmpl(9)
     print *, "nx, ny=", nx,ny

     do i = 1, nx*ny
        if((gfld1%fld(i) > 9999.9 .and. gfld2%fld(i) < 9999.9) .or. &
           (gfld1%fld(i) < 9999.9 .and. gfld2%fld(i) > 9999.9)) then
           print *, "mismatch mask ", i, gfld1%fld(i), gfld2%fld(i)
        end if
     end do

     call gf_free(gfld1)
     call gf_free(gfld2)

  end do

  call baclose(iunit1,iret)
  call baclose(iunit2,iret)

end program main
