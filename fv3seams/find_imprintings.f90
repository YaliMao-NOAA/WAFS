module find_imprintings
  use grib_mod
  use GDSWZD_MOD
contains
!----------------------------------------------------------------------------
  subroutine readnc(fillnumber, v, tilefile, kgds, mosaicdata, iret)
    implicit none

    integer, intent(in) :: fillnumber
    integer, intent(in) :: v
    character(*), intent(in) :: tilefile
    integer, intent(in) :: kgds(:)
    real, intent(inout) :: mosaicdata(:)
    integer, intent(out) :: iret

    integer :: iunit
    character(256) :: line

    real(4), allocatable :: lat(:), lon (:)
    integer :: nx, ny, n, ncount, i,j,ij

    integer :: iopt
    real :: fill = -9999.0
    real, allocatable :: xpts(:,:), ypts(:,:)
    integer :: nret

    integer :: ix,jy,nxnew, nynew

    integer :: ic, jc, ii,jj, istart, iend, jstart, jend
    
    iunit = 33
    open(unit=iunit,file=tilefile,action='read', status='old', iostat=iret)
    if (iret /= 0) then
      write(*, *) 'Cannot open tile file ', trim(tilefile), ', iostat = ', iret
      return
    end if

    do
       read(iunit, '(a256)', iostat=iret) line
       if (iret < 0) then !loop breaks at the end of file/record
          iret = 0
          exit
       else if (iret > 0) then
          write(*, *) 'Error in reading tile line, iostat=', iret
          exit
       end if

       if(index(line, "nxp =") > 0) then
          write(*,*) trim(line)
          i = index(line, "=")
          read(line(i+1:),*) nx
          write(*,*) "nx=", nx
       end if
       if(index(line, "nyp =") > 0) then
          write(*,*) trim(line)
          i = index(line, "=")
          read(line(i+1:),*) ny
          write(*,*) "ny=", ny
          exit
       end if
    end do

    allocate(lat(nx*ny))
    allocate(lon(nx*ny))

    do
       read(iunit, '(a256)', iostat=iret) line
       if(index(line, " x =") > 0) then
          n = 1
          do
             read(iunit, '(a256)', iostat=iret) line
             if(index(line, ";") > 0) then
                ncount=countString(line,",") + 1
                read(line,*) (lon(i), i=n,n+ncount-1)
                write(*,*) trim(line)
                write(*,*) "lon=",lon(n:n+ncount-1)
                write(*,*) "lon nxy=", n+ncount-1
                exit
             else
                ncount=countString(line,",")
                read(line,*) (lon(i), i=n,n+ncount-1)
                n = n + ncount
             end if
          end do
       end if

       if(index(line, " y =") > 0) then
          n = 1
          do
             read(iunit, '(a256)', iostat=iret) line
             if(index(line, ";") > 0) then
                ncount=countString(line,",") + 1
                read(line,*) (lat(i), i=n,n+ncount-1)
                write(*,*) trim(line)
                write(*,"(A,F15.10)") "lat=",lat(n:n)
                write(*,*) "lat nxy=", n+ncount-1
                exit
             else
                ncount=countString(line,",")
                read(line,*) (lat(i), i=n,n+ncount-1)
                n = n + ncount
             end if
          end do
          exit
       end if
    end do

    iopt = -1
    allocate(xpts(nx,ny))
    allocate(ypts(nx,ny))

    call GDSWZD(kgds, iopt, nx*ny,fill,xpts,ypts,lon,lat,nret)
    
    nxnew = kgds(2)
    nynew = kgds(3)
    do j = 1, ny
    do i = 1, nx
       if(xpts(i,j) < 0. .or. ypts(i,j) < 0) cycle

       if(mod(fillnumber, 2) == 0) then
          ic = floor(xpts(i,j))
          jc = floor(ypts(i,j))
          if(fillnumber==4 .and. abs(lat((j-1)*nx+i)) <= 30.) then
             ! use 2 grid points
             istart = -((fillnumber-2-1)/2)
             iend = (fillnumber-2)/2
          else
             istart = -((fillnumber-1)/2)
             iend = fillnumber/2
          end if
       else
          ic = xpts(i,j)
          jc = ypts(i,j)
          istart = - fillnumber/2
          iend = fillnumber/2
       end if
       jstart = istart
       jend = iend

       do jy = jstart, jend
          jj = jy + jc
          if( jj < 1 ) jj = 1
          if( jj > nynew) jj = nynew
          do ix = istart, iend
             ii = ix + ic
             if(ii < 1) ii = ii + nxnew
             if(ii > nxnew) ii = ii - nxnew
             ij = (jj - 1) * nxnew + ii
             if(mosaicdata(ij) < 0. .or. mosaicdata(ij) == v) then
                mosaicdata(ij) = v
             else
                mosaicdata(ij) = mosaicdata(ij) + v+10
             end if
          end do
       end do
    end do
    end do

    deallocate(lat, lon)
    deallocate(xpts, ypts)

    close(iunit)
  end subroutine readnc

