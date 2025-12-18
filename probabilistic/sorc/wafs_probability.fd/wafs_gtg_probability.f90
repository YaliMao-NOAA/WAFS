        program wafs_edparm_probability
!
! main program: naefs_bc_probability_g2
!
! prgmmr: Bo Cui           org: Bo.Cui      date: 2013-10-01
!
! abstract: calculate 10%,50% & 90% probability forecast, ensemble mean, & spread of
!           ensemble NCEP, CMC or NAEFS
! 
!            modification: use accumulated analysis difference to adjust CMC ensemble
!            modification: set NAEFS product ID as 114 
!                          set GEFS product ID as 107 that pass from bias-corrected product directly
!           add 13 new variables for bias estimation (H, T, U, V at 100mb 50mb 10mb and VVEL)
!           calculate and output 2m dew point temperature and 2m relative humidity (+2 variables)
!
! usage:
!
!   input file: ncep/cmc/fnmoc ensemble forecast                                          
!             : ncep/cmc accumulated analysis difference
!             : ncep/cmc accumulated analysis difference 6 hour ago
!             : cmc ensemble forecast t2m
!             : cmc ensemble forecast t2m 6 hour ago
!             : ncep/fnmoc accumulated analysis difference
!             : ncep/fnmoc accumulated analysis difference 6 hour ago
!             : fnmoc ensemble forecast t2m
!             : fnmoc ensemble forecast t2m 6 hour ago
!
!   output file: 10%, 50%, 90% and mode probability forecast
!              : ensemble mean and spread
!
!   parameters
!     nvar  -      : number of variables
!

!   2m dew point temperature and 2m relative humidity process
!
!      step 1. read in 2m dew point temperature of NCEP/GEFS and CMC/GEFS ensembles, adjust 
!              CMC/FNMOC each member's dpt2m,combine NCEP and adjusted CMC 2m dew point temperature
!              to generate the mean, spread, mode, 10%, and etc.
!           2. compare the mean, mode, 10%, 50% and 90% of 2m temperature and 2m dew point
!              temperature, make sure the values of 2m temperature are smaller than 2m dew
!              point temperature
!           3. use adjusted CMC 2m temperature and 2m dew point temperature to get new CMC 2m
!              relative humidity, combine NCEP and CMC new 2m relative humidity to generate the
!              mean, spread, mode, 10%, 50% and 90% forecast.
!           4. adjust the mean, spread, mode, 10%, 50% and 90% values of rh to make sure these values
!              are not larger than 100%
!              or smaller than 0%

! programs called:
!   baopenr          grib i/o
!   baopenw          grib i/o
!   baclose          grib i/o
!   getgbeh          grib reader
!   getgbe           grib reader
!   putgbe           grib writer

! exit states:
!   cond =   0 - successful run
!   cond =   1 - I/O abort
!
! attributes:
!   language: fortran 90
!
!$$$

!use naefs_mod

use grib_mod
use params

!implicit none

type(gribfield) :: gfld,gfldo
integer :: currlen=0
logical :: unpack=.true.
logical :: expand=.false.

integer,dimension(200) :: jids,jpdt,jgdt,iids,ipdt,igdt
integer jskp,jdisc,jpdtn,jgdtn,idisc,ipdtn,igdtn
common /param/jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt

integer     nmemd,nmvar,nvar,ivar,i,k,im,imem,n,inum,ignum,ii
parameter   (nmemd=62,nmvar=52)

integer, parameter :: nthreshold=2
real, parameter :: thresholds(nthreshold) = (/0.20, 0.45/)
real :: fvalues(nthreshold)

real,       allocatable :: fgrid_im(:),fgrid(:,:),fst(:),fgrid_t2m(:)
real,       allocatable :: ens_avg(:),ens_spr(:)
real,       allocatable :: anl_bias_cmc(:),t2m_bias_cmc(:),t2m_biasm06_cmc(:)
real,       allocatable :: t2m_cmc(:),t2m_cmcm06(:)
real,       allocatable :: anl_bias_fnmoc(:),t2m_bias_fnmoc(:),t2m_biasm06_fnmoc(:)
real,       allocatable :: t2m_fnmoc(:),t2m_fnmocm06(:)
real,       allocatable :: edr_p20(:),edr_p45(:),prob_mode(:),prob_90(:)
real,       allocatable :: prob_10_t2m(:),prob_90_t2m(:),prob_mode_t2m(:),prob_50_t2m(:),prob_avg_t2m(:)
logical(1), allocatable :: lbms(:),lbmsout(:)
real        dmin,dmax,avg,spr,weight(nmemd)
integer     maxgrd,ndata,ifhr
integer     index,j,iret,jret             

