  subroutine getseams(seamfile,fillnumber,npts,ipts,jpts)
      use gtg_ctlblk, only: SPVAL, printflag,iprt
    implicit none

    character(*), intent(in) :: seamfile
    integer, intent(out) :: fillnumber
    integer, intent(inout) :: npts
    integer, intent(out) :: ipts(npts),jpts(npts)

    integer :: iret

    integer :: iunit, i
    character(30) :: line

    if(printflag>=1) then
      write(iprt, *) "enter getseams"
      write(iprt, *) "seamfile=", seamfile
      write(iprt, *) "npts=",npts
    endif

!   iunit = 23
!   --- Find a free unit number and open the file for read access
    call find_free_unit(iunit)
    if(iunit <= 0) then
       write(iprt,*) 'error finding free unit in getseams'
       write(iprt,*) 'iunit=',iunit
       write(iprt,*) 'ABORT'
       call abort
    endif
    open(unit=iunit,file=seamfile,action='read', status='old',form='formatted', iostat=iret)
    if (iret /= 0) then
      write(iprt, *) 'Cannot open tile file ', trim(seamfile), ', iostat = ', iret
      write(iprt, *) 'ABORT'
      call abort
    end if

    npts = 0
    do
       read(iunit, '(a30)', iostat=iret) line
       if (iret < 0) then !loop breaks at the end of file/record
          iret = 0
          exit
       else if (iret > 0) then
          write(iprt, *) 'Error in reading tile line, iostat=', iret
          exit
       end if

       if(index(line,"fillnumber=") > 0) then
          i = index(line, "=")
          read(line(i+1:),*) fillnumber
       end if

       if(index(line,"i,j=") > 0) then
          exit ! To have another loop to read gridpoints
       end if
    end do

    do
       read(iunit, '(a30)', iostat=iret) line
       if (iret < 0) then !loop breaks at the end of file/record
          iret = 0
          exit
       else if (iret > 0) then
          write(iprt, *) 'Error in reading tile line, iostat=', iret
          exit
       end if

       npts = npts + 1
       read(line,*) ipts(npts), jpts(npts)
    end do

    close(iunit)

    if(printflag>=1) then
      write(iprt, *) "exit  getseams"
      write(iprt, *) "fillnumber=", fillnumber
      write(iprt, *) "There are", npts, "of imprinting grid points"
    endif

  end subroutine getseams


  subroutine gtg_smoothseams(ismooth,IM,JM,jsta_2L,jend_2U,jsta,jend,fillnumber,npts,ipts,jpts,SPVAL,fld)
    implicit none
    integer, intent(in) :: ismooth
    integer, intent(in) :: IM,JM,jsta_2L,jend_2U,jsta,jend
    integer, intent(in) :: fillnumber
    integer, intent(in) :: npts
    integer, intent(in) :: ipts(npts), jpts(npts)
    real,intent(in) :: SPVAL
    real, intent(inout) :: fld(IM,jsta_2l:jend_2u)

    real :: fldseam(IM,jsta_2l:jend_2u)

    integer :: nrange, irange, jrange
    integer :: i,j,n, ii, jj

    real :: sum
    real :: weight(20), avgweight(20)
    integer :: icircle, ncircle, nvalid

    if(fillnumber > 4) then
       write(*,*) "The seam filling area exceeds UPP halo", fillnumber
       return
    end if

    ! For first round of smoothing, mark missing in imprinting gridpoints
    ! For later round of smoothing, keep input values
    fldseam = fld
    if (ismooth == 1) then
       do n = 1, npts
          i = ipts(n)
          j = jpts(n)
          if(j >= jsta_2l .and. j <= jend_2u) fldseam(i,j) = SPVAL
       end do
    end if

    loop_n: do n = 1, npts
       i = ipts(n)
       j = jpts(n)
       ! j can't be 1 or JM since seams occur in low-med latitue area
       if(j < jsta .or. j > jend) cycle
       ncircle = 0
       avgweight(:) = 0.0
       weight(:) = 0.0
       loop_nrange: do nrange = 1, fillnumber/2
          nvalid = 0
          sum = 0.0
          do jrange = -nrange, nrange
          do irange = -nrange, nrange
             if((abs(irange) == nrange .and. abs(jrange) <= nrange) .or. &
                (abs(irange) <= nrange .and. abs(jrange) == nrange)) then
                ii = i + irange
                jj = j + jrange
                if( ii < 1) ii = ii + IM
                if( ii > IM) ii = ii - IM
                if(fldseam(ii,jj) /= SPVAL) then
                   nvalid = nvalid + 1
                   sum = sum + fldseam(ii,jj)
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
!             print *,  "circles=",i,j, ncircle, avgweight(1:ncircle)
          fld(i,j) = 0.
          do icircle = 1, ncircle
             weight(icircle) = ((ncircle - icircle)*2 + 1.0)/(1.0 * ncircle * ncircle)
             fld(i,j) = fld(i,j) + avgweight(icircle) * weight(icircle)
          end do
!       else
!          if(ismooth> 1) print *, i,j, "not filled",ismooth
       end if

    end do loop_n

  end subroutine gtg_smoothseams