!----------------------------------------------------------------------------
  recursive function countString(string, char) result (n)
    character(*), intent(in) :: string, char
    integer :: n

    integer :: i

    i=index(string,char)
    if(i == 0) then
       n = 0
       return
    else
       n=1+countString(string(i+1:), char)
    end if

  end function countString


!----------------------------------------------------------------------------
  subroutine readgb2(filename, gfld, kgds, iret)
    character(*), intent(in) :: filename
    type(gribfield), intent(out) :: gfld
    integer, intent(out) :: kgds(:)
    integer, intent(out) :: iret

    integer :: iunit

    integer, parameter :: msk1=32000

    integer :: lskip, lgrib             ! output of skgb()
    integer :: currlen
    CHARACTER(1), allocatable, dimension(:) :: cgrib
    integer :: lengrib                  ! output of baread()
    integer :: listsec0(3), listsec1(13)! output of gb_info 
    integer :: numfields, numlocal, maxlocal ! output of gb_info 
    logical :: unpack, expand           ! output of gf_getfld  

    integer :: iseek, n

    unpack = .false.
    expand = .false.

    iret = -1

    iunit = 12
    call baopenr(iunit, filename, iret)
    if (iret /= 0) then
       write(*, *) 'open file error: ', filename, ' iret=', iret
       return
    end if

    iseek = 0
    currlen = 0

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


       ! only need to find one valid field, any field
       do n = 1, numfields
          call gf_getfld(cgrib, lengrib, n, unpack, expand, gfld, iret)
          if (iret /= 0) then
             write(*,*) 'ERROR extracting field = ', iret
             cycle
          end if
          iseek = -1 ! one valid field is found, no more seeking 
          exit
       end do

       call m_pdt2gds(gfld, kgds)

       if(iseek == -1) exit
    end do

    write(*,*) "kgds=", kgds(1:20)

    call BACLOSE(iunit, iret)

    return

  end subroutine readgb2


!----------------------------------------------------------------------------
  subroutine writegb2(filename, gfld, fld, nxy, iret)
    implicit none

    character(*), intent(in) :: filename
    type(gribfield), intent(in) :: gfld
    integer, intent(in) :: nxy
    real(4), intent(in) :: fld(nxy)     ! the data to be written
    integer, intent(out) :: iret

    integer :: iunit

    CHARACTER(LEN=1),ALLOCATABLE,DIMENSION(:) :: CGRIB
    integer(4) :: lcgrib, lengrib
    integer :: listsec0(2)
    integer :: igds(5)
    real    :: coordlist=0.0
    integer :: ilistopt=0
    ! flexible arrays of template 4, 5                                                                                                                                         
    logical(kind=1), dimension(nxy) :: bmap
    integer :: ibmap ! indicator whether to use bitmap                                                                                                                         
    iunit = 32
    call BAOPENW(iunit, trim(filename), iret)
    if (iret /= 0) then
       write(*, *) 'open file error: ', trim(filename), ' iret=', iret
       return
    end if

