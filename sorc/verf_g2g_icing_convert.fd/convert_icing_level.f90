!###########################################################!
! in Grib2 version
! Convert icing on sigma level to pressure level
!
! This program takes 3 products on sigma level (102)
!   1) icing probabilty       (19 233)
!   2) icing potential        (19 20)
!   3) icing severity         (19 234)
! will do the following:
!   1) convert to potential (potential*0.85=probability)
!      change (19 233) => (19 20)
!      output on its corresponding pressure level
!   2) output on its corresponding pressure level
!   3) output on its corresponding pressure level
!
!###########################################################!

program main

  use grib_mod
  implicit none

  ! The 6 vertical levels to be verficated.
  ! HybridLevels & PressHLevels are matching levels
  integer, parameter :: NLEVELS = 6
  integer, target :: HybridLevels(NLEVELS) = (/ 7315,5486,4267,3048,1828,914 /) ! in meter \
  integer, target :: PressHLevels(NLEVELS) = (/ 400, 500, 600, 700, 800, 900 /) ! in hPa   /
  integer, pointer :: pLevles(:)

  ! parameter to read & write data
  integer :: icat, iprm, ilev
  real, allocatable :: data(:,:) ! data(nxy, vertical_levels)
  integer :: iunit, ounit

  ! input arguments
  character(len=100) :: filename, output, ctmp

  ! for reading grib2 data
  integer, parameter :: msk1=32000
  integer :: lskip, lgrib             ! output of skgb()
  integer :: currlen
  CHARACTER(1), allocatable, dimension(:) :: cgrib
  integer :: lengrib                  ! output of baread()
  integer :: listsec0(3), listsec1(13)! output of gb_info
  integer :: numfields, numlocal, maxlocal ! output of gb_info 
  logical :: unpack=.true., expand           ! output of gf_getfld
  type(gribfield) :: gfld
  integer :: iseek, n, k, level

  character(len=*), parameter :: myself = 'readGB2() '

  ! other variables
  integer :: nxy, fhour, iret
  integer, pointer :: pLevels(:)

  pLevels => HybridLevels    ! read on sigma level

  ! ===========================================!
  ! take care of input arguments

  call GET_COMMAND_ARGUMENT(1, filename)
  call GET_COMMAND_ARGUMENT(2, output)
  call GET_COMMAND_ARGUMENT(3, ctmp)
  read(ctmp, *) icat
  call GET_COMMAND_ARGUMENT(4, ctmp)
  read(ctmp, *) iprm
  if(icat /= 19) stop "convert_icing_level: only works for icing"
  ilev = 102 ! on sigma level

  iunit = 20
  ounit = 50

  ! ===========================================!
  ! read in data in Grib2

  iseek = 0
  currlen = 0
  call baopenr(iunit, trim(filename), iret)
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

     ! do the loop and read all data on each level
     loop_numfields: do n = 1, numfields
        call gf_getfld(cgrib, lengrib, n, unpack, expand, gfld, iret)
        if (iret /= 0) then
           print *, myself, 'ERROR extracting field = ', iret
           cycle
        end if

        ! allocate data(:,:) if necessory
        if(.not. allocated(data)) then
           nxy = gfld%igdtmpl(8) * gfld%igdtmpl(9)
           fhour = gfld%ipdtmpl(9)
           allocate(data(nxy, NLEVELS))
        end if

        ! assign data(:,:) at the appropriate level
        if(gfld%ipdtmpl(1)==icat .and. gfld%ipdtmpl(2)==iprm .and. gfld%ipdtmpl(10)==ilev) then
           do k = 1, NLEVELS
              level = gfld%ipdtmpl(12) / 10 ** gfld%ipdtmpl(11)
              if(level == pLevels(k)) then
                 print *, "Converted level=", level, "m"
                 data(:, k) = gfld%fld
                 exit
              end if
           end do
        end if

     end do loop_numfields

  end do loop_read

  call baclose(iunit,iret)

  ! probability -> potential
  ! Currently icing potentials are produced, 
  ! while CIP and FIP produces probability, so conversion is needed.
  if (iprm == 233) then		 ! probability
     if (fhour == 0) then ! CIP
        data(:,:) = data(:,:) / 0.85
     else                 ! FIP
        data(:,:) = data(:,:) / (0.84-0.033*fhour)
     end if
  end if

  !******************************************************
  ! output data
  !******************************************************
  pLevels => PressHLevels   ! output on its corresponding pressure level

  call BAOPENW(ounit,output,iret)

  if (iprm == 233) iprm=20	! all outputs match GFS's ice potential
  ilev = 100   ! all outputs on pressure level, corresponding to flight levels

  gfld%ipdtmpl(1)  = icat
  gfld%ipdtmpl(2)  = iprm
  gfld%ipdtmpl(10) = ilev
  gfld%ipdtmpl(11) = 0    ! The last gf_getfld() may set gfld%ipdtmpl(11) to non-zero

  do k=1,NLEVELS
     gfld%ipdtmpl(12) = pLevels(k) * 100 ! in Pa
     gfld%fld = data(:,k)
     call PUTGB2(ounit, gfld, iret)
  end do

  call baclose(ounit,iret)

  call gf_free(gfld)

  deallocate(data)

end program main
