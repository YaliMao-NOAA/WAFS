module smooth_imprintings
  use grib_mod
  use GDSWZD_MOD

  implicit none
  
  integer :: fillnumber
  integer :: nx, ny
  integer :: npts ! actual number of grid points of imprintings
  integer, allocatable :: ipts(:), jpts(:)

contains

!----------------------------------------------------------------------------
  subroutine getseams(seamfile, iret)
    implicit none

    character(*), intent(in) :: seamfile
    integer, intent(out) :: iret

    integer :: iunit, i
    character(30) :: line
    
    iunit = 33
    open(unit=iunit,file=seamfile,action='read', status='old', iostat=iret)
    if (iret /= 0) then
      write(*, *) 'Cannot open tile file ', trim(seamfile), ', iostat = ', iret
      return
    end if

    do
       read(iunit, '(a30)', iostat=iret) line
       if (iret < 0) then !loop breaks at the end of file/record
          iret = 0
          exit
       else if (iret > 0) then
          write(*, *) 'Error in reading tile line, iostat=', iret
          exit
       end if

       if(index(line,"fillnumber=")) then
          i = index(line, "=")
          read(line(i+1:),*) fillnumber
       end if
       if(index(line, "nx=") > 0) then
          i = index(line, "=")
          read(line(i+1:),*) nx
       end if
       if(index(line, "ny=") > 0) then
          i = index(line, "=")
          read(line(i+1:),*) ny
          exit
       end if
    end do

    write(*,*) "fillnumber=",fillnumber,"nx,ny=", nx,ny

    allocate(ipts(nx*ny))
    allocate(jpts(nx*ny))

    npts = 0
    read(iunit, '(a30)', iostat=iret) line ! read "i,j=" line
    do
       read(iunit, '(a30)', iostat=iret) line
       if (iret < 0) then !loop breaks at the end of file/record
          iret = 0
          exit
       else if (iret > 0) then
          write(*, *) 'Error in reading tile line, iostat=', iret
          exit
       end if

       npts = npts + 1
       read(line,*) ipts(npts), jpts(npts)
    end do

    write(*,*) "There are", npts, "of impringting grid points"

    close(iunit)

  end subroutine getseams


!----------------------------------------------------------------------------
  subroutine processgrib2(ifilename,ofilename,iret)
    use grib_mod

    implicit none

    character(*), intent(in) :: ifilename,ofilename
    integer, intent(out) :: iret

    integer :: iunit, iunitwrite

    integer, parameter :: msk1=32000

    integer :: lskip, lgrib             ! output of skgb()
    integer :: currlen
    CHARACTER(1), allocatable, dimension(:) :: cgrib
    integer :: lengrib                  ! output of baread()
    integer :: listsec0(3), listsec1(13)! output of gb_info 
    integer :: numfields, numlocal, maxlocal ! output of gb_info 
    logical :: unpack, expand           ! output of gf_getfld  

    integer :: iseek,n

    type(gribfield) :: gfld
    integer :: nflds

    real, allocatable :: newdata(:)

    allocate(newdata(nx*ny), stat=iret)
    if (iret /= 0) then  
       write(*,*) "fail to allocate array of newdata"
    else
       write(*,*) "sucess to allocate newdata", size(newdata), "iret=", iret, nx,ny
    end if

    unpack = .true.
    expand = .true.

    iunit = 12
    call baopenr(iunit, ifilename, iret)
    if (iret /= 0) then
       write(*, *) 'open file error: ', ifilename, ' iret=', iret
       return
    end if

    iunitwrite = 32
    call BAOPENW(iunitwrite, trim(ofilename), iret)
    if (iret /= 0) then
       write(*, *) 'open file error: ', trim(ofilename), ' iret=', iret
       return
    end if

    iseek = 0
    currlen = 0

    nflds = 0

    do
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
          write(*, *) 'ERROR querying GRIB2 message = ',iret
          stop 10
       endif

       nflds = nflds + numfields

       do n = 1, numfields
          call gf_getfld(cgrib, lengrib, n, unpack, expand, gfld, iret)
          if (iret /= 0) then
             write(*,*) 'ERROR extracting field = ', iret
             cycle
          end if

          write(*,*)  nflds, "records"

          if((gfld%ipdtmpl(1) == 19 .and. gfld%ipdtmpl(2) == 29) .or. &
             (gfld%ipdtmpl(1) == 19 .and. gfld%ipdtmpl(2) == 30)) then
             call smooth_field(fillnumber,npts,ipts,jpts,nx,ny,gfld%fld,newdata)
          else
             newdata = gfld%fld
          end if
          call writegb2(iunitwrite, gfld, nx*ny,newdata, iret)
       end do
    end do

    call BACLOSE(iunit, iret)
    call BACLOSE(iunitwrite, iret)

    deallocate(newdata)
    deallocate(ipts,jpts)

    return

  end subroutine processgrib2


!----------------------------------------------------------------------------
  subroutine writegb2(iunit, gfld, nxy,fld, iret)
    integer, intent(in) :: iunit
    type(gribfield), intent(in) :: gfld
    integer, intent(in) :: nxy
    real, intent(in) :: fld(nxy)     ! the data to be written
    integer, intent(out) :: iret

    CHARACTER(LEN=1),ALLOCATABLE,DIMENSION(:) :: CGRIB
    integer(4) :: lcgrib, lengrib
    integer :: listsec0(2)
    integer :: igds(5)
    real    :: coordlist=0.0
    integer :: ilistopt=0
    ! flexible arrays of template 4, 5                                                                                                                                         
    logical(kind=1), dimension(nx*ny) :: bmap
    integer :: ibmap ! indicator whether to use bitmap                                                                                                                         
