!-------------------------------------------------------------------------------
module grib2nemsio_gfsflux
!$$$ module document block
! Module : grib2nemsio_gfsflux: read flux file in grib2 and write out in nemsio
! Abstract
! Program history log
!   2017-10-16 Yali Mao  :  initiated from INITPOST_GFS_NEMS_MPIIO.f
!                           referred to /global/noscrub/Hui-Ya.Chuang/test_fv3_netcdf_read/fv3nc2nemsio.fd/
!
!
!$$$ end module document block
!-------------------------------------------------------------------------------

  use nemsio_module
  use Grib_MOD

  implicit none

  private
  public grib2_to_nemsiofile

  integer, parameter :: nrec=105     ! 105 fields need to be read from flux file
  integer,parameter :: IVEGSRC=1     ! nemsio_getheadvar()
  integer,parameter :: iCU_PHYSICS=4 ! nemsio_getheadvar()

  type :: field_2D_type  ! 
!    nemsio part
!    /nwprod2/lib/nemsio/v2.2.3/src/nemsio_openclose.f90
!    name ending with _ave/_min/_max, nemsio code will take care of it.
     character(nemsio_charkind) :: name
     character(nemsio_charkind) :: vcoordName
!    grib2 part
     integer :: idisp  ! product discipline, flux filed is 0/1/2/10
     integer :: npdt   ! number of template 4, flux field is 4.0/4.8
     integer :: icat   ! catogory
     integer :: iprm   ! parameter
     integer :: ilevel ! type of level (code table 4.5)
     integer :: level
     integer :: istats ! (template 4.8, code table 4.10)
                       !  0-ave 1-acc 2-max 3-min
  end type field_2D_type
  type(field_2D_type) :: fields2D(nrec) 

  integer,          parameter :: intkind=4,realkind=4
  integer(intkind), parameter :: intfill=-9999_intkind
  real,             parameter :: SPVAL=9.99e20 ! nemsio SPVAL is different
  real,             parameter :: PTHRESH = 0.000001
  type :: nemsio_head
     integer(nemsio_intkind)     :: version=198410
     character(nemsio_charkind8) :: gdatatype='bin4'
     character(nemsio_charkind8) :: modelname='GFS'

     integer(nemsio_intkind)     :: nrec=intfill
     integer(nemsio_intkind)     :: nmeta=8
     integer(nemsio_intkind)     :: nmetavari=3
     integer(nemsio_intkind)     :: nmetavarr=1
     integer(nemsio_intkind)     :: nmetaaryi=1

     integer(nemsio_intkind)     :: nfhour=intfill
     integer(nemsio_intkind)     :: nfminute=0
     integer(nemsio_intkind)     :: nfsecondn=0
     integer(nemsio_intkind)     :: nfsecondd=1
     integer(nemsio_intkind)     :: idate(7)=intfill
     integer(nemsio_intkind)     :: fhour=intfill

     integer(nemsio_intkind)     :: dimx=intfill
     integer(nemsio_intkind)     :: dimy=intfill
     integer(nemsio_intkind)     :: dimz=intfill
     real(nemsio_realkind)       :: rlon_min      
     real(nemsio_realkind)       :: rlon_max       
     real(nemsio_realkind)       :: rlat_min       
     real(nemsio_realkind)       :: rlat_max       

     integer(nemsio_intkind)     :: nframe=0
     integer(nemsio_intkind)     :: ntrac=3
     integer(nemsio_intkind)     :: nsoil=4

     integer(nemsio_intkind)     :: ncldt=3
     integer(nemsio_intkind)     :: idvc=2
     integer(nemsio_intkind)     :: idsl=intfill
     integer(nemsio_intkind)     :: idvm=intfill
     integer(nemsio_intkind)     :: idrt=0

     logical                     :: extrameta= .true.

     character(nemsio_charkind),allocatable :: recname(:)
     character(nemsio_charkind),allocatable :: reclevtyp(:)
     integer(nemsio_intkind),allocatable    :: reclev(:)
     real(nemsio_realkind),allocatable      :: lat(:)
     real(nemsio_realkind),allocatable      :: lon(:)

     character(nemsio_charkind),allocatable :: variname(:)
     character(nemsio_charkind),allocatable :: varrname(:)
     character(nemsio_charkind),allocatable :: aryiname(:)
     integer(nemsio_intkind),allocatable    :: varival(:)
     integer(nemsio_intkind),allocatable    :: aryilen(:)
     integer(nemsio_intkind),allocatable    :: aryival(:,:) ! not used?
     real(nemsio_realkind),allocatable      :: varrval(:)
  end type nemsio_head
  type(nemsio_head) :: head