double precision,allocatable :: fstd(:)
double precision edrp20,edrp45,prob90,mode

integer     kens(5)
integer     ipdn(nmvar),ipdtnum_out
integer     ipd1(nmvar),ipd2(nmvar),ipd10(nmvar),ipd11(nmvar),ipd12(nmvar),mmod(nmvar)
integer     ipd11_cmc(nmvar), ipd12_cmc(nmvar)
integer     ipd11_new(nmvar), ipd12_new(nmvar)

character*10  ffd(nmvar)

! variables: u,v,t,h at 1000,925,850,700,500,250,200,100,50,10 mb,  &
!            slp pres t2m u10m v10m tmax tmin ULWRF(Surface) ULWRF(OLR) VVEL(850w)

integer     iret_ncep,iret_bias_cmc,iret_biasm06_cmc,ifdebias,iall_cmc,iall_fnmoc
integer     iret_bias_fnmoc,iret_biasm06_fnmoc
integer     iunit,lfipg(nmemd),lfipg1,lfipg2,lfipg3,lfipg4,lfipg5,lfipg6,icfipg(nmemd)
integer     icfipg1,icfipg2,icfipg3,icfipg4,icfipg5,icfipg6
integer     pidswitch,nfiles,iskip(nmemd),tfiles,ifile
integer     lfopg1,lfopg2,lfopg3,lfopg4,lfopg5,lfopg6
integer     icfopg1,icfopg2,icfopg3,icfopg4,icfopg5,icfopg6

character*150 cfipg(nmemd),cfipg1,cfipg2,cfipg3,cfipg4,cfipg5,cfipg6
character*150 cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6

namelist /namens/pidswitch,nfiles,ifdebias,iall_cmc,iall_fnmoc,iskip,cfipg,cfipg1,cfipg2,cfipg3, &
                 cfipg4,cfipg5,cfipg6,ifhr,cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6
namelist /varlist/ffd,ipdn,ipd1,ipd2,ipd10,ipd11,ipd12,mmod,nvar
 
read (5,namens)
!write (6,namens)

read (5,varlist)
!write(6,varlist)

print *, 'Input variables include '
print *, (ffd(i),i=1,nvar)

! stop this program if there is no enough files put in 

print *, ' '; print *, 'Input files size ', nfiles                  

if(iall_cmc.eq.1) print *, 'There is No NCEP GEFS Files'

if(iall_cmc.eq.1.and.iall_fnmoc.eq.1) print *, 'There is No NCEP and CMC GEFS Files'

if(nfiles.le.10) goto 1020 

! set the fort.* of intput file, open forecast files

print *, '   '
print *, 'Input files include '

iunit=9

tfiles=nfiles

do ifile=1,nfiles
  iunit=iunit+1
  icfipg(ifile)=iunit
  lfipg(ifile)=len_trim(cfipg(ifile))
  print '(a4,i3,a125)', 'fort.',icfipg(ifile), cfipg(ifile)(1:lfipg(ifile))
  call baopenr(icfipg(ifile),cfipg(ifile)(1:lfipg(ifile)),iret)
  if ( iret .ne. 0 ) then
    print *,'there is no NAEFS forecast, ifile,iret = ',cfipg(ifile)(1:lfipg(ifile)),iret
!   tfiles=nfiles-1
    iskip(ifile)=0
  endif
enddo


! set the fort.* of output file

print *, '   '
print *, 'Output files include '

iunit=iunit+1
icfopg1=iunit
lfopg1=len_trim(cfopg1)
call baopenwa(icfopg1,cfopg1(1:lfopg1),iret)
print *, 'fort.',icfopg1, cfopg1(1:lfopg1)
if(iret.ne.0) then
  print *,'there is no output probability, 10% = ',cfopg1(1:lfopg1),iret
endif

