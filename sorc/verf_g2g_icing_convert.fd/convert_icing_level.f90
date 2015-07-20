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

  ! The 6 vertical levels to be verficated.
  ! HybridLevels & PressHLevels are matching levels
  integer, parameter :: NLEVELS = 6
  integer, target :: HybridLevels(NLEVELS) = (/ 7315,  5792,  4267,  3048,  1828,  914 /)  ! in meter \
  integer, target :: PressHLevels(NLEVELS) = (/ 40000, 50000, 60000, 70000, 80000, 90000 /) ! in Pa   /

  ! parameter to read & write data
  integer :: icat, iprm, ilev
  real, allocatable :: data(:,:) ! data(nxy, vertical_levels)
  integer :: iunit, ounit

  ! input arguments
  character(len=100) :: inputfile, outputfile, args

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
  integer :: iseek, n, k, level

  character(len=*), parameter :: myself = 'readGB2() '

  ! other variables
  integer :: nxy, fhour, iret, i, lplevels
  integer, pointer :: piLevels(:), poLevels(:)
  character(2) :: cunit

  ! ===========================================!
  ! take care of input arguments

  call GET_COMMAND_ARGUMENT(1, inputfile)
  call GET_COMMAND_ARGUMENT(2, outputfile)
  call GET_COMMAND_ARGUMENT(3, args)
  read(args, *) icat
  call GET_COMMAND_ARGUMENT(4, args)
  read(args, *) iprm
  if(icat /= 19) stop "convert_icing_level: only works for icing"


  ! ===========================================!
  ! read, process and output data in Grib2

  ilev = 100   ! all outputs on pressure level (corresponding to flight levels)
  poLevels => PressHLevels   ! output on its corresponding pressure level

  iunit = 20
  ounit = 50
  call baopenr(iunit, trim(inputfile), iret)
  call BAOPENW(ounit,trim(outputfile),iret)

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

        ! allocate data(:,:) if necessory
        if(.not. allocated(data)) then
           nxy = gfld%igdtmpl(8) * gfld%igdtmpl(9)
           fhour = gfld%ipdtmpl(9)
           allocate(data(nxy, NLEVELS))
        end if

        if_ipdtmpl: if(gfld%ipdtmpl(1)==icat .and. gfld%ipdtmpl(2)==iprm) then

           if (gfld%ipdtmpl(10) == 100) then
              ! on pressure level
              cunit = "pa"
              lplevels = 1             ! process all levels, false loop for pressure levels
           elseif (gfld%ipdtmpl(10) == 102) then
              ! on sigma level
              cunit="m"
              lplevels = NLEVELS       ! process limited levels
           endif

           level = gfld%ipdtmpl(12) / (10 ** gfld%ipdtmpl(11))
           loop_lplevels: do k = 1, lplevels
              if_level: if((gfld%ipdtmpl(10) == 100) .or. &
                            ((gfld%ipdtmpl(10) == 102) .and. (level/10 == HybridLevels(k)/10)) ) then
                 print *, "Converted level=", level, " ", cunit
                 data(:, k) = gfld%fld

!!! assign data(:,:) at the appropriate level
                 if (iprm == 233) then		 ! probability
                    ! probability -> potential
                    ! Currently icing potentials are produced, 
                    ! while CIP and FIP produces probability, so conversion is needed.
                    if (fhour == 0) then ! CIP
                       data(:,k) = data(:,k) / 0.85
                    else                 ! FIP
                       data(:,k) = data(:,k) / (0.84-0.033*fhour)
                    end if
                 else if (iprm == 234) then          !severity
                    do i = 1, nxy
                       if(data(i,k) == 1. .or. data(i,k) == 2.) then
                          data(i,k) = data(i,k) + 1
                       elseif(data(i,k) == 4.) then
                          data(i,k) = 1
                       elseif(data(i,k) == 5.) then
                          data(i,k) = 4
                       end if
                    end do

                 end if


!!! output data
                 gfld%ipdtmpl(1)  = icat
                 if (iprm == 233) gfld%ipdtmpl(2)=20	! all probability outputs match GFS's ice potential
                 gfld%ipdtmpl(11) = 0    ! The last gf_getfld() may set gfld%ipdtmpl(11) to non-zero
                 if(gfld%ipdtmpl(10) == 102) gfld%ipdtmpl(12) = poLevels(k)
                 gfld%ipdtmpl(10) = ilev

                 gfld%fld = data(:,k)
                 call PUTGB2(ounit, gfld, iret)

                 exit
              end if if_level
           end do loop_lplevels
        end if if_ipdtmpl

        call gf_free(gfld)
     end do loop_numfields

  end do loop_read

  if(allocated(data)) deallocate(data)

  call baclose(iunit,iret)
  call baclose(ounit,iret)

end program main