contains

  subroutine grib2_to_nemsiofile(infile,outfile,iret)
    implicit none
    character(len=*), intent(in) :: infile
    character(len=*), intent(in) :: outfile
    integer,intent(out) :: iret

    integer :: iunit
    type(gribfield) :: gfld
    integer :: dimx, dimy

    type(nemsio_gfile) :: gfile

    integer :: i

    print *, "match_nemsio_grib2"
    call match_nemsio_grib2()


    print *, "open grib2 file"
    iunit = 11
    call baopenr(iunit, infile, iret)
    if (iret /= 0) then
       write(*, *)'open grib2 file error: ', trim(infile), ' iret=', iret
       return
    end if

    print *, "read grib2 file"
!   call getgb2 one time first to get information of idate, fhour and grid
    i=1
    call readGB2(iunit,fields2D(i)%idisp,fields2D(i)%npdt,fields2D(i)%icat,&
                 fields2D(i)%iprm,fields2D(i)%ilevel,fields2D(i)%level,&
                 fields2D(i)%istats,gfld,iret)
    if(iret /= 0) return

    dimx = gfld%igdtmpl(8)
    dimy = gfld%igdtmpl(9)

    print *, "init_head_from_grib2 dimx,dimy=",dimx,dimy

    call init_head_from_grib2(nrec,fields2D,dimx,dimy,gfld,head)
    call gf_free(gfld)

    call nems_write_init(outfile,head,gfile,iret)

!   write the each field in grib2 to gfile
    do i = 1, nrec
       call readGB2(iunit,fields2D(i)%idisp,fields2D(i)%npdt,fields2D(i)%icat,&
                    fields2D(i)%iprm,fields2D(i)%ilevel,fields2D(i)%level,&
                    fields2D(i)%istats,gfld,iret)
!       print *, "unpacked,expanded,ibmap",gfld%unpacked,gfld%expanded,gfld%ibmap
!       print *, "size of ibmap, fld=", size(gfld%bmap),size(gfld%fld)

!      set to SPVAL if bmap false
       if(gfld%ibmap == 0) then
          where(.not. gfld%bmap) gfld%fld = SPVAL
       end if

!      SNOW FRACTION is multiplied by 100 by UPP, so set it back
       if(trim(head%recname(i)) == 'cpofp') then
          where(gfld%fld/100. > PTHRESH) gfld%fld = gfld%fld/100
       end if

       call nemsio_writerecv(gfile,head%recname(i),levtyp=head%reclevtyp(i),&
                    lev=head%reclev(i),data=gfld%fld,iret=iret)
       if (iret /= 0) then
          print*,'error writing',head%recname(i),head%reclevtyp(i),head%reclev(i),iret
          STOP
       ENDIF
    end do

    call gf_free(gfld)


  end subroutine grib2_to_nemsiofile

  subroutine match_nemsio_grib2()