!   ALLOCATE ARRAY FOR GRIB2 FIELD                                                                                                                                             
    lcgrib=gfld%ngrdpts*4
    allocate(cgrib(lcgrib),stat=iret)
    if ( iret /= 0 ) then
       print *, iret
       iret=2
    endif
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -                                                                                                        
!  CREATE NEW MESSAGE                                                                                                                                                          
    listsec0(1)=gfld%discipline
    listsec0(2)=gfld%version
    if ( associated(gfld%idsect) ) then
       call gribcreate(cgrib,lcgrib,listsec0,gfld%idsect,iret)
       if (iret .ne. 0) then
          write(*,*) ' ERROR creating new GRIB2 field = ',iret
       endif
    else
       print *, ' No Section 1 info available. '
       iret=10
       deallocate(cgrib)
       return
    endif
!  ADD GRID TO GRIB2 MESSAGE (Grid Definition Section 3)                                                                                                                       
    igds(1)=gfld%griddef    ! Source of grid definition (see Code Table 3.0)
    igds(2)=gfld%ngrdpts    ! Number of grid points in the defined grid.
    igds(3)=gfld%numoct_opt ! Number of octets needed for each additional grid points definition
    igds(4)=gfld%interp_opt ! Interpretation of list for optional points definition (Code Table 3.11)
    igds(5)=gfld%igdtnum    ! Grid Definition Template Number (Code Table3.1)
    if ( associated(gfld%igdtmpl) ) then
       call addgrid(cgrib, lcgrib, igds, gfld%igdtmpl, gfld%igdtlen,&
            ilistopt, gfld%num_opt, iret)
       if (iret == 0) then
          write(*,*) ' ERROR adding grid info = ',iret
       endif
    else
       print *, ' No GDT info available. '
       iret=11
       deallocate(cgrib)
       return
    endif

    bmap = .false.
    ibmap = 255
    ! call addfield
    call addfield(cgrib, lcgrib, gfld%ipdtnum, gfld%ipdtmpl, &
                  size(gfld%ipdtmpl), coordlist, gfld%num_coord, &
                  gfld%idrtnum, gfld%idrtmpl, size(gfld%idrtmpl), &
                  fld, gfld%ngrdpts, ibmap, bmap, iret)
    if (iret /= 0) then
       write(*,*) 'ERROR adding data field = ',iret
    endif
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -                                                                                                        
!  CLOSE GRIB2 MESSAGE AND WRITE TO FILE                                                                                                                                       
    call gribend(cgrib, lcgrib, lengrib, iret)
    call wryte(iunit, lengrib, cgrib)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -                                                                                                        
    deallocate(cgrib)

    return
  end subroutine writegb2


  subroutine smooth_field(fillnumber,npts,ipts,jpts,nx,ny,fld,newdata)
    implicit none
    integer, intent(in) :: fillnumber
    integer, intent(in) :: npts
    integer, intent(in) :: ipts(npts), jpts(npts)
    integer, intent(in) :: nx, ny
    real, intent(inout) :: fld(:)
    real, intent(inout) :: newdata(:)

    integer :: nrange, irange, jrange
    integer :: i,j,n, ii, jj, ij, iijj

    real :: sum
    real :: weight(20), avgweight(20)
    integer :: ncircle, nvalid

    integer :: ismooth,nsmooth

    nsmooth = 2

    do n = 1, npts
       i = ipts(n)
       j = jpts(n)
       ij = (j-1)*nx + i
       fld(ij) = 9.999E+10
    end do

    newdata = fld


    loop_ismooth: do ismooth = 1, nsmooth

       write(*,*) ismooth, "smooth"

       loop_n: do n = 1, npts
          i = ipts(n)
          j = jpts(n)
          ij = (j-1)*nx + i
          ncircle = 0
          avgweight = 0.0
          loop_nrange: do nrange = 1, fillnumber/2
             nvalid = 0
             sum = 0.0
             do jrange = -nrange, nrange
             do irange = -nrange, nrange
                if((abs(irange) == nrange .and. abs(jrange) <= nrange) .or. &
                   (abs(irange) <= nrange .and. abs(jrange) == nrange)) then
                   ii = i + irange
                   jj = j + jrange
                   if(jj < 1 .or. jj > ny) cycle
                   if( ii < 1) ii = ii + nx
                   if( ii > nx) ii = ii - nx
                   iijj = (jj-1)*nx + ii
                   if(fld(iijj) < 9999.) then
                      nvalid = nvalid + 1
                      sum = sum + fld(iijj)
                   end if
                end if
             end do
             end do
             if(nvalid > 0) then
                ncircle = ncircle + 1
                avgweight(ncircle) = sum/nvalid
             end if
          end do loop_nrange

          if(ncircle > 0) then
!             write(*,*) "circles=",i,j, ncircle, avgweight(1:ncircle)
             newdata(ij) = 0.
             do i = 1, ncircle
                weight(i) = ((ncircle - i)*2 + 1.0)/(1.0 * ncircle * ncircle)
                newdata(ij) = newdata(ij) + avgweight(i) * weight(i) 
             end do
          else
             write(*,*) i,j, "not filled"
          end if

       end do loop_n
       fld = newdata
    end do loop_ismooth

  end subroutine smooth_field

end module smooth_imprintings


program main
  use smooth_imprintings

  character(256) :: seamfile, grib2file, outgrib2file


  type(gribfield) :: gfld

  integer :: iret


  call GET_COMMAND_ARGUMENT(1, seamfile)
  call GET_COMMAND_ARGUMENT(2, grib2file)

  call getseams(trim(seamfile), iret)

  outgrib2file = "smoothed" // trim(grib2file)

  call processgrib2(trim(grib2file), trim(outgrib2file),iret)

end program main