!iunit=iunit+1
!icfopg2=iunit
!lfopg2=len_trim(cfopg2)
!call baopenwa(icfopg2,cfopg2(1:lfopg2),iret)
!print *, 'fort.',icfopg2, cfopg2(1:lfopg2)
!if(iret.ne.0) then
!  print *,'there is no output probability, 90% = ',cfopg2(1:lfopg2),iret
!endif

iunit=iunit+1
icfopg3=iunit
lfopg3=len_trim(cfopg3)
call baopenwa(icfopg3,cfopg3(1:lfopg3),iret)
print *, 'fort.',icfopg3, cfopg3(1:lfopg3)
if(iret.ne.0) then
  print *,'there is no output probability, 50% =  ',cfopg3(1:lfopg3),iret
endif

!iunit=iunit+1
!icfopg4=iunit
!lfopg4=len_trim(cfopg4)
!call baopenwa(icfopg4,cfopg4(1:lfopg4),iret)
!print *, 'fort.',icfopg4, cfopg4(1:lfopg4)
!if(iret.ne.0) then
!  print *,'there is no output ensemble average =  ',cfopg4(1:lfopg4),iret
!endif

!iunit=iunit+1
!icfopg5=iunit
!lfopg5=len_trim(cfopg5)
!call baopenwa(icfopg5,cfopg5(1:lfopg5),iret)
!print *, 'fort.',icfopg5, cfopg5(1:lfopg5)
!if(iret.ne.0) then
!  print *,'there is no output ensemble spread  =  ',cfopg5(1:lfopg5),iret
!endif

!iunit=iunit+1
!icfopg6=iunit
!lfopg6=len_trim(cfopg6)
!call baopenwa(icfopg6,cfopg6(1:lfopg6),iret)
!print *, 'fort.',icfopg6, cfopg6(1:lfopg6)
!if(iret.ne.0) then
!  print *,'there is no output probability, mode =  ',cfopg6(1:lfopg6),iret
!endif

! find grib message, maxgrd: number of grid points in the defined grid