!   change template 4 for simplifying sample grib2
    gfld%ipdtmpl(1) = 3
    gfld%ipdtmpl(2) = 5
    gfld%ipdtmpl(10) = 1


!   ALLOCATE ARRAY FOR GRIB2 FIELD                                                                                                                                             
    lcgrib=gfld%ngrdpts*4
    allocate(cgrib(lcgrib),stat=iret)
    if ( iret.ne.0 ) then
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
       if (iret.ne.0) then
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

    gfld%idrtmpl(1) = 0
    gfld%idrtmpl(2) = 0

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

    call BACLOSE(iunit, iret)
    return
  end subroutine writegb2


!----------------------------------------------------------------------------
  subroutine m_pdt2gds(gfld, kgds)
    implicit none
    type(gribfield), intent(in) :: gfld
    integer, intent(out) :: kgds(:)

    ! call gdt2gds() (in g2 module) to get kgds used by gdswzd_mod() (in ip module)
    integer :: igds(5), igrid
    integer :: ideflist(1)
    integer :: iret

    igds(1) = gfld%griddef
    igds(2) = gfld%ngrdpts
    igds(3) = gfld%numoct_opt
    igds(4) = gfld%interp_opt
    igds(5) = gfld%igdtnum
    CALL gdt2gds(igds, gfld%igdtmpl, 0, ideflist, kgds, igrid, iret)

    return
  end subroutine m_pdt2gds


!----------------------------------------------------------------------------
  subroutine points2fill(outtext, fillnumber,nx, ny, mosaicdata)
    character(*), intent(in) :: outtext
    integer, intent(in) :: fillnumber
    integer, intent(in) :: nx, ny
    real, intent(inout) :: mosaicdata(:)

    integer :: ipts(nx*ny), jpts(nx*ny)
    integer :: i, n, iunit

    iunit = 43

    open(unit=iunit,file=outtext,action='write', status='UNKNOWN', iostat=iret)

    write(iunit,"(A, I2)") "fillnumber=", fillnumber
    write(iunit,"(A, I5)") "nx=",nx
    write(iunit,"(A, I5)") "ny=",ny
    write(iunit,*) "i,j="

    n = 0
    do i = 1, nx*ny
       if(mosaicdata(i) > 6) then
          mosaicdata(i) = 1
          n = n + 1
          ipts(n) = mod(i-1, nx) + 1
          jpts(n) = (i-ipts(n))/nx + 1
          write(iunit, "(I6, I6)") ipts(n), jpts(n)
       else
          mosaicdata(i) = 0
       end if
    end do

    close(iunit)

  end subroutine points2fill

end module find_imprintings


program main
  use find_imprintings

  character(500) :: grib2file, tilefile, outputfile, outtext
  integer :: fillnumber, ntilefile

  integer :: iret, i, nx, ny, nxy
  type(gribfield) :: gfld
  integer :: kgds(200)

  real, allocatable :: mosaicdata(:)

  outputfile="mosaictiles.grib2"
  outtext="imprintings.txt"

  call GET_COMMAND_ARGUMENT(1, grib2file)
  read(grib2file,*) fillnumber

  call GET_COMMAND_ARGUMENT(2, grib2file)

  call readgb2(trim(grib2file), gfld, kgds, iret)

  nx = gfld%igdtmpl(8)
  ny = gfld%igdtmpl(9)
  nxy = nx*ny
  allocate(mosaicdata(nxy))
  mosaicdata = -1

  call GET_COMMAND_ARGUMENT(3, tilefile)
  read(tilefile,*) ntilefile

  write(*,*) ntilefile, " tile(s)"

  do i = 1, ntilefile
     call GET_COMMAND_ARGUMENT(3+i, tilefile)
     call readnc(fillnumber,i, trim(tilefile),kgds,mosaicdata, iret)
     write(*,*) i, "tile file=", trim(tilefile)
  end do

  call points2fill(trim(outtext),fillnumber,nx,ny,mosaicdata)

  call writegb2(trim(outputfile), gfld, mosaicdata, nxy, iret)

  deallocate(mosaicdata)

end program main
