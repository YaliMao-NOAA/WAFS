      program degrib2

      use grib_mod
      use params
      integer, parameter :: msk1=32000, maxfld=1100
      CHARACTER(len=1),allocatable,dimension(:) :: cgrib
      integer :: listsec0(3)
      integer :: listsec1(13)
!      integer :: igds(5),igdstmpl(200),ipdstmpl(200),idrstmpl(200)
!      integer :: ideflist(500)
      character(len=250) :: gfile
      INTEGER :: NARG
      integer :: currlen=0
      integer :: jpdt(20)
      integer,dimension(maxfld)::ncat,nparm,nlevtype
      integer,dimension(maxfld)::nlev,ifcsthr,npdt,nspatial
      logical :: unpack,expand
      type(gribfield) :: gfld
      call start()
      unpack=.true.
      expand=.true.
      
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  GET ARGUMENTS
      NARG=IARGC()
      IF(NARG.NE.1) THEN
        CALL ERRMSG('degrib2:  Incorrect usage')
        CALL ERRMSG('Usage: degrib2 grib2file')
        CALL ERREXIT(2)
      ENDIF

      IUNIT=10
      CALL GETARG(1,gfile)
      CALL BAOPENR(iunit,trim(gfile),IOS)
      if(ios/=0)print*,'cant open ',trim(gfile)

      itot=0
      icount=0
      iseek=0
      do
         call skgb(iunit,iseek,msk1,lskip,lgrib)
         if (lgrib.eq.0) exit    ! end loop at EOF or problem
         if (lgrib.gt.currlen) then ! allocate cgrib if size is expanded.
            if (allocated(cgrib)) deallocate(cgrib)
            allocate(cgrib(lgrib),stat=is)
            currlen=lgrib
         endif
         call baread(iunit,lskip,lgrib,lengrib,cgrib)
         if (lgrib.ne.lengrib) then
            print *,' degrib2: IO Error.'
            call errexit(9)
         endif
         iseek=lskip+lgrib
         icount=icount+1
         PRINT *
         PRINT *,'GRIB MESSAGE ',icount,' starts at',lskip+1
         PRINT *

! Unpack GRIB2 field
         call gb_info(cgrib,lengrib,listsec0,listsec1,
     &                numfields,numlocal,maxlocal,ierr)
         if (ierr.ne.0) then
           write(6,*) ' ERROR querying GRIB2 message = ',ierr
           stop 10
         endif
         itot=itot+numfields
         print *,' SECTION 0: ',(listsec0(j),j=1,3)
         print *,' SECTION 1: ',(listsec1(j),j=1,13)
         print *,' Contains ',numlocal,' Local Sections ',
     &           ' and ',numfields,' data fields.'

         do n=1,numfields
           call gf_getfld(cgrib,lengrib,n,unpack,expand,gfld,ierr)
           if (ierr.ne.0) then
             write(6,*) ' ERROR extracting field = ',ierr
             cycle
           endif

           print *
           print *,' FIELD ',n
           if (n==1) then
            print *,' SECTION 0: ',gfld%discipline,gfld%version
            print *,' SECTION 1: ',(gfld%idsect(j),j=1,gfld%idsectlen)
           endif
           if ( associated(gfld%local).AND.gfld%locallen.gt.0 ) then
              print *,' SECTION 2: ',gfld%locallen,' bytes'
           endif
           print *,' SECTION 3: ',gfld%griddef,gfld%ngrdpts,
     &                            gfld%numoct_opt,gfld%interp_opt,
     &                            gfld%igdtnum
           print *,' GRID TEMPLATE 3.',gfld%igdtnum,': ',
     &            (gfld%igdtmpl(j),j=1,gfld%igdtlen)
           if ( gfld%num_opt .eq. 0 ) then
             print *,' NO Optional List Defining Number of Data Points.'
           else
             print *,' Section 3 Optional List: ',
     &                (gfld%list_opt(j),j=1,gfld%num_opt)
           endif
           print *,' PRODUCT TEMPLATE 4.',gfld%ipdtnum,': ',
     &          (gfld%ipdtmpl(j),j=1,gfld%ipdtlen)


           if ( gfld%num_coord .eq. 0 ) then
             print *,' NO Optional Vertical Coordinate List.'
           else
             print *,' Section 4 Optional Coordinates: ',
     &             (gfld%coord_list(j),j=1,gfld%num_coord)
           endif
           if ( gfld%ibmap .ne. 255 ) then
              print *,' Num. of Data Points = ',gfld%ndpts,
     &             '    with BIT-MAP ',gfld%ibmap
           else
              print *,' Num. of Data Points = ',gfld%ndpts,
     &                '    NO BIT-MAP '
           endif
           print *,' DRS TEMPLATE 5.',gfld%idrtnum,': ',
     &          (gfld%idrtmpl(j),j=1,gfld%idrtlen)


	   im=gfld%igdtmpl(8)
	   jm=gfld%igdtmpl(9)

           fldmax=gfld%fld(1)
           fldmin=gfld%fld(1)
           sum=gfld%fld(1)
           do j=2,im*jm
             if (gfld%fld(j).gt.fldmax) fldmax=gfld%fld(j)
             if (gfld%fld(j).lt.fldmin) fldmin=gfld%fld(j)
             sum=sum+gfld%fld(j)
           enddo
           print *,' Data Values:'
           write(6,fmt='("  MIN=",f21.8,"  AVE=",f21.8,
     &          "  MAX=",f21.8)') fldmin,sum/gfld%ndpts,fldmax
          !do j=1,gfld%ndpts
          !   write(22,*) gfld%fld(j)
          !enddo

!          call gf_free(gfld)
         enddo
	 npdt(icount)=gfld%ipdtnum
	 ncat(icount)=gfld%ipdtmpl(1)
	 nparm(icount)=gfld%ipdtmpl(2)
	 nlevtype(icount)=gfld%ipdtmpl(10)
	 nlev(icount)=gfld%ipdtmpl(12)
         if (gfld%ipdtnum == 0 .or. gfld%ipdtnum == 7) then
           nspatial(icount) = -1
         else
 	   nspatial(icount)=gfld%ipdtmpl(16)
         endif
	 ifcsthr(icount)=gfld%ipdtmpl(9) 

	 call gf_free(gfld)

      end do
      print *," "
      print *, ' Total Number of Fields Found = ',itot, icount
      print*,'sending the following to write_ndfd_grib2'
      do n=1,itot
       print*,gfld%ndpts,itot,
     &            npdt(n),ncat(n),nparm(n),
     &            ifcsthr(n),nlevtype(n),nlev(n),
     &            nspatial(n),
     &            'forecast',1, listsec1(6),listsec1(7),listsec1(8),
     &             listsec1(9),
     &            0,0,1
      enddo

      end program degrib2
