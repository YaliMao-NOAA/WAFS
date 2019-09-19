      program test_readgrib2
!
!------------------------------------------------------
! ABSTRACT: This routine is to read out a grib2 data
!   Jan 2012     J.Wang    test gfs master grib2 data
!------------------------------------------------------
!
      use grib_mod
      use g2grids
!
      implicit none
!
      type(gribfield) :: gfld
      integer ifile,j,jdisc,jpdtn,jgdtn,iret,nx,ny
      integer day,month,year,hour,fhour,minute,gdstmpl_num,pdstempl_num
      integer,dimension(200) :: jids,jpdt,jgdt
      real fldmin,fldmax,firstval,lastval
      real lat_first,lon_first,lat_last,lon_last,dx,dy
      logical :: unpack=.true.
      character(255) :: cin
!
! code start
!
!-- set unit
      ifile=10
!
!-- get file name
      call getarg(1,cin)
!
!-- Open GRIB2 file
      call baopenr(ifile,trim(cin),iret)
      print *,'cin=',trim(cin),'iret=',iret
      
! Set GRIB2 field identification values to search for
      j=0              ! search from 0
      jdisc=0          ! discipline, for met field:0 hydro: 1, land: 2
!-- set id section
      jids=-9999
!-- set product def template(pdt), using template 4.xx
      jpdtn=-1
!-- set product def array
      jpdt=-9999
!for pdt, define catogory, parameter and level type and level
!eg: tmp at 500 hpa
      jpdt(1)= 19	! code table 4.1
      jpdt(2)= 20	! table 4.2 (0-0)
      jpdt(10)=100	! code table 4.5
      jpdt(12)=50000	! level value, in Pa 
!
!-- set grid def template
      jgdtn=-1
!-- set product def array
      jgdt=-9999


! Get field from file
      call getgb2(ifile,0,j,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,  &
                 unpack,j,gfld,iret)
      print *,'af call getgb2,iret=',iret

! Process field ...
print *, gfld%ndpts
      firstval=gfld%fld(1)
      lastval=gfld%fld(gfld%ndpts)
print *, 'interval=', firstval, lastval, gfld%ndpts
      fldmax=maxval(gfld%fld)
      fldmin=minval(gfld%fld)
      print *,'get hgt,gfld=',gfld%fld(1),gfld%fld(gfld%ndpts),&
           'fldmax=',fldmax,'fldmin=',fldmin,'total points=',gfld%ndpts
!date
      year=gfld%idsect(6)
      month=gfld%idsect(7)
      day=gfld%idsect(8)
      hour=gfld%idsect(9)
      minute=gfld%idsect(10)
!more pds info:
      pdstempl_num=gfld%ipdtnum
! other pds info is in gfld%ipdtmpl
      fhour=gfld%ipdtmpl(9)
      

!
!gds info
      gdstmpl_num=gfld%igdtnum
!eg: lat/lon
!      if(gdstmpl_num==0) then
        nx=gfld%igdtmpl(8)
        ny=gfld%igdtmpl(9)
        lat_first=gfld%igdtmpl(12)
        lon_first=gfld%igdtmpl(13)
        lat_last=gfld%igdtmpl(15)
        lon_last=gfld%igdtmpl(16)
        dx=gfld%igdtmpl(17)
        dy=gfld%igdtmpl(18)
       print *,'pds info,nx=',nx,'ny=',ny,'lat_first=', lat_first,lon_first, &
         'lat/lon_lat=',lat_last,lon_last,'dx/dy=',dx,dy
       print *, gfld%igdtmpl
!      endif

! Free memory when done with field
      call gf_free(gfld)
      stop
      end