do ifile=1,tfiles
  if(iskip(ifile).ne.0) then 
    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1
    call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
    call getgb2(icfipg(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
    maxgrd=gfld%ngrdpts
    call gf_free(gfld)
    if(iret.eq.0) goto 100
  endif       
enddo

100 continue

if(iret.ne.0) then; print*,' getgbeh, cannot get maxgrd ';endif
if(iret.ne.0) goto 1020

! get NCEP ensemble ipdt message: fixed surface and its scaled value

do ifile=1,tfiles
  if(iskip(ifile).eq.1) then 
    call getipdt_g2_surface(icfipg(ifile),nmvar,ipd1,ipd2,ipd10,ipd11,ipd12,ipd11_new,ipd12_new)
    ipd11=ipd11_new
    ipd12=ipd12_new
    go to 120
  endif
enddo

120 continue

! get CMC ensemble ipdt message: fixed surface and its scaled value

do ifile=1,tfiles
  if(iskip(ifile).eq.2) then 
    call getipdt_g2_surface(icfipg(ifile),nmvar,ipd1,ipd2,ipd10,ipd11,ipd12,ipd11_new,ipd12_new)
    ipd11_cmc=ipd11_new
    ipd12_cmc=ipd12_new
    go to 140
  endif
enddo

140 continue

allocate (fgrid(maxgrd,tfiles),fgrid_im(maxgrd),fstd(tfiles),fst(tfiles),                   &
          edr_p20(maxgrd),edr_p45(maxgrd),prob_90(maxgrd),prob_mode(maxgrd),ens_avg(maxgrd),&
          prob_10_t2m(maxgrd),prob_50_t2m(maxgrd),prob_90_t2m(maxgrd),prob_mode_t2m(maxgrd),&
          prob_avg_t2m(maxgrd),t2m_bias_fnmoc(maxgrd),                                      &
          ens_spr(maxgrd),anl_bias_cmc(maxgrd),t2m_bias_cmc(maxgrd),t2m_cmc(maxgrd),        &
          t2m_biasm06_cmc(maxgrd),t2m_cmcm06(maxgrd),anl_bias_fnmoc(maxgrd),                &
          t2m_fnmoc(maxgrd),t2m_biasm06_fnmoc(maxgrd),t2m_fnmocm06(maxgrd))

print *, '   '

! loop over variables

t2m_bias_cmc=0.0
t2m_biasm06_cmc=0.0
t2m_bias_fnmoc=0.0
t2m_biasm06_fnmoc=0.0

do ivar = 1, nvar  

  print *, '----- Start NCEP/CMC/FNMOC Ensemble Combination For Variable ',ffd(ivar),'------'
  print *, '   '

  iids=-9999;ipdt=-9999; igdt=-9999
  idisc=-1;  ipdtn=-1;   igdtn=-1

  ipdt(1)=ipd1(ivar)
  ipdt(2)=ipd2(ivar)
  ipdt(10)=ipd10(ivar)
  ipdt(12)=ipd12(ivar)

  fgrid=-9999.9999

  inum=0
  iret_ncep=0
  iret_bias_cmc=0
  iret_bias_fnmoc=0
  iret_biasm06_cmc=0
  iret_biasm06_fnmoc=0


  ! loop over NAEFS members, get operational ensemble forecast

  print *, '----- NCEP/CMC/FNMOC Ensemble Forecast for Current Time ------'; print *, '   '

  do imem=1,nfiles 

    iids=-9999;ipdt=-9999; igdt=-9999
    idisc=-1;  ipdtn=-1;   igdtn=-1

    ipdt(1)=ipd1(ivar)
    ipdt(2)=ipd2(ivar)
    ipdt(10)=ipd10(ivar)
    ipdt(12)=ipd12(ivar)

    fgrid_im=-9999.9999

    ! check how many cneter ensmebles are read
    ! mmod(ivar)=0, no this variable
    ! mmod(ivar)=1, only NCEP/GEFS
    ! mmod(ivar)=2, NCEP/GEFS + CMC/GEFS
    ! mmod(ivar)=3, NCEP/GEFS + CMC/GEFS + FNMOC/GEFS
    ! iskip(imem)=1,ensemble from NCEP
    ! iskip(imem)=2,ensemble from CMC 
    ! iskip(imem)=3,ensemble from FNMOC

    if(mmod(ivar).eq.0)  goto 200
    if(iskip(imem).eq.0) goto 200
    if(mmod(ivar).eq.1.and.iskip(imem).eq.2) goto 200
    if(mmod(ivar).eq.1.and.iskip(imem).eq.3) goto 200
    if(mmod(ivar).eq.2.and.iskip(imem).eq.3) goto 200

    if(ipd1(ivar).eq.0.and.ipd2(ivar).eq.6.and.ipd10(ivar).eq.103.and.ipd12(ivar).eq.2) then
       print *, " "
    else
      igdtn=-1; ipdtn=ipdn(ivar)
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(icfipg(imem),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfld,iret)
    endif

    if(iret.ne.0) print '(a12,4i7,a12,i4)', 'there is no ',jpdt(1),jpdt(2),jpdt(10),jpdt(12), &
                        ' for member ',imem

    ! judge if data come from right source

    ! %idsect(1)=  7: US National Weather Service - NCEP (WMC)
    ! %idsect(1) =54: Canadian Meteorological Service - Montreal (RSMC)s
    ! %idsect(1) =58: FNMOC
    ! %ipdtmpl(5)=114: NAEFS Products from joined NCEP,CMC global ensembles
    ! %ipdtmpl(5)=107: Global Ensemble Forecast System (GEFS)

    if(iret.eq.0) then
      if(iskip(imem).eq.2.and.gfld%idsect(1).ne.54) iret=99                           
      if(iskip(imem).eq.3.and.gfld%idsect(1).ne.58) iret=99                           
    endif

    if(iret.ne.0) call gf_free(gfld)
    if(iret.ne.0) goto 200

    ! print NCEP data message

    if (iskip(imem).eq.1) call printinfr(gfld,ivar)

    ! start CMC/FNMOC data processing
    ! invert & remove initial analyis difference between NCEP and CMC/FNMOC

    fgrid_im(1:maxgrd)=gfld%fld(1:maxgrd)


    call gf_free(gfld)

    inum=inum+1
    fgrid(1:maxgrd,inum)=fgrid_im(1:maxgrd)

    200 continue

  enddo          ! end of imem loop

  ! end of imem loop, calculate 10%, 50% and 90% probability

  print *, '   '; print *,ffd(ivar),' has member',inum; print *, '   '
  if(inum.le.10) goto 300

  print *, '   '; print *,  ' Combined Ensemble Data Example at Point 8601 '
  write (*,'(10f8.1)') (fgrid(8601,i),i=1,inum)
  print *, '   '

  print *, "maxgrd=",maxgrd
  
  do n=1,maxgrd

    fst(1:inum)=fgrid(n,1:inum)
    fstd(1:inum)=fgrid(n,1:inum)

    do i=1,inum
      weight(i)=1/float(inum)
    enddo

    ens_avg(n)=epdf(fst,weight,inum,1.0,0)
    ens_spr(n)=epdf(fst,weight,inum,2.0,0)

    call probability_gtg(fstd,inum,nthreshold,thresholds,fvalues)
    edr_p20(n)=fvalues(1)
    edr_p45(n)=fvalues(2)
    prob_90(n)=prob90

    prob_mode(n)=-9999.99

    if(abs(edr_p20(n)) > 1.1  .or. abs(edr_p45(n))  > 1.1) then
      print *, 'Abnormal   ', edr_p20(n), edr_p45(n)
      print *,  ' Sorted Ensemble Data Example at Point',n
      write (*,'(10f8.2)') (fstd(i),i=1,inum)
      print *,  ' edr_p20(n), edr_p45(n), 90% Probability at Point',n
      write (*,'(5f12.1)') edr_p20(n),edr_p45(n), prob_90(n),ens_avg(n),ens_spr(n)
      print *, '   '
    endif

  enddo

  print *, '   '



  ! get grib2 message from input file 

  do ifile=1,tfiles
    if(iskip(ifile).ne.0) then
      iids=-9999;ipdt=-9999; igdt=-9999
      idisc=-1;  ipdtn=-1;   igdtn=-1
      ipdt(1)=ipd1(ivar)
      ipdt(2)=ipd2(ivar)
      ipdt(10)=ipd10(ivar)
      ipdt(12)=ipd12(ivar)
      ipdtn=ipdn(ivar)
      call init_parm(ipdtn,ipdt,igdtn,igdt,idisc,iids)
      call getgb2(icfipg(ifile),0,jskp,jdisc,jids,jpdtn,jpdt,jgdtn,jgdt,unpack,jskp,gfldo,iret)
      if(iret.ne.0) goto 500

      if(iret.eq.0) goto 400
    endif
    500 continue
  enddo

  400 continue

  ! save NCEP message for output. If no NCEP data, save CMC data message later
  ! idsect(1) is for product generation center
  ! ipdtmpl(5) is for generation process identifier

  ! %idsect(1)=  7: US National Weather Service - NCEP (WMC)
  ! %idsect(1) =54: Canadian Meteorological Service - Montreal (RSMC)s
  ! %ipdtmpl(5)=114: NAEFS Products from joined NCEP,CMC global ensembles
  ! %ipdtmpl(5)=107: Global Ensemble Forecast System (GEFS)

  if(pidswitch.eq.1) then
    gfldo%idsect(1)=7
    gfldo%ipdtmpl(5)=114
  endif

  ! save probability forecast

  print*, '  '
  print *, '----- Output Probability for Current Time ------'
  print *, '   '

  ! when product difinition template 4.1/4.11 chenge to 4.2/4.12
  ! ipdtlen aslo change, need do modification for output
  ! code table 4.0, 2=derived forecast

  if(gfldo%ipdtnum.eq.1 .or. gfldo%ipdtnum.eq.0) ipdtnum_out=2
  if(gfldo%ipdtnum.eq.11) ipdtnum_out=12

!  call change_template4(gfldo%ipdtnum,ipdtnum_out,gfldo%ipdtmpl,gfldo%ipdtlen)

  ! extensions for 10% probability forecast
  
  gfldo%ipdtnum=ipdtnum_out          ! derived forecast

  gfldo%ipdtmpl(17)=inum   !PDT 4.2 Number of forecasts in the ensemble             

  gfldo%ipdtmpl(16)=193    ! code table 4.7, Percentile value (10%) of All Members

  gfldo%fld(1:maxgrd)=edr_p20(1:maxgrd)

  print *, '----- Probility 10% for Current Time ------'

  call putgb2(icfopg1,gfldo,iret)
  call printinfr(gfldo,ivar)

  ! extensions for 90% probability forecast

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=23          !: OCT 44, Product identifier, ensemble forecast value for X% probability
! kensout(5)=90          !: OCT 45, Spatial Smoothing of Product or Probability (if byte 44 = 23), 90=90% probability 

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=195    ! code table 4.7, Percentile value (90%) of All Members

  gfldo%fld(1:maxgrd)=prob_90(1:maxgrd)

  print *, '----- Probility 90% for Current Time ------'

!  call putgb2(icfopg2,gfldo,jret)
!  call printinfr(gfldo,ivar)

  ! extensions for 50% forecast

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=23          !: OCT 44, Product identifier, ensemble forecast value for X% probability
! kensout(5)=50          !: OCT 45, Spatial Smoothing of Product or Probability (if byte 44 = 23), 50=50% probability 

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=194    ! code table 4.7, Percentile value (50%) of All Members

  gfldo%fld(1:maxgrd)=edr_p45(1:maxgrd)

  print *, 'gfldo%idrtmpl(3)=',gfldo%idrtmpl(3)
  print *, '----- Probility 50% for Current Time ------'
  call putgb2(icfopg3,gfldo,jret)
  call printinfr(gfldo,ivar)

  ! extensions for mode forecast

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=24          !: OCT 44, Product identifier, the ensemble mode forecast (mode = 3*medium - 2*mean)
! kensout(5)=-1          !: OCT 45, Spatial Smoothing of Product

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=192    ! code table 4.7, unweighted mode of all Members

  gfldo%fld(1:maxgrd)=prob_mode(1:maxgrd)

  print *, '-----  Probility Mode for Current Time ------'
!  call putgb2(icfopg6,gfldo,jret)
!  call printinfr(gfldo,ivar)

  print *, '----- Output ensemble average and spread for Current Time ------'
  print *, '   '

  ! extensions for ensemble mean

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=4           !: OCT 44, Product identifier, 4 = Weighted mean ( of bias corrected forecasts)
! kensout(5)=-1          !: OCT 45, Spatial Smoothing of Product

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=0      ! code table 4.7, unweighted mean of all Members

  gfldo%fld(1:maxgrd)=ens_avg(1:maxgrd)

  print *, '-----  Ensemble Average for Current Time ------'
!  call putgb2(icfopg4,gfldo,jret)
!  call printinfr(gfldo,ivar)

  ! extensions for ensemble spread

! kpdsout(23)=2
! kensout(1)=1           !: OCT 41, Identifies application
! kensout(2)=5           !: OCT 42, 5= whole ensemble
! kensout(3)=0           !: OCT 43, Identification number
! kensout(4)=11          !: OCT 44, Product identifier, 11 = Standard deviation with respect to ensemble mean 
! kensout(5)=-1          !: OCT 45, Spatial Smoothing of Product

  gfldo%ipdtnum=ipdtnum_out          ! derived forecast
  gfldo%ipdtmpl(16)=4      ! code table 4.7, spread of all Members

  gfldo%fld(1:maxgrd)=ens_spr(1:maxgrd)

  print *, '-----  Ensemble Spread for Current Time ------'
!  call putgb2(icfopg5,gfldo,jret)
!  call printinfr(gfldo,ivar)

  call gf_free(gfldo)

  ! end of probability forecast calculation               

  300 continue

enddo 

! end of ivar loop                                      

! close files

do ifile=1,nfiles
  call baclose(icfipg(ifile),iret)
enddo

if(ifdebias.eq.1) then 
  call baclose(icfipg2,iret)
  call baclose(icfipg5,iret)
  if(ifhr.ge.6) then
    call baclose(icfipg1,iret)
    call baclose(icfipg3,iret)
    call baclose(icfipg4,iret)
    call baclose(icfipg6,iret)
  endif
endif

call baclose(icfopg1,iret)
!call baclose(icfopg2,iret)
call baclose(icfopg3,iret)
!call baclose(icfopg4,iret)
!call baclose(icfopg5,iret)
!call baclose(icfopg6,iret)

print *,'Probability Calculation Successfully Complete'

stop

1020  continue

print *, 'There is not Enough Files Input, Stop!'
!call errmsg('There is not Enough Files Input, Stop!')
!call errexit(1)

stop
end