!------------------------------------------------
!   UPP:
!------------------------------------------------
!   1) values on 1 hybrid level are from 3D file, not from flux file
!   2) surface pressure and surface height are from 3D file, not from flux file
!   3) land mask: converts to sea mask (FIX.f)
!   4) Surface temperature: converts to potential temperature
!   5) 2-m temperature: converts to potential temperature
!   6) Precipitation rate: instantaneous=averaged, converts to m/timestep by dtq2*0.001
!   7) snow cover: converts to fraction
!   8) Snow depth: converts to mm
!   9) albedo: converts to fraction by 0.01 (FIX.f)
!   10) mxsalb: outputed by GFS model, but not by UPP though UPP reads in
!   11) time averaged column cloud (tcdc): converts to fraction by 0.01 (CLDRAD.f)
!   12) plant canopy sfc water(cnwat): converts to m
!   13) vegetation: converts to fraction
!   14) time averaged outgoing sfc shortwave (aswout): a minus sign (CLDRAD.f)
!   15) time averaged surface sensible heat flux (sfcshx): a minus sign
!   16) time averaged surface latent heat flux (sfclhx): a minus sign
!------------------------------------------------
!   nemsio code   |  flux grib2 (degrib2 & wgrib2)
!------------------------------------------------
!   sunsd_acc     | not 'acc fcst' because of legend
!   csulf         ! ave fcst   \
!   csusf         ! ave fcst    \
!   csdlf         ! ave fcst   names under nemsio code should end with "_ave", but...
!   csdsf         ! ave fcst    /
!   snohf         ! ave fcst   /
!   spfhmax_max   ! qmax
!   spfhmin_min   ! qmin
!   (computed)    | lftx
!   (computed)    ! pwat
!------------------------------------------------
    fields2D(1)=field_2D_type('land','sfc',  2,0,0,0,1,0,-1)
    fields2D(2)=field_2D_type('icec','sfc',  10,0,2,0,1,0,-1)
    fields2D(3)=field_2D_type('hpbl','sfc',  0,0,3,196,1,0,-1)
    fields2D(4)=field_2D_type('fricv','sfc', 0,0,2,197,1,0,-1)
    fields2D(5)=field_2D_type('sfcr','sfc',  2,0,0,1,1,0,-1)
    fields2D(6)=field_2D_type('sfexc','sfc', 2,0,0,195,1,0,-1)
    fields2D(7)=field_2D_type('acond','sfc', 2,0,0,228,1,0,-1)
    fields2D(8)=field_2D_type('tmp','sfc',   0,0,0,0,1,0,-1)
    fields2D(9)=field_2D_type('cprat_ave','sfc',   0,8,1,196,1,0,0)
    fields2D(10)=field_2D_type('prate_ave','sfc',  0,8,1,7,1,0,0)
    fields2D(11)=field_2D_type('weasd','sfc',      0,0,1,13,1,0,-1)
    fields2D(12)=field_2D_type('snowc_ave','sfc',  0,8,1,42,1,0,0)
    fields2D(13)=field_2D_type('snod','sfc',       0,0,1,11,1,0,-1)
    fields2D(14)=field_2D_type('tmp','2 m above gnd',  0,0,0,0,103,2,-1)
    fields2D(15)=field_2D_type('spfh','2 m above gnd', 0,0,1,0,103,2,-1)
    fields2D(16)=field_2D_type('albdo_ave','sfc',      0,8,19,1,1,0,0)
    ! fields2D()=field_2D_type('mxsalb','sfc',
    fields2D(17)=field_2D_type('tcdc_ave','atmos col',    0,8,6,1,10,0,0)
    fields2D(18)=field_2D_type('tcdc_ave','low cld lay',  0,8,6,1,214,0,0)
    fields2D(19)=field_2D_type('tcdc_ave','mid cld lay',  0,8,6,1,224,0,0)
    fields2D(20)=field_2D_type('tcdc_ave','high cld lay', 0,8,6,1,234,0,0)
    fields2D(21)=field_2D_type('tcdc','convect-cld laye', 0,0,6,1,244,0,-1)
    fields2D(22)=field_2D_type('sltyp','sfc',  2,0,3,194,1,0,-1)
    fields2D(23)=field_2D_type('cnwat','sfc',  2,0,0,196,1,0,-1)
    fields2D(24)=field_2D_type('cpofp','sfc',  0,0,1,39,1,0,-1)
    fields2D(25)=field_2D_type('veg','sfc',    2,0,0,4,1,0,-1)
    fields2D(26)=field_2D_type('soill','0-10 cm down',    2,0,3,192,106,0,-1)
    fields2D(27)=field_2D_type('soill','10-40 cm down',   2,0,3,192,106,10,-1)
    fields2D(28)=field_2D_type('soill','40-100 cm down',  2,0,3,192,106,40,-1)
    fields2D(29)=field_2D_type('soill','100-200 cm down', 2,0,3,192,106,100,-1)
    fields2D(30)=field_2D_type('soilw','0-10 cm down',    2,0,0,192,106,0,-1)
    fields2D(31)=field_2D_type('soilw','10-40 cm down',   2,0,0,192,106,10,-1)
    fields2D(32)=field_2D_type('soilw','40-100 cm down',  2,0,0,192,106,40,-1)
    fields2D(33)=field_2D_type('soilw','100-200 cm down', 2,0,0,192,106,100,-1)
    fields2D(34)=field_2D_type('tmp','0-10 cm down',      2,0,0,2,106,0,-1)
    fields2D(35)=field_2D_type('tmp','10-40 cm down',     2,0,0,2,106,10,-1)
    fields2D(36)=field_2D_type('tmp','40-100 cm down',    2,0,0,2,106,40,-1) 
    fields2D(37)=field_2D_type('tmp','100-200 cm down',   2,0,0,2,106,100,-1)
    fields2D(38)=field_2D_type('dlwrf_ave','sfc',  0,8,5,192,1,0,0)
    fields2D(39)=field_2D_type('dlwrf','sfc',      0,0,5,192,1,0,-1)
    fields2D(40)=field_2D_type('ulwrf_ave','sfc',  0,8,5,193,1,0,0)
    fields2D(41)=field_2D_type('ulwrf','sfc',      0,0,5,193,1,0,-1)
    fields2D(42)=field_2D_type('ulwrf_ave','nom. top',  0,8,5,193,8,0,0)
    fields2D(43)=field_2D_type('dswrf_ave','sfc',  0,8,4,192,1,0,0)
    fields2D(44)=field_2D_type('dswrf','sfc',      0,0,4,192,1,0,-1)
    fields2D(45)=field_2D_type('duvb_ave','sfc',   0,8,4,194,1,0,0)
    fields2D(46)=field_2D_type('cduvb_ave','sfc',  0,8,4,195,1,0,0)
    fields2D(47)=field_2D_type('uswrf_ave','sfc',  0,8,4,193,1,0,0)
    fields2D(48)=field_2D_type('uswrf','sfc',      0,0,4,193,1,0,-1)
    fields2D(49)=field_2D_type('dswrf_ave','nom. top',  0,8,4,192,8,0,0)
    fields2D(50)=field_2D_type('uswrf_ave','nom. top',  0,8,4,193,8,0,0)
    fields2D(51)=field_2D_type('shtfl_ave','sfc', 0,8,0,11,1,0,0)
    fields2D(52)=field_2D_type('shtfl','sfc',     0,0,0,11,1,0,-1)
    fields2D(53)=field_2D_type('lhtfl_ave','sfc', 0,8,0,10,1,0,0)
    fields2D(54)=field_2D_type('lhtfl','sfc',     0,0,0,10,1,0,-1)
    fields2D(55)=field_2D_type('gflux_ave','sfc', 2,8,0,193,1,0,0)
    fields2D(56)=field_2D_type('gflux','sfc',     2,0,0,193,1,0,-1)
    fields2D(57)=field_2D_type('uflx_ave','sfc',  0,8,2,17,1,0,0)
    fields2D(58)=field_2D_type('vflx_ave','sfc',  0,8,2,18,1,0,0)
    fields2D(59)=field_2D_type('u-gwd_ave','sfc', 0,8,3,194,1,0,0)
    fields2D(60)=field_2D_type('v-gwd_ave','sfc', 0,8,3,195,1,0,0)
    fields2D(61)=field_2D_type('pevpr_ave','sfc', 0,8,1,200,1,0,0)
    fields2D(62)=field_2D_type('pevpr','sfc',     0,0,1,200,1,0,-1)
    fields2D(63)=field_2D_type('ugrd','10 m above gnd',  0,0,2,2,103,10,-1)
    fields2D(64)=field_2D_type('vgrd','10 m above gnd',  0,0,2,3,103,10,-1)
    fields2D(65)=field_2D_type('vgtyp','sfc',            2,0,0,198,1,0,-1)
    fields2D(66)=field_2D_type('sotyp','sfc',            2,0,3,0,1,0,-1)
    fields2D(67)=field_2D_type('pres','convect-cld top', 0,0,3,0,243,0,-1)
    fields2D(68)=field_2D_type('pres','convect-cld bot', 0,0,3,0,242,0,-1)
    fields2D(69)=field_2D_type('pres_ave','low cld top', 0,8,3,0,213,0,0)
    fields2D(70)=field_2D_type('pres_ave','low cld bot', 0,8,3,0,212,0,0)
    fields2D(71)=field_2D_type('tmp_ave','low cld top',  0,8,0,0,213,0,0)
    fields2D(72)=field_2D_type('pres_ave','mid cld top', 0,8,3,0,223,0,0)
    fields2D(73)=field_2D_type('pres_ave','mid cld bot', 0,8,3,0,222,0,0)
    fields2D(74)=field_2D_type('tmp_ave','mid cld top',  0,8,0,0,223,0,0)
    fields2D(75)=field_2D_type('pres_ave','high cld top',0,8,3,0,233,0,0)
    fields2D(76)=field_2D_type('pres_ave','high cld bot',0,8,3,0,232,0,0)
    fields2D(77)=field_2D_type('tmp_ave','high cld top', 0,8,0,0,233,0,0)
    fields2D(78)=field_2D_type('tcdc_ave','bndary-layer cld',  0,8,6,1,211,0,0)
    fields2D(79)=field_2D_type('cwork_ave','atmos col',     0,8,6,193,200,0,0)
    fields2D(80)=field_2D_type('watr_acc','sfc',            2,8,0,5,1,0,1)
    fields2D(81)=field_2D_type('tmax_max','2 m above gnd',  0,8,0,4,103,2,2)
    fields2D(82)=field_2D_type('tmin_min','2 m above gnd',  0,8,0,5,103,2,3)
    fields2D(83)=field_2D_type('icetk','sfc',      10,0,2,1,1,0,-1)
    fields2D(84)=field_2D_type('wilt','sfc',       2,0,0,201,1,0,-1)
    fields2D(85)=field_2D_type('sunsd_acc','sfc',  0,0,6,201,1,0,-1)
    fields2D(86)=field_2D_type('fldcp','sfc',      2,0,3,203,1,0,-1)
    fields2D(87)=field_2D_type('vbdsf_ave','sfc',  0,8,4,200,1,0,0)
    fields2D(88)=field_2D_type('vddsf_ave','sfc',  0,8,4,201,1,0,0)
    fields2D(89)=field_2D_type('nbdsf_ave','sfc',  0,8,4,202,1,0,0)
    fields2D(90)=field_2D_type('nddsf_ave','sfc',  0,8,4,203,1,0,0)
    fields2D(91)=field_2D_type('csulf','sfc',      0,8,5,195,1,0,0)
    fields2D(92)=field_2D_type('csulf','nom. top', 0,8,5,195,8,0,0)
    fields2D(93)=field_2D_type('csusf','sfc',      0,8,4,198,1,0,0)
    fields2D(94)=field_2D_type('csusf','nom. top', 0,8,4,198,8,0,0)
    fields2D(95)=field_2D_type('csdlf','sfc',      0,8,5,196,1,0,0)
    fields2D(96)=field_2D_type('csdsf','sfc',      0,8,4,196,1,0,0)
    fields2D(97)=field_2D_type('spfhmax_max','2 m above gnd',  0,8,1,219,103,2,2)
    fields2D(98)=field_2D_type('spfhmin_min','2 m above gnd',  0,8,1,220,103,2,3)
    fields2D(99)=field_2D_type('ssrun_acc','sfc',  1,8,0,193,1,0,1)
    fields2D(100)=field_2D_type('evbs_ave','sfc',  2,8,3,198,1,0,0)
    fields2D(101)=field_2D_type('evcw_ave','sfc',  2,8,0,229,1,0,0)
    fields2D(102)=field_2D_type('trans_ave','sfc', 2,8,0,230,1,0,0)
    fields2D(103)=field_2D_type('sbsno_ave','sfc', 0,8,1,212,1,0,0)
    fields2D(104)=field_2D_type('soilm','0-200 cm down',  2,0,0,3,106,0,-1)
    fields2D(105)=field_2D_type('snohf','sfc',     0,8,0,16,1,0,0)
  end subroutine match_nemsio_grib2

!----------------------------------------------------------------------------
  subroutine readGB2(iunit,idisp, npdt, icat, iprm, ilev, level, istats, gfld, iret)
    implicit none
    integer, intent(in) :: iunit! opened file handler
    integer, intent(in) :: idisp
    integer, intent(in) :: npdt	! number of product defination template 4
    integer, intent(in) :: icat	! category  
    integer, intent(in) :: iprm	! parameter number
    integer, intent(in) :: ilev	! type of level (code table 4.5)
    integer, intent(in) :: level! if pressure level, in Pa
    integer, intent(in) :: istats
    type(gribfield),intent(out) :: gfld
    integer, intent(out) :: iret

    integer j,jdisc,jpdtn,jgdtn
    integer,dimension(200) :: jids,jpdt,jgdt
    logical :: unpack

    iret = -1

    j        = 0          ! search from 0
    jdisc    = idisp      ! for met field:0 hydro: 1, land: 2 ocean: 10
    jids(:)  = -9999
    !-- set product defination template 4
    jpdtn    = npdt   ! number of product defination template 4
    jpdt(:)  = -9999
    jpdt(1)  = icat   ! category 
    jpdt(2)  = iprm   ! parameter number
    jpdt(10) = ilev   ! type of level (code table 4.5)
    jpdt(12) = level  ! level value
    if(npdt==8) jpdt(24)=istats
    !-- set grid defination template/section 3
    jgdtn    = -1  
    jgdt(:)  = -9999
    unpack=.true.
    ! Get field from file
    call getgb2(iunit, 0, j, jdisc, jids, jpdtn, jpdt, &
                jgdtn, jgdt, unpack, j, gfld, iret)
    if( iret /= 0) then
       print *, 'Reading grib2 field error. iret=',iret, npdt, icat, iprm, ilev, &
                istats,"on level=",level
       return
    endif

    ! data = reshape(gfld%fld, (/ nx, ny /))

    return
  end subroutine readGB2

!----------------------------------------------------------------------------
  subroutine init_head_from_grib2(nrec,fields2D,dimx,dimy,gfld,head)
    integer,intent(in) :: nrec
    type(field_2D_type),intent(in) :: fields2D(nrec)
    integer,intent(in) :: dimx,dimy
    type(gribfield),intent(in) :: gfld
    type(nemsio_head),intent(inout) :: head

    real, allocatable:: glat1d(:),glon1d(:)
    integer :: nmeta
    integer :: idrt ! converted from Grid Definition Template number to be used by splat()

    real, parameter :: RTD=180./3.1415926

    integer :: i,j

    print *, "initialize nmetavari"
    nmeta = head%nmetavari
    allocate(head%variname(nmeta))
    allocate(head%varival(nmeta))
    allocate(head%aryiname(nmeta))
    allocate(head%aryilen(nmeta))
    head%variname(1)='cu_physics'
    head%variname(2)='mp_physics'
    head%variname(3)='IVEGSRC'
    head%varival(1)=4
    head%varival(2)=1000
    head%varival(3)=IVEGSRC
    head%aryiname(1)= 'lpl'
    head%aryilen(1)= dimy/2 

    print *, "initialize nmetavarr"
    nmeta = head%nmetavarr
    allocate(head%varrname(nmeta))
    allocate(head%varrval(nmeta))
    head%varrname(1)='zhour'


    print *, "initialize 2D field records"
    head%nrec = nrec
    allocate(head%recname(nrec))
    allocate(head%reclevtyp(nrec))
    allocate(head%reclev(nrec))
    do i = 1, nrec
       head%recname(i) = fields2D(i)%name
       head%reclevtyp(i) = fields2D(i)%vcoordName
       head%reclev(i) = 1 ! for fields in flux data
    end do

!   initialize grid information, computing lat,lon as in GFS POST SIGIO
    print *, "initialize grid information dimx,dimy=",dimx,dimy
    head%dimx=dimx
    head%dimy=dimy
    ! head%dimz
    allocate(head%lat(dimx*dimy),head%lon(dimx*dimy))
    ! As in splat(), only accepts idrt=0 or 4, but not 256
    if(gfld%igdtnum == 0) then
       idrt = 0 !  Lat/Lon grid
    elseif(gfld%igdtnum == 40) then
       idrt = 4 !  Gaussian Lat/Lon grid
    else
       print *, "SPLAT() doesn't support grid number:", gfld%igdtnum
    end if
    ! computing lat, lon    
    allocate(glat1d(dimy),glon1d(dimy))
    call splat(idrt,dimy,glat1d,glon1d)
    do j = 1, dimy
       do i = 1, dimx
          head%lat((j-1)*dimx+i) = asin(glat1d(j))*RTD
          head%lon((j-1)*dimx+i) = 360./dimx*(i-1)
       end do
    end do
    deallocate(glat1d,glon1d)
    head%rlon_min = minval(head%lon)
    head%rlon_max = maxval(head%lon)
    head%rlat_min = minval(head%lat)
    head%rlat_max = maxval(head%lat)

    print *, "lon_min=", head%rlon_min,"lon_max=", head%rlon_max
    print *, "lat_min=", head%rlat_min,"lat_max=", head%rlat_max

!   initialize date, but UPP doesn't read date information from flux file,
!   so assign it in an easy way.
    head%idate(1:6) = 0
    head%idate(7)   = 1

  end subroutine init_head_from_grib2


  subroutine nems_write_init(filename,head,gfile,iret)
    implicit none

    character(len=*), intent(in) :: filename
    type(nemsio_head),intent(in) :: head
    type(nemsio_gfile),intent(inout) :: gfile
    integer, intent(out) :: iret

    integer :: i, j, k

    call nemsio_init(iret=iret)
    print*,'init nemsio, iret=',iret                                                                                         
    call nemsio_open(gfile,trim(filename),'write',          &
         & iret=iret,                                       &
         & modelname=trim(head%modelname),                  &
         & version=head%version,gdatatype=head%gdatatype,   &
         & dimx=head%dimx,dimy=head%dimy,                   &
         & dimz=head%dimz,rlon_min=head%rlon_min,           &
         & rlon_max=head%rlon_max,rlat_min=head%rlat_min,   &
         & rlat_max=head%rlat_max,                          &
         & lon=head%lon,lat=head%lat,                       &
         & idate=head%idate,nrec=head%nrec,                 &
         & nframe=head%nframe,idrt=head%idrt,               &
         & ncldt=head%ncldt,idvc=head%idvc,                 &
         & nfhour=head%nfhour,nfminute=head%nfminute,       &
         & nfsecondn=head%nfsecondn,nmeta=head%nmeta,       &
         & nfsecondd=head%nfsecondd,extrameta=.true.,       &
         & nmetaaryi=head%nmetaaryi,recname=head%recname,   &
         & nmetavari=head%nmetavari,variname=head%variname, &
         & varival=head%varival,varrval=head%varrval,       &
         & nmetavarr=head%nmetavarr,varrname=head%varrname, &
         & reclevtyp=head%reclevtyp,                        &
         & reclev=head%reclev,aryiname=head%aryiname,       &
         & aryilen=head%aryilen)
    print*,'open nemsio, iret=',iret
  end subroutine nems_write_init


!------------------------------------------------------
  subroutine nems_write(gfile,recname,reclevtyp,level,dimx,data2d,iret)

  implicit none
    type(nemsio_gfile)         :: gfile
    integer                    :: iret,level,dimx
    real                       :: data2d(dimx)
    character(nemsio_charkind) :: recname, reclevtyp

     call nemsio_writerecv(gfile,recname,levtyp=reclevtyp,lev=level,data=data2d,iret=iret)
     if (iret.NE.0) then
         print*,'error writing',recname,level,iret
         STOP
     ENDIF

  end subroutine nems_write

end module grib2nemsio_gfsflux

program main
  use grib2nemsio_gfsflux

  character(100) :: grib2file, nemsiofile
  integer :: iret

  call GET_COMMAND_ARGUMENT(1, grib2file)
  call GET_COMMAND_ARGUMENT(2, nemsiofile)

  call grib2_to_nemsiofile(grib2file, nemsiofile, iret)

  print *, "main iret=", iret
end program main
