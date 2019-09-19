!------------------------------------------------------------------------------
!
! MODULE: Satellite
!
! DESCRIPTION:
! Check whether satellite sensor numbers match GCIP configuration
! satellite sensor data: $DCOMROOT/us007003/*/mcidas/GLOBCOMPSSR.*00
! GCIP cfg: /gpfs/dell1/nco/ops/nw*/gfs.v*/parm/wafs/wafs_gcip_gfs.cfg
!
! REVISION HISTORY:
! March 2019
!
!------------------------------------------------------------------------------
MODULE Satellite

  IMPLICIT NONE

  PRIVATE
  PUBLIC match

  integer, parameter :: BYTE16=16, BYTE8=8, BYTE4=4, BYTE2=2, BYTE1=1
  real, parameter :: PI=3.14159265358979
  real, parameter :: R2D=180./PI, D2R=PI/180.

CONTAINS

  ! to check whether satellite sensor matches GCIP configration file, iret=-2 if no match
  ! to write out data in grib2
  subroutine match(satfile, cfgfile, iret)
    character(len=*), intent(in) :: satfile,cfgfile
    integer, intent(out) :: iret


    character(60) :: outfile

    integer :: kgds(200) ! satellite grid info
    real, allocatable :: brightness(:)

    integer :: numCFG, numSAT
    integer :: ssCFG(20) ! satellite sensors from GCIP configuration
    integer :: ssSAT(20) ! satellite sensors from satellite data

    integer :: i, j, k,ibrightness, ij

    logical :: existing

    integer(4), parameter :: nfld = 1
    real(4), allocatable :: data(:,:)
    integer(4), dimension(nfld) :: ncat,nparm,nlevtype,nlev,ifcsthr,npdt,nspatial
    character(len=60) :: typeproc
    integer(4) :: yyyy, mm, dd, hh
    integer(4) :: nxy,nx,ny

    iret = -1

    call readGCIPconfig(cfgfile,numCFG,ssCFG)
    if (numCFG <= 0) then
       write(*,*) "Error in reading GCIP configruation file", numCFG
       return
    end if

    call decodeMcIDAS(satfile,kgds,brightness,iret)
    if (iret /= 0) then
       write(*,*) "Error in decoding satellite data"
       return
    end if
    nx = kgds(2)
    ny = kgds(3)
    nxy = kgds(3)*kgds(2)

    ! set numSAT ssSAT
    numSAT = 0
    do ij = 1, nxy
       ibrightness=int(brightness(ij))
       if(ibrightness < 0 .or. ibrightness > 999) return
       if(numSAT == 0) then
          numSAT = numSAT + 1
          ssSAT(numSAT) = ibrightness
       else
          existing = .false.
          do k = 1, numSAT
             if(ibrightness == ssSAT(k)) then
                existing = .true.
             end if
          end do
          if(.not. existing) then             
             numSAT = numSAT + 1
             ssSAT(numSAT) = ibrightness
          end if
       end if
    end do

    call mysort(numCFG, ssCFG(1:numCFG))
    call mysort(numSAT, ssSAT(1:numSAT))

    write(*,'(a9,<numCFG>I4)') "cfg ss=",(ssCFG(i),i=1,numCFG)
    write(*,'(a9,<numSAT>I4)') "sat ss=",(ssSAT(i),i=1,numSAT)

    allocate(data(nxy,1))
    data(:,1) = brightness(:)
    npdt(1) = 0
    ncat(1) = 3
    nparm(1) = 0
    ifcsthr(1) = 0
    nlevtype(1) = 1
    nlev(1) = 0
    nspatial(1) = 0
    
    typeproc = "forecast"

    read(satfile(13:16),*,iostat=iret) yyyy
    read(satfile(17:18),*,iostat=iret) mm
    read(satfile(19:20),*,iostat=iret) dd
    read(satfile(21:22),*,iostat=iret) hh

    outfile = "sat" // satfile(13:22) // ".grib2"

    write(*,*) trim(outfile)

    call write_ndfd_grib2(data,nxy,nx,ny,nfld, &
         npdt,ncat,nparm,ifcsthr,nlevtype,nlev,nspatial, &
         typeproc,0, yyyy,mm,dd,hh,0,0,&
         0,outfile)

    iret = 0

    deallocate(brightness)
    deallocate(data)

  end subroutine match


  !----------------------------------------------------------------------------
  ! DESCRIPTION:
  !> Decode satellite in McIDAS, check against GCIP configuration file and 
  !> set iret=-2 if mismatching, meanwile write out data in grib2
  !
  !> @param[in]  cfgfile  - GCIP configuration file to check satellite sensor
  !> @param[in]  satfile  - satellite sensor data file to be decoded.
  !> @param[out] iret     - status; -1 if failure, -2 if mismatching
  !
  !----------------------------------------------------------------------------

  subroutine decodeMcIDAS(satfile,kgds,brightness,iret)
    implicit none
    character(len=*), intent(in) :: satfile
    integer, intent(out) :: kgds(:) ! satellite grid info
    real, allocatable, intent(out) :: brightness(:)
    integer, intent(out) :: iret


    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! header type and header
    type :: McIDAS_header_t
       integer :: year
       integer :: month
       integer :: date
       integer :: hour
       integer :: minute
       integer :: nx
       integer :: ny
       integer :: gapx
       integer :: gapy
       integer :: nBytes ! number of bytes per element 1/2/4
       integer :: nBands ! max number of bands per line
       integer :: nPrefix
       integer :: nPrefixDoc
       integer :: nPrefixCal
       integer :: nPrefixMap
       integer :: validity
       integer :: offsetData
       integer :: lengthData ! total data block length in bytes

       character(len=4) :: sourceType
       character(len=4) :: calibrationType
       character(len=4) :: originalSourceType

       integer :: ulImageLine    ! upper-left image line coordinate
       integer :: ulImageElement ! upper-left image element coordinate

       character(len=4) :: navigationType

       integer :: npImageLine    ! image line of the equator
       integer :: npImageElement ! image element of the normal longitude

       real :: stdlat
       real :: dx
    end type McIDAS_header_t
    type(McIDAS_header_t) :: header
    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! parameter
    integer, parameter :: IADIR_LEN = 64
    integer, parameter :: IANAV_LEN = 640
    integer, parameter :: IACAL_LEN = 128
    integer, parameter :: ITLEN = IADIR_LEN + IANAV_LEN + IACAL_LEN

    integer(kind=BYTE4) :: iarray(ITLEN)
    integer(kind=BYTE4) :: iadir(IADIR_LEN), ianav(IANAV_LEN), iacal(IACAL_LEN)
    integer(kind=BYTE1)   :: barray(4, ITLEN)
    equivalence(iarray, barray)
    equivalence(iarray, iadir)
    equivalence(iarray(IADIR_LEN+1), ianav)
    equivalence(iarray(IADIR_LEN+IACAL_LEN+1), iacal)

    integer(kind=BYTE1), allocatable :: b1Data(:)
    integer(kind=BYTE2), allocatable :: b2Data(:)
    integer(kind=BYTE4), allocatable :: b4Data(:)
    integer :: lengthAllData
    integer :: dataStartPoint

    integer :: iunit

    integer :: dd, mm, ss ! temporary variables for longitude, latitude DDD:MM:SS
    real :: stdlat, clon, dx, radius, rcos, ecc
    real :: rxp, ryp ! area coordination of natural origin 
    real :: lat, lon
    real :: dxp, dyp, arg

    integer :: i, ij

    iret = -1

    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! Step 1/2: Read and analyze the header
    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!

    iunit = 13
    open(unit=iunit,file=trim(satfile),status='old',access='direct',iostat=iret,recl=ITLEN*BYTE4)
    if(iret /= 0) return
    read(unit=iunit, rec=1, iostat=iret) (iarray(i), i=1, ITLEN)
    close(unit=iunit, iostat=iret)

    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! iadir(2) should always be 4; otherwise needs byte-swapping
    ! little endian <-> big endian
    if(iadir(2) /= 4) then
       barray(:,  1:24) = barray(BYTE4:1:-1, 1:24)  ! 25-32 ASCII, no swapping
       barray(:, 33:51) = barray(BYTE4:1:-1, 33:51) ! 52-53 ASCII, no swapping
       barray(:, 54:56) = barray(BYTE4:1:-1, 54:56) ! 57    ASCII, no swapping
       barray(:, 58:64) = barray(BYTE4:1:-1, 58:64)

       ! swap NAV block except 1st word
       barray(:, IADIR_LEN+2:IADIR_LEN+IANAV_LEN) = &
            barray(BYTE4:1:-1, IADIR_LEN+2:IADIR_LEN+IANAV_LEN) 

       ! swap CAL block if it exists.
       if(iadir(63) /= 0 ) then 
          barray(:, IADIR_LEN+IANAV_LEN+2:ITLEN) = &
               barray(BYTE4:1:-1, IADIR_LEN+IANAV_LEN+2:ITLEN)
       end if
    end if
       
    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! area directory block

    header% year = iadir(4)/1000 + 1900 ! YYDDD
    call m_yyddd2date(header% year, mod(iadir(4), 1000), header% month, header% date, iret)
    header% hour = iadir(5) / 10000
    header% minute = iadir(5)/100 - header% hour * 100

    header% ny = iadir(9)
    header% nx = iadir(10)

    header% gapy = iadir(12)
    header% gapx = iadir(13)

    header% nBytes = iadir(11)
    header% nBands = iadir(14)

    header% validity = iadir(36)

    header% nPrefix = iadir(15)
    header% nPrefixDoc = iadir(49)
    header% nPrefixCal = iadir(50)
    header% nPrefixMap = iadir(51)

    header% offsetData = iadir(34)
    header% lengthData = (header%nx * header%nBytes * header%nBands + header%nPrefix) * header%ny

    call m_int2string(iadir(52), header%sourceType)
    call m_int2string(iadir(53), header%calibrationType)
    call m_int2string(iadir(57), header%originalSourceType)

    header% ulImageLine = iadir(6)
    header% ulImageElement = iadir(7)

    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! navigation type
    call m_int2string(ianav(1), header%navigationType)

    header% npImageLine = ianav(2)
    header% npImageElement = ianav(3)

    lengthAllData = header% offsetData + header% lengthData
    if(mod(lengthAllData, header%nBytes) /= 0) then
       write(*,*) "McIDAS headers are in words, must times of 4"
       return
    end if

    if(header%nBytes == BYTE1) then
       allocate(b1Data(lengthAllData/header%nBytes), stat=iret)
    else if(header%nBytes == BYTE2) then
       allocate(b2Data(lengthAllData/header%nBytes), stat=iret)
    else if(header%nBytes == BYTE4) then
       allocate(b4Data(lengthAllData/header%nBytes), stat=iret)
    else
       return
    end if

    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! Step 2/2: Read data and set GDS
    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!

    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! read data into a 1-dimension array
    open(unit=iunit, file=satfile, status='old', access='direct', iostat=iret,recl=lengthAllData)
    if(header%nBytes == BYTE1) then
       read(unit=iunit, rec=1, iostat=iret) b1Data
    else if(header%nBytes == BYTE2) then
       read(unit=iunit, rec=1, iostat=iret) b2Data
    else if(header%nBytes == BYTE4) then
       read(unit=iunit, rec=1, iostat=iret) b4Data
    end if
    close(unit=iunit, iostat=iret)

    allocate(brightness(header%nx * header%ny), stat=iret)

    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! convert the 1-dimension array to 2-dimension array
    dataStartPoint = header% offsetData / header%nBytes
    do ij = 1, header%ny * header%nx
       if(header%nBytes == BYTE1) then
          brightness(ij) = b1Data(dataStartPoint + ij)
          IF(brightness(ij) < 0) THEN
             ! FORTRAN does not have unsigned one-byte integer (-128, 127)
             ! From 1-byte integer to 2-byte integer, the highest bit
             ! of a byte '1' is interpreted:
             !   1) -- a negative integer, for a one-byte integer
             !   2) -- 128 for a two or more byte integer
             brightness(ij)  = 256 + brightness(ij)
          END IF
       else if(header%nBytes == BYTE2) then
          brightness(ij) = b2Data(dataStartPoint + ij)
       else if(header%nBytes == BYTE4) then
          brightness(ij) = b4Data(dataStartPoint + ij)
       end if
    end do

    if(allocated(b1Data)) deallocate(b1Data)
    if(allocated(b2Data)) deallocate(b2Data)
    if(allocated(b4Data)) deallocate(b4Data)

    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! NAV block

    ! standard latitude    DDD::MM:SSS
    dd = ianav(4) / 10000
    mm = ianav(4) / 100 - dd * 100
    ss = ianav(4) - dd * 10000 - mm * 100
    stdlat = dd + mm/60. + ss/3600.

    ! BYTE4 longitude    DDD::MM:SSS
    ! If west postitive, make west negative.
    dd = ianav(6) / 10000
    mm = ianav(6) / 100 - dd * 100
    ss = ianav(6) - dd * 10000 - mm * 100
    clon = dd + mm/60. + ss/3600.
    if( ianav(10) >= 0 ) clon = -clon

    ! set pixel/grid spacing and earth radius and eccentricity
    dx = ianav(5) * header%gapx ! in metar
    radius = ianav(7)           ! in metar
    ecc = ianav(8)/1000000.
    ! Since dx may vary, calculate dx
    dx = PI * 2 * radius / header% nx

    ! area coordination of natural origin 
    rxp = real(ianav(3)-iadir(7)) / iadir(13) + 1.
    ryp = header%ny - real(ianav(2) - iadir(6)) / iadir(12)

    !~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!
    ! set GDS information
    kgds(:) = -1
    select case(trim(header%navigationType))
    case('MERC')

       rcos = radius * cos(stdlat * D2R)

       kgds(1) = 1 ! Mercator Projection Grid
       kgds(2) = header% nx
       kgds(3) = header% ny

       ! Compute lat/lon of the top-left corner.
       dxp   = 1. - rxp
       dyp   = header% ny - ryp
       arg   = EXP ( dx * dyp / rcos )
       lat = ( 2. * ATAN ( arg ) - PI/2.) * R2D
       lon = clon + ( dx * dxp / rcos ) * R2D
       call m_prnlon(lon)
       kgds(4) = lat * 1000
       kgds(5) = lon * 1000
       kgds(6) = 128
       ! Compute lat/lon of the bottom-right corner point.
       dxp = header% nx - rxp
       dyp = 1 - ryp
       arg = EXP ( dx * dyp / rcos )
       lat = ( 2. * ATAN ( arg ) - PI/2. ) * R2D
       lon = clon + ( dx * dxp / rcos ) * R2D
       call m_prnlon(lon)
       kgds(7) = lat * 1000
       kgds(8) = lon * 1000
       ! for global mosaic, longitude of the start may be close to that of the end
       if(kgds(8) - kgds(5) <= 5 * 1000.0) then
           kgds(5) = kgds(5) - 360 * 1000.0
       endif

       kgds(9) = stdlat
       ! scanning mode:
       ! Satellite data is stored from North/top to South/bottom
       !                          from West/left to East/right
       kgds(11) = 0 
       kgds(12) = dx  ! unit: meter
       kgds(13) = dx  ! unit: meter
       kgds(20) = 255

       iret = 0
       write(*,*) "Satellite GDS of", satfile, kgds(1:20)

    case default
       write(*,*) "Satellite Projection ", trim(header%navigationType), " isn't supported yet."
       iret = -1
    end select

    return
  end subroutine decodeMcIDAS
 

  !----------------------------------------------------------------------------
  ! DESCRIPTION:
  !> Interpret a word in integer to a string
  !
  !> @param[in]  number - a word of 4 bytes
  !> @param[out] cOut   - a len=4 string matching to each byte of number
  !----------------------------------------------------------------------------

  subroutine m_int2string(number, cOut)
    IMPLICIT NONE
    integer(kind=BYTE4), intent(in) :: number
    character(len=*), intent(out) :: cOut

    integer(kind=BYTE1) :: cNumber(BYTE4)
    integer :: aNumber, i

    equivalence(aNumber, cNumber) ! equivalence can not apply to a dummy argument

    aNumber = number

    do i = 1, BYTE4
       cOut(i:i) = char(cNumber(i))
    end do
  end subroutine m_int2string

  !----------------------------------------------------------------------------
  ! DESCRIPTION:
  !> convert the day of a year to month and date
  !
  !> @param[in]  year   - which year
  !> @param[in]  day    - day of the year
  !> @param[out] month  - the month of the year
  !> @param[out] date   - the date of the month
  !> @param[out] iret   - status; -1 if failure
  !
  !----------------------------------------------------------------------------
  subroutine m_yyddd2date(year, day, month, date, iret)
    IMPLICIT NONE
    integer, intent(in) :: year
    integer, intent(in) :: day
    integer, intent(inout) :: month
    integer, intent(inout) :: date
    integer, intent(out) :: iret

    integer :: daysInMonths(12) = (/ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 /)
    integer :: days(12)

    integer :: i

    if((year < 1900) .or. ((day < 0) .or. (day > 366))) then
       iret = -1
       return
    end if

    do i = 1, 12
       days(i) = sum(daysInMonths(1:i))
    end do

    ! if a leap year
    if((mod(year, 4) == 0 .and. mod(year, 100) /= 0) .or. &
       (mod(year, 400) == 0)) then
       days(2:) = days(2:) + 1
    end if

    do i = 1, 12
       if(day - days(i) <= 0) exit
    end do

    month = i
    date  = daysInMonths(i) - (days(i)-day)

    iret = 0
    return
  end subroutine m_yyddd2date

  !----------------------------------------------------------------------------
  ! DESCRIPTION:
  !> Make sure longitude to fall in [-180, 180]
  !
  !> @param[inout] dlon - longitude
  !
  !----------------------------------------------------------------------------
  subroutine m_prnlon(dlon)
    IMPLICIT NONE
    real, intent(inout) :: dlon

    real :: dln
    dln   = dlon - IFIX ( dlon / 360. ) * 360.
    IF ( dln  .lt. -180. ) dln = dln + 360.
    IF ( dln  .gt.  180. ) dln = dln - 360.
    dlon = dln
    return
  end subroutine m_prnlon

  subroutine readGCIPconfig(cfgfile,numSat,ss)
    implicit none
    character(len=*), intent(in) :: cfgfile
    integer,intent(out) :: numSat  ! number of satellite sensors
    integer,intent(out) :: ss(:) ! satellite sensors

    integer :: iunit
    integer :: i, iret
    character(256) :: line
    character(20) :: rawValues
    real :: longitude

    numSat = -1
    ss = -1

    iunit=30
    open(unit=iunit,file=trim(cfgfile),action='read', status='old', iostat=iret)
    if (iret /= 0) then
      write(*, *) 'Cannot open GCIP configuration file ', trim(cfgfile), ', iostat = ', iret
      return
    end if

    do
       read(iunit, '(a256)', iostat=iret) line
       if (iret < 0) then !loop breaks at the end of file/record
          iret = 0
          exit
       else if (iret > 0) then
          write(*, *) 'Error in reading GCIP cfg line, iostat=', iret
          exit
       end if
       if(index(line,"satellite_source =") > 0) then
          write(*,*)  trim(line)
          i = index(line, '=')
          line = line(i+1:)

          numSat = 0
          i = index(line,',')
          do while (i > 0)
             rawValues = line(1:i-1)
             line=line(i+1:)
             i = index(line,',')
             numSat = numSat + 1
             read(rawValues,*,iostat=iret) ss(numSat), longitude
          end do
          rawValues = line
          numSat = numSat + 1
          read(rawValues,*,iostat=iret) ss(numSat), longitude

          write(*,*) "In configuration, there are", numSat, "satellites:", ss(1:numSat)
          exit
       end if
    end do

  end subroutine readGCIPconfig

  subroutine mysort(n, arr)
    integer, intent(in) :: n
    integer, intent(inout) :: arr(n)

    integer :: i, j, key

    do i = 1, n
       key = arr(i)
       j = i-1

       ! Move elements of arr[1..i], that are greater than key,
       ! to one position ahead of their current position 
       do while (j >= 0 .and. arr(j) > key)
          arr(j+1) = arr(j)
          j = j-1
       end do

       arr(j+1) = key
    end do

  end subroutine mysort

END MODULE Satellite

program main

  use Satellite

  character(200) :: satfile, cfgfile
  integer :: iret

  call GET_COMMAND_ARGUMENT(1, satfile)
  call GET_COMMAND_ARGUMENT(2, cfgfile)

  call match(satfile, cfgfile, iret)
end program main
