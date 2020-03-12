!###########################################################!
! in Grib2 version
! Convert icing on sigma level to pressure level
!   probability: -> potential, (19 233) => (19 20)
!     CIP: (potential*0.85=probability)
!     FIP: (potential*(0.84-0.033*fhour)=probability)
!   severity:    -> swap categories, sorted 'trace'
! Outputs are on pressure level
!
! Notes: 
!   1. processing and writing data have to be in the same
!   loop as reading to keep bitmap information of read-in gfld
!   2. process all levels if inputs are on pressure levels,
!      while process limited levels if on sigma levels.
!
!###########################################################!

program main

  use grib_mod
  implicit none



  ! parameter to read data
  integer :: icat, iprm
  real, allocatable :: data(:) ! data(nxy)
  integer :: iunit

  character(len=100) :: inputfile

  ! for reading grib2 data
  integer, parameter :: msk1=32000
  integer :: lskip, lgrib             ! output of skgb()
  integer :: currlen
  CHARACTER(1), allocatable, dimension(:) :: cgrib
  integer :: lengrib                  ! output of baread()
  integer :: listsec0(3), listsec1(13)! output of gb_info
  integer :: numfields, numlocal, maxlocal ! output of gb_info 
  logical :: unpack=.true., expand=.true.           ! output of gf_getfld
  type(gribfield) :: gfld
  integer :: iseek, k, n, level

  character(len=*), parameter :: myself = 'readGB2() '

  ! other variables
  integer :: nxy, iret, i,ncount

  ! ===========================================!
  ! take care of input arguments

  call GET_COMMAND_ARGUMENT(1, inputfile)
  icat = 19
  iprm = 36
!  iprm = 234

  ! ===========================================!
  ! read, process and output data in Grib2

  iunit = 20
  call baopenr(iunit, trim(inputfile), iret)

  iseek = 0
  currlen = 0
  loop_read: do

     call skgb(iunit, iseek, msk1, lskip, lgrib)
     if (lgrib == 0) exit    ! end loop at EOF or problem
     if (lgrib > currlen) then ! allocate cgrib if size is expanded.
        if (allocated(cgrib)) deallocate(cgrib)
        allocate(cgrib(lgrib), stat=iret)
        currlen = lgrib
     endif

     call baread(iunit, lskip, lgrib, lengrib, cgrib)
     if (lgrib /= lengrib) then
        print *,' degrib2: IO Error.'
        call errexit(9)
     endif

     iseek = lskip + lgrib
     ! GRIB MESSAGE starts at lskip+1

     ! Unpack GRIB2 field
     call gb_info(cgrib,lengrib,listsec0,listsec1,numfields,numlocal,maxlocal,iret)
     if (iret /= 0) then
        print *, myself, 'ERROR querying GRIB2 message = ',iret
        stop 10
     endif

!!! do the loop and read all data on each level
     loop_numfields: do n = 1, numfields
        call gf_getfld(cgrib, lengrib, n, unpack, expand, gfld, iret)
        if (iret /= 0) then
           print *, myself, 'ERROR extracting field = ', iret
           cycle
        end if

        ! allocate data(:) necessory
        if(.not. allocated(data)) then
           nxy = gfld%igdtmpl(8) * gfld%igdtmpl(9)
           allocate(data(nxy))
           data = 99999.9
        end if

        if_ipdtmpl: if(gfld%ipdtmpl(1)==icat .and. gfld%ipdtmpl(2)==iprm) then
           level = gfld%ipdtmpl(12) / (10 ** gfld%ipdtmpl(11))
           write(*,*) "data size=", size(gfld%fld)
           data(:) = gfld%fld
           ncount = 0
           do i = 1, nxy
              if((data(i) > 99999.)) then
                 ncount = ncount + 1
              elseif(data(i)/= 0. .and. data(i) /= 1. .and. &
                  data(i)/= 2. .and. data(i) /= 3. .and. &
                  data(i)/= 4. .and. data(i) /= 5. ) then
                 write(*,*) "Not integer icing severity", i, level, data(i)
              end if
!              if( data(i) /= 0.)  write(*,*) "sample value of icing severity", i, data(i), level, nxy
           end do
           if(ncount>0) print *, "On level=",level, ncount, " gridpoints have missing value"
        end if if_ipdtmpl

        call gf_free(gfld)
     end do loop_numfields

  end do loop_read

  if(allocated(data)) deallocate(data)

  call baclose(iunit,iret)

end program main
