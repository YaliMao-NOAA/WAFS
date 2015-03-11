program naefs_bc_probability
!
! main program: naefs_bc_probability
!
! prgmmr: Bo Cui           org: np/wx20        date: 2007-07-21
!                          mod: np/wx20        date: 2008-01-21
!                          mod: np/wx20        date: 2009-04-03
!
! abstract: calculate 10%,50% & 90% probability forecast, ensemble mean, & spread of ensemble NCEP, CMC or NAEFS
! 
!            modification: use accumulated analysis difference to adjust CMC ensemble
!            modification: set NAEFS product ID as 114 
!                          set GEFS product ID as 107 that pass from bias-corrected product directly
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

!implicit none

integer     nmemd,nmvar,nvar,ivar,i,k,im,imem,n,inum,ignum
parameter   (nmemd=62,nmvar=50)

real,       allocatable :: fgrid_im(:),fgrid(:,:),fst(:),fgrid_t2m(:)
real,       allocatable :: ens_avg(:),ens_spr(:)
real,       allocatable :: anl_bias_cmc(:),t2m_bias_cmc(:),t2m_biasm06_cmc(:)
real,       allocatable :: t2m_cmc(:),t2m_cmcm06(:)
real,       allocatable :: anl_bias_fnmoc(:),t2m_bias_fnmoc(:),t2m_biasm06_fnmoc(:)
real,       allocatable :: t2m_fnmoc(:),t2m_fnmocm06(:)
real,       allocatable :: prob_10(:),prob_90(:),prob_mode(:),prob_50(:)
logical(1), allocatable :: lbms(:),lbmsout(:)
real        dmin,dmax,avg,spr,weight(nmemd)
integer     maxgrd,ndata,ifhr
integer     index,j,iret,jret             

double precision,allocatable :: fstd(:)
double precision prob10,prob90,prob50,mode

integer     jpds(200),jgds(200),jens(200),kpds(200),kgds(200),kens(200),lpds(200),lgds(200),lens(200)
integer     kpdsout(200),kgdsout(200),kensout(200)
integer     pds5(nmvar),pds6(nmvar),pds7(nmvar),mmod(nmvar)

character*10  ffd(nmvar)

! variables: u,v,t,h at 1000,925,850,700,500,250,200,100,50,10 mb,  &
!            slp pres t2m u10m v10m tmax tmin ULWRF(Surface) ULWRF(OLR) VVEL(850w)

!data pds5/7,7,7,7,7,7,7,7,7,7,  &
!          11,11,11,11,11,11,11,11,11,11, &
!          33,33,33,33,33,33,33,33,33,33, &
!          34,34,34,34,34,34,34,34,34,34, &
!          2,1,11,33,34,15,16,212,212,39/

!data pds6/100,100,100,100,100,100,100,100,100,100,  &
!          100,100,100,100,100,100,100,100,100,100,  &
!          100,100,100,100,100,100,100,100,100,100,  &
!          100,100,100,100,100,100,100,100,100,100,  &
!          102,1,105,105,105,105,105,1,8,100/

!data pds7/1000,925,850,700,500,250,200,100,50,10,   &
!          1000,925,850,700,500,250,200,100,50,10,   &
!          1000,925,850,700,500,250,200,100,50,10,   &
!          1000,925,850,700,500,250,200,100,50,10,   &
!          0,0,2,10,10,2,2,0,0,850/

!
integer     iret_ncep,iret_bias_cmc,iret_biasm06_cmc,ifdebias,iall_cmc,iall_fnmoc
integer     iret_bias_fnmoc,iret_biasm06_fnmoc
integer     iunit,lfipg(nmemd),lfipg1,lfipg2,lfipg3,lfipg4,lfipg5,lfipg6,icfipg(nmemd)
integer     icfipg1,icfipg2,icfipg3,icfipg4,icfipg5,icfipg6
integer     pidswitch,nfiles,iskip(nmemd),tfiles,ifile
integer     lfopg1,lfopg2,lfopg3,lfopg4,lfopg5,lfopg6
integer     icfopg1,icfopg2,icfopg3,icfopg4,icfopg5,icfopg6

character*100 cfipg(nmemd),cfipg1,cfipg2,cfipg3,cfipg4,cfipg5,cfipg6
character*100 cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6

namelist /namens/pidswitch,nfiles,ifdebias,iskip,cfipg,cfipg1,cfipg2,cfipg3,cfipg4,cfipg5,cfipg6, &
                 ifhr,cfopg1,cfopg2,cfopg3,cfopg4,cfopg5,cfopg6
namelist /varlist/ffd,pds5,pds6,pds7,mmod,nvar
 
read (5,namens)
!write (6,namens)

read (5,varlist)
!write(6,varlist)

print *, 'Input variables include ', (ffd(i),i=1,nvar)

! stop this program if there is no enough files put in 

print *, 'Input files size ', nfiles                  

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
  print *, 'fort.',icfipg(ifile), cfipg(ifile)(1:lfipg(ifile))
  call baopenr(icfipg(ifile),cfipg(ifile)(1:lfipg(ifile)),iret)
  if ( iret .ne. 0 ) then
    print *,'there is no NAEFS forecast, ifile,iret = ',cfipg(ifile)(1:lfipg(ifile)),iret
    tfiles=nfiles-1
    iskip(ifile)=0
  endif
enddo

if(ifdebias.eq.1) then 

  ! set the fort.* of intput CMC t2m forecast 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg1=iunit
    lfipg1=len_trim(cfipg1)
    call baopenr(icfipg1,cfipg1(1:lfipg1),iret)
    print *, 'fort.',icfipg1, cfipg1(1:lfipg1)
    if(iret.ne.0) then
      print *,'there is no previous 6hr CMC forecast input, iret=  ',cfipg1(1:lfipg1),iret
    endif
  endif

  ! set the fort.* of intput NCEP & CMC analysis difference   

  iunit=iunit+1
  icfipg2=iunit
  lfipg2=len_trim(cfipg2)
  call baopenr(icfipg2,cfipg2(1:lfipg2),iret)
  print *, 'fort.',icfipg2, cfipg2(1:lfipg2)
  if(iret.ne.0) then
    print *,'there is no NCEP & CMC analysis bias input, iret=  ',cfipg2(1:lfipg2),iret
  endif

  ! set the fort.* of intput NCEP & CMC analysis difference 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg3=iunit
    lfipg3=len_trim(cfipg3)
    call baopenr(icfipg3,cfipg3(1:lfipg3),iret)
    print *, 'fort.',icfipg3, cfipg3(1:lfipg3)
    if(iret.ne.0) then
      print *,'there is no NCEP & CMC analysis bias (6h ago) input, iret=  ',cfipg3(1:lfipg3),iret
    endif
  endif

  ! set the fort.* of intput FNMOC t2m forecast 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg4=iunit
    lfipg4=len_trim(cfipg4)
    call baopenr(icfipg4,cfipg4(1:lfipg4),iret)
    print *, 'fort.',icfipg4, cfipg4(1:lfipg4)
    if(iret.ne.0) then
      print *,'there is no previous 6hr FNMOC forecast input, iret=  ',cfipg4(1:lfipg4),iret
    endif
  endif

  ! set the fort.* of intput NCEP & FNMOC analysis difference   

  iunit=iunit+1
  icfipg5=iunit
  lfipg5=len_trim(cfipg5)
  call baopenr(icfipg5,cfipg5(1:lfipg5),iret)
  print *, 'fort.',icfipg5, cfipg5(1:lfipg5)
  if(iret.ne.0) then
    print *,'there is no NCEP & FNMOC analysis bias input, iret=  ',cfipg5(1:lfipg5),iret
  endif

  ! set the fort.* of intput NCEP & FNMOC analysis difference 6h ago   

  if(ifhr.ge.6) then
    iunit=iunit+1
    icfipg6=iunit
    lfipg6=len_trim(cfipg6)
    call baopenr(icfipg6,cfipg6(1:lfipg6),iret)
    print *, 'fort.',icfipg6, cfipg6(1:lfipg6)
    if(iret.ne.0) then
      print *,'there is no NCEP & FNMOC analysis bias (6h ago) input, iret=  ',cfipg6(1:lfipg6),iret
    endif
  endif

endif

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

iunit=iunit+1
icfopg2=iunit
lfopg2=len_trim(cfopg2)
call baopenwa(icfopg2,cfopg2(1:lfopg2),iret)
print *, 'fort.',icfopg2, cfopg2(1:lfopg2)
if(iret.ne.0) then
  print *,'there is no output probability, 90% = ',cfopg2(1:lfopg2),iret
endif

iunit=iunit+1
icfopg3=iunit
lfopg3=len_trim(cfopg3)
call baopenwa(icfopg3,cfopg3(1:lfopg3),iret)
print *, 'fort.',icfopg3, cfopg3(1:lfopg3)
if(iret.ne.0) then
  print *,'there is no output probability, 50% =  ',cfopg3(1:lfopg3),iret
endif

iunit=iunit+1
icfopg4=iunit
lfopg4=len_trim(cfopg4)
call baopenwa(icfopg4,cfopg4(1:lfopg4),iret)
print *, 'fort.',icfopg4, cfopg4(1:lfopg4)
if(iret.ne.0) then
  print *,'there is no output ensemble average =  ',cfopg4(1:lfopg4),iret
endif

iunit=iunit+1
icfopg5=iunit
lfopg5=len_trim(cfopg5)
call baopenwa(icfopg5,cfopg5(1:lfopg5),iret)
print *, 'fort.',icfopg5, cfopg5(1:lfopg5)
if(iret.ne.0) then
  print *,'there is no output ensemble spread  =  ',cfopg5(1:lfopg5),iret
endif

iunit=iunit+1
icfopg6=iunit
lfopg6=len_trim(cfopg6)
call baopenwa(icfopg6,cfopg6(1:lfopg6),iret)
print *, 'fort.',icfopg6, cfopg6(1:lfopg6)
if(iret.ne.0) then
  print *,'there is no output probability, mode =  ',cfopg6(1:lfopg6),iret
endif

! judge if all member are from CMC data, 1=all member are from CMC data

iall_cmc=0
do imem=1,nfiles 
  if (iskip(imem).eq.2) then 
    iall_cmc=iall_cmc+1
  endif
enddo

if(iall_cmc.eq.nfiles) iall_cmc=1

iall_fnmoc=0
do imem=1,nfiles 
  if (iskip(imem).eq.3) then 
    iall_fnmoc=iall_fnmoc+1
  endif
enddo

if(iall_fnmoc.eq.nfiles) iall_fnmoc=1

! find grib message. input: jpds,jgds and jens.  output: kpds,kgds,kens
! ndata: integer number of bites in the grib message
! index=0, to get index buffer from the grib file not the grib index file
! lbms, logical*1 (maxgrd or kf) unpacked bitmap if present

index=0; j=-1; iret=0
jpds=-1; jgds=-1; jens=-1

do ifile=1,tfiles
  if(iskip(ifile).ne.0) then 
    call getgbeh(icfipg(ifile),index,j,jpds,jgds,jens,ndata,maxgrd,j,kpds,kgds,kens,iret)
    if(iret.eq.0) goto 100
  endif       
enddo

100 continue

allocate (fgrid(maxgrd,tfiles),fgrid_im(maxgrd),fstd(tfiles),fst(tfiles),lbms(maxgrd),lbmsout(maxgrd))
allocate (prob_10(maxgrd),prob_50(maxgrd),prob_90(maxgrd),prob_mode(maxgrd),ens_avg(maxgrd),ens_spr(maxgrd))
allocate (anl_bias_cmc(maxgrd),t2m_bias_cmc(maxgrd),t2m_cmc(maxgrd),t2m_biasm06_cmc(maxgrd),t2m_cmcm06(maxgrd))
allocate (anl_bias_fnmoc(maxgrd),t2m_bias_fnmoc(maxgrd),t2m_fnmoc(maxgrd),t2m_biasm06_fnmoc(maxgrd),t2m_fnmocm06(maxgrd))

print *, '   '

! loop over variables

t2m_bias_cmc=0.0
t2m_biasm06_cmc=0.0
t2m_bias_fnmoc=0.0
t2m_biasm06_fnmoc=0.0

do ivar = 1, nvar  

  print *, '----- Start NCEP/CMC/FNMOC Ensemble Combination For Variable ',ffd(ivar),'------'; print *, '   '

  index=0; j=-1; iret=0
  jpds=-1; jgds=-1; jens=-1
  kpds=-1; kgds=-1; kens=-1

  jpds(5)=pds5(ivar)
  jpds(6)=pds6(ivar)
  jpds(7)=pds7(ivar)

  fgrid=-9999.9999

  inum=0
  iret_ncep=0
  iret_bias_cmc=0
  iret_bias_fnmoc=0
  iret_biasm06_cmc=0
  iret_biasm06_fnmoc=0

  ! get NCEP and CMC analyis difference 

  if(ifdebias.eq.1) then 

    ! get NCEP & CMC analysis bias data

    index=0; j=-1; iret_bias_cmc=0

    if(pds5(ivar).ne.15.and.pds5(ivar).ne.16) then

      call getgbe(icfipg2,index,maxgrd,j,jpds,jgds,jens,ndata,j,kpds,kgds,kens,lbms,anl_bias_cmc,iret_bias_cmc)

      if(iret_bias_cmc.ne.0) then
        print*, 'there is no ',ffd(ivar), jpds(5),jpds(6),jpds(7),' for CMC analysis bias '
        anl_bias_cmc=0.0
      else
        print *, '   '; print *, '----- NCEP & CMC Analysis Bias for Current Cycle ------'
        call message(anl_bias_cmc,maxgrd,kpds,kens,lbms,ivar)
      endif

    endif

    ! there is no Tmax and Tmin from CMC/NCEP analysis difference, don't read them

    ! get NCEP & FNMOC analysis bias data

    index=0; j=-1; iret_bias_fnmoc=0

    if(pds5(ivar).ne.15.and.pds5(ivar).ne.16) then

      call getgbe(icfipg5,index,maxgrd,j,jpds,jgds,jens,ndata,j,kpds,kgds,kens,lbms,anl_bias_fnmoc,iret_bias_fnmoc)

      if(iret_bias_fnmoc.ne.0) then
        print*, 'there is no ',ffd(ivar),jpds(5),jpds(6),jpds(7),' for FNMOC analysis bias'; print *, '   '
        anl_bias_fnmoc=0.0
      else
        print *, '   '; print *, '----- NCEP & FNMOC Analysis Bias for Current Cycle ------'
        call message(anl_bias_fnmoc,maxgrd,kpds,kens,lbms,ivar)
      endif

    endif

    ! there is no Tmax and Tmin from FNMOC/NCEP analysis difference, don't read them
 
  endif

  ! loop over NAEFS members, get operational ensemble forecast

  print *, '----- NCEP/CMC/FNMOC Ensemble Forecast for Current Time ------'; print *, '   '

  do imem=1,nfiles 

    !if (iskip(imem).eq.1) print *, '----- NCEP Ensemble Forecast for Current Time ------'; print *, '   '
    !if (iskip(imem).eq.2) print *, '----- CMC Ensemble Forecast for Current Time ------'; print *, '   '
    !if (iskip(imem).eq.3) print *, '----- FNMOC Ensemble Forecast for Current Time ------'; print *, '   '

    index=0; j=-1; iret=0
    jpds=-1; jgds=-1; jens=-1
    kpds=-1; kgds=-1; kens=-1

    jpds(5)=pds5(ivar)
    jpds(6)=pds6(ivar)
    jpds(7)=pds7(ivar)

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

    call getgbe(icfipg(imem),index,maxgrd,j,jpds,jgds,jens,ndata,j,kpds,kgds,kens,lbms,fgrid_im,iret)

    if(iret.ne.0) then; print*, 'there is no ',ffd(ivar), jpds(5),jpds(6),jpds(7),' for member ',imem; endif  

    if (iret.ne.0) goto 200

    ! print NCEP data message

    if (iskip(imem).eq.1) then
      call message(fgrid_im,maxgrd,kpds,kens,lbms,ivar)
    endif

    ! save NCEP message for output. If there is no NCEP data, save CMC data message later
    ! pds(1) is for product generation center, pds(2) is for product ID 
    ! pds(1)=  7: US National Weather Service - NCEP (WMC) 
    ! pds(1) =54: Canadian Meteorological Service - Montreal (RSMC)s
    ! pds(2)=114: NAEFS Products from joined NCEP,CMC global ensembles  
    ! pds(2)=107: Global Ensemble Forecast System (GEFS)

    if (iskip(imem).eq.1) then
      kpdsout=kpds; kgdsout=kgds; kensout=kens; lbmsout=lbms
      if(pidswitch.eq.1) then
        kpdsout(1)=7
        kpdsout(2)=114
      endif   
    endif

    ! start CMC data processing, invert & remove initial analyis difference between NCEP and CMC

    if (iskip(imem).eq.2.or.iskip(imem).eq.3) then

      call cvncep(fgrid_im,maxgrd,kpds,kgds,kens,lbms,ivar)

      ! judeg if all member are from CMC data

      if (iall_cmc.eq.1.or.iall_fnmoc.eq.1) then
        kpdsout=kpds; kgdsout=kgds; kensout=kens; lbmsout=lbms
        if(pidswitch.eq.1) then
          kpdsout(1)=7
          kpdsout(2)=114
        endif   
      endif

    endif

    ! adjust CMC ensemble forecast 

    if(ifdebias.eq.1.and.iskip(imem).eq.2) then 

      if(pds5(ivar).ne.15.and.pds5(ivar).ne.16) then
        call debias(anl_bias_cmc,fgrid_im,maxgrd)
      else
        index=0;j=-1;iret=0
        jpds=-1; jgds=-1; jens=-1
        lpds=-1; lgds=-1; lens=-1
        jpds(5)=11; jpds(6)=105; jpds(7)=2
        jpds(23)=2
        jens(2)=kens(2)
        jens(3)=kens(3)

        print *, '----- CMC Ensemble Forecast T2m 6 hour ago ------'
        call getgbe(icfipg1,index,maxgrd,j,jpds,jgds,jens,ndata,j,lpds,lgds,lens,lbms,t2m_cmcm06,iret)
        call cvncep(t2m_cmcm06,maxgrd,lpds,lgds,lens,lbms,ivar)
        !call message(t2m_cmcm06,maxgrd,lpds,lens,lbms,ivar)

        index=0; j=-1; iret=0
        lpds=-1; lgds=-1; lens=-1

        print *, '----- CMC Ensemble Forecast T2m Current Time ------'

        call getgbe(icfipg(imem),index,maxgrd,j,jpds,jgds,jens,ndata,j,lpds,lgds,lens,lbms,t2m_cmc,jret)
        call cvncep(t2m_cmc,maxgrd,lpds,lgds,lens,lbms,ivar)
        !call message(t2m_cmc,maxgrd,lpds,lens,lbms,ivar)

        ! show NCEP & CMC T2m analysis bias 6 hour ago

        index=0; j=-1; iret_biasm06_cmc=0
        jpds=-1; jgds=-1; jens=-1
        lpds=-1; lgds=-1; lens=-1
        jpds(5)=11; jpds(6)=105; jpds(7)=2

        call getgbe(icfipg3,index,maxgrd,j,jpds,jgds,jens,ndata,j,lpds,lgds,lens,lbms,t2m_biasm06_cmc,iret_biasm06_cmc)

        print *, '   '; print *, '----- NCEP & CMC T2m Analysis Bias 6 Hour Ago ------'
        call message(t2m_biasm06_cmc,maxgrd,lpds,lens,lbms,ivar)

        ! show NCEP & CMC T2m analysis bias 

        index=0; j=-1; iret_bias_cmc=0
        lpds=-1; lgds=-1; lens=-1

        call getgbe(icfipg2,index,maxgrd,j,jpds,jgds,jens,ndata,j,lpds,lgds,lens,lbms,t2m_bias_cmc,iret_bias_cmc)

        print *, '   '; print *, '----- NCEP & CMC T2m Analysis Bias for Current Cycle ------'
        call message(t2m_bias_cmc,maxgrd,lpds,lens,lbms,ivar)

        if(iret.eq.0.and.jret.eq.0.and.iret_bias_cmc.eq.0.and.iret_biasm06_cmc.eq.0) then 
          call biastmaxtmin(fgrid_im,t2m_cmcm06,t2m_cmc,t2m_biasm06_cmc,t2m_bias_cmc,anl_bias_cmc,maxgrd)
          print *, '   '; print *, '----- NCEP & CMC Analysis Bias for Tmax or Tmin ------'
          call message(anl_bias_cmc,maxgrd,lpds,lens,lbms,ivar)
        else
          anl_bias_cmc=0.0
        endif

        call debias(anl_bias_cmc,fgrid_im,maxgrd)

      endif  !  end for varibale is tmin and tmax

      print *, '----- After Debias CMC Forecast for Current Time ------'
      call message(fgrid_im,maxgrd,kpds,kens,lbms,ivar)

    endif  !  end for ifdebias.eq.1 and iskip(imem).eq.2

    ! adjust FNMOC ensemble forecast 

    if(ifdebias.eq.1.and.iskip(imem).eq.3) then 

      if(pds5(ivar).ne.15.and.pds5(ivar).ne.16) then
        call debias(anl_bias_fnmoc,fgrid_im,maxgrd)
      else
        index=0; j=-1; iret=0
        jpds=-1; jgds=-1; jens=-1
        jpds(5)=11; jpds(6)=105; jpds(7)=2

        jpds(23)=2
        jens(2)=kens(2)
        jens(3)=kens(3)

        lpds=-1; lgds=-1; lens=-1

        print *, '----- FNMOC Ensemble Forecast T2m 6 hour ago ------'; print *, '   '
        call getgbe(icfipg4,index,maxgrd,j,jpds,jgds,jens,ndata,j,lpds,lgds,lens,lbms,t2m_fnmocm06,iret)
        call cvncep(t2m_fnmocm06,maxgrd,lpds,lgds,lens,lbms,ivar)

        index=0; j=-1; iret=0
        lpds=-1; lgds=-1; lens=-1

        print *, '----- FNMOC Ensemble Forecast T2m Current Time ------'; print *, '   '
        call getgbe(icfipg(imem),index,maxgrd,j,jpds,jgds,jens,ndata,j,lpds,lgds,lens,lbms,t2m_fnmoc,jret)
        call cvncep(t2m_fnmoc,maxgrd,lpds,lgds,lens,lbms,ivar)

        ! show NCEP & FNMOC T2m analysis bias 6 hour ago

        index=0; j=-1; iret_biasm06_fnmoc=0
        jpds=-1; jgds=-1; jens=-1
        lpds=-1; lgds=-1; lens=-1
        jpds(5)=11; jpds(6)=105; jpds(7)=2

        call getgbe(icfipg6,index,maxgrd,j,jpds,jgds,jens,ndata,j,lpds,lgds,lens,lbms,t2m_biasm06_fnmoc,iret_biasm06_fnmoc)

        print *, '   '; print *, '----- NCEP & FNMOC T2m Analysis Bias 6 Hour Ago ------'
        call message(t2m_biasm06_fnmoc,maxgrd,lpds,lens,lbms,ivar)

        ! show NCEP & FNMOC T2m analysis bias 

        index=0; j=-1; iret_bias_fnmoc=0
        lpds=-1; lgds=-1; lens=-1

        call getgbe(icfipg5,index,maxgrd,j,jpds,jgds,jens,ndata,j,lpds,lgds,lens,lbms,t2m_bias_fnmoc,iret_bias_fnmoc)

        print *, '   '; print *, '----- NCEP & FNMOC T2m Analysis Bias for Current Cycle ------'
        call message(t2m_bias_fnmoc,maxgrd,lpds,lens,lbms,ivar)

        if(iret.eq.0.and.jret.eq.0.and.iret_bias_fnmoc.eq.0.and.iret_biasm06_fnmoc.eq.0) then 
          call biastmaxtmin(fgrid_im,t2m_fnmocm06,t2m_fnmoc,t2m_biasm06_fnmoc,t2m_bias_fnmoc,anl_bias_fnmoc,maxgrd)
          print *, '   '; print *, '----- NCEP & FNMOC Analysis Bias for Tmax or Tmin ------'
          call message(anl_bias_fnmoc,maxgrd,lpds,lens,lbms,ivar)
        else
          anl_bias_fnmoc=0.0
        endif

        call debias(anl_bias_fnmoc,fgrid_im,maxgrd)

      endif    !  end for varibale is tmin and tmax

      print *, '----- After Debias FNMOC Forecast for Current Time ------'
      call message(fgrid_im,maxgrd,kpds,kens,lbms,ivar)

    endif    !  end for ifdebias.eq.1 and iskip(imem).eq.3

    inum=inum+1
    fgrid(1:maxgrd,inum)=fgrid_im(1:maxgrd)

    200 continue

  enddo          ! end of imem loop

  ! end of imem loop, calculate 10%, 50% and 90% probability

  print *, '   '; print *,ffd(ivar),' has member',inum; print *, '   '
  if(inum.le.10) goto 300

  print *, '   '; print *,  ' Combined Ensemble Data Example at Point 8601 '
  write (*,'(10f8.1)') (fgrid(8601,i),i=1,inum)

  do n=1,maxgrd

    fst(1:inum)=fgrid(n,1:inum)
    fstd(1:inum)=fgrid(n,1:inum)

    do i=1,inum
      weight(i)=1/float(inum)
    enddo

    ens_avg(n)=epdf(fst,weight,inum,1.0,0)
    ens_spr(n)=epdf(fst,weight,inum,2.0,0)

    call probability(fstd,inum,prob10,prob90,prob50)
    prob_10(n)=prob10
    prob_90(n)=prob90
    prob_50(n)=prob50

    if(prob_50(n).gt.-999.0.and.prob_50(n).lt.999999.0.and.ens_avg(n).gt.-999.0.and.ens_avg(n).lt.999999.0) then
      prob_mode(n)=3*prob_50(n)-2*ens_avg(n)
    else
      prob_mode(n)=-9999.99
!     print *,  ' there is no mode forecast at point',n,prob_mode(n),lbmsout(n)
!     write (*,'(10f8.1)') (fst(i),i=1,inum)
    endif

    if(prob10.eq.0.0.or.prob90.eq.0.0.or.prob50.eq.0.0) then
      print *, '   '
      print *,  ' Sorted Ensemble Data Example at Point',n
      write (*,'(10f8.2)') (fst(i),i=1,inum)
      print *,  ' 10%, 90%, 50% Probability at Point',n
      write (*,'(10f8.1)') prob_10(n),prob_90(n), prob_50(n)
    endif

  enddo

  print *, '   '

  ! save probability forecast

  print*, '  '
  print *, '----- Output Probability for Current Time ------'
  print *, '   '

  ! extensions for 10% probability forecast

  kpdsout(23)=2
  kensout(1)=1           !: OCT 41, Identifies application
  kensout(2)=5           !: OCT 42, 5= whole ensemble
  kensout(3)=0           !: OCT 43, Identification number
  kensout(4)=23          !: OCT 44, Product identifier, ensemble forecast value for X% probability
  kensout(5)=10          !: OCT 45, Spatial Smoothing of Product or Probability (if byte 44 = 23), 10=10% probability

  call putgbe(icfopg1,maxgrd,kpdsout,kgdsout,kensout,lbmsout,prob_10,jret)

  print *, '----- Probility 10% for Current Time ------'
  call message(prob_10,maxgrd,kpdsout,kensout,lbmsout,ivar)

  ! extensions for 90% probability forecast

  kpdsout(23)=2
  kensout(1)=1           !: OCT 41, Identifies application
  kensout(2)=5           !: OCT 42, 5= whole ensemble
  kensout(3)=0           !: OCT 43, Identification number
  kensout(4)=23          !: OCT 44, Product identifier, ensemble forecast value for X% probability
  kensout(5)=90          !: OCT 45, Spatial Smoothing of Product or Probability (if byte 44 = 23), 90=90% probability 

  call putgbe(icfopg2,maxgrd,kpdsout,kgdsout,kensout,lbmsout,prob_90,jret)

  print *, '----- Probility 90% for Current Time ------'
  call message(prob_90,maxgrd,kpdsout,kensout,lbmsout,ivar)

  ! extensions for 50% forecast

  kpdsout(23)=2
  kensout(1)=1           !: OCT 41, Identifies application
  kensout(2)=5           !: OCT 42, 5= whole ensemble
  kensout(3)=0           !: OCT 43, Identification number
  kensout(4)=23          !: OCT 44, Product identifier, ensemble forecast value for X% probability
  kensout(5)=50          !: OCT 45, Spatial Smoothing of Product or Probability (if byte 44 = 23), 50=50% probability 

  call putgbe(icfopg3,maxgrd,kpdsout,kgdsout,kensout,lbmsout,prob_50,jret)

  print *, '-----  Probility 50% for Current Time ------'
  call message(prob_50,maxgrd,kpdsout,kensout,lbmsout,ivar)

  ! extensions for mode forecast

  kpdsout(23)=2
  kensout(1)=1           !: OCT 41, Identifies application
  kensout(2)=5           !: OCT 42, 5= whole ensemble
  kensout(3)=0           !: OCT 43, Identification number
  kensout(4)=24          !: OCT 44, Product identifier, the ensemble mode forecast (mode = 3*medium - 2*mean)
  kensout(5)=-1          !: OCT 45, Spatial Smoothing of Product

  call putgbe(icfopg6,maxgrd,kpdsout,kgdsout,kensout,lbmsout,prob_mode,jret)

  print *, '-----  Probility Mode for Current Time ------'
  call message(prob_mode,maxgrd,kpdsout,kensout,lbmsout,ivar)

  print *, '----- Output ensemble average and spread for Current Time ------'
  print *, '   '

  ! extensions for ensemble mean

  kpdsout(23)=2
  kensout(1)=1           !: OCT 41, Identifies application
  kensout(2)=5           !: OCT 42, 5= whole ensemble
  kensout(3)=0           !: OCT 43, Identification number
  kensout(4)=4           !: OCT 44, Product identifier, 4 = Weighted mean ( of bias corrected forecasts)
  kensout(5)=-1          !: OCT 45, Spatial Smoothing of Product

  call putgbe(icfopg4,maxgrd,kpdsout,kgdsout,kensout,lbmsout,ens_avg,jret)

  print *, '-----  Ensemble Average for Current Time ------'
  call message(ens_avg,maxgrd,kpdsout,kensout,lbmsout,ivar)

  ! extensions for ensemble spread

  kpdsout(23)=2
  kensout(1)=1           !: OCT 41, Identifies application
  kensout(2)=5           !: OCT 42, 5= whole ensemble
  kensout(3)=0           !: OCT 43, Identification number
  kensout(4)=11          !: OCT 44, Product identifier, 11 = Standard deviation with respect to ensemble mean 
  kensout(5)=-1          !: OCT 45, Spatial Smoothing of Product

  call putgbe(icfopg5,maxgrd,kpdsout,kgdsout,kensout,lbmsout,ens_spr,jret)

  print *, '-----  Ensemble Spread for Current Time ------'
  call message(ens_spr,maxgrd,kpdsout,kensout,lbmsout,ivar)

  ! end of probability forecast calculation               

  300 continue
enddo

! end of ivar loop                                      

! close files

do ifile=1,nfiles
  call baclose(icfipg(ifile),iret)
enddo

call baclose(icfipg1,iret)
call baclose(icfipg2,iret)

call baclose(icfopg1,iret)
call baclose(icfopg2,iret)
call baclose(icfopg3,iret)
call baclose(icfopg4,iret)
call baclose(icfopg5,iret)
call baclose(icfopg6,iret)

print *,'Probability Calculation Successfully Complete'

stop

1020  continue

print *, 'There is not Enough Files Input, Stop!'
call errmsg('There is not Enough Files Input, Stop!')
call errexit(1)

stop
end

subroutine grange(n,ld,d,dmin,dmax)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM: GRANGE(N,LD,D,DMIN,DMAX)
!   PRGMMR: YUEJIAN ZHU       ORG:NP23          DATE: 97-03-17
!
! ABSTRACT: THIS SUBROUTINE WILL ALCULATE THE MAXIMUM AND
!           MINIMUM OF A ARRAY
!
! PROGRAM HISTORY LOG:
!   97-03-17   YUEJIAN ZHU (WD20YZ)
!
! USAGE:
!
!   INPUT ARGUMENTS:
!     N        -- INTEGER
!     LD(N)    -- LOGICAL OF DIMENSION N
!     D(N)     -- REAL ARRAY OF DIMENSION N
!
!   OUTPUT ARGUMENTS:
!     DMIN     -- REAL NUMBER ( MINIMUM )
!     DMAX     -- REAL NUMBER ( MAXIMUM )
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN
!
!$$$
logical(1) ld(n)
real d(n)
real dmin,dmax
integer i,n
dmin=1.e40
dmax=-1.e40
do i=1,n
  if(ld(i)) then
    dmin=min(dmin,d(i))
    dmax=max(dmax,d(i))
  endif
enddo
return
end

subroutine debias(bias,fgrid,maxgrd)

!     apply the bias correction
!
!     parameters
!                  fgrid  ---> ensemble forecast
!                  bias   ---> bias estimation

implicit none

integer maxgrd,ij
real bias(maxgrd),fgrid(maxgrd)

do ij=1,maxgrd
  if(fgrid(ij).gt.-99999.0.and.fgrid(ij).lt.999999.0.and.bias(ij).gt.-99999.0.and.bias(ij).lt.999999.0) then
    fgrid(ij)=fgrid(ij)-bias(ij)
  else
    fgrid(ij)=fgrid(ij)
  endif
enddo

return
end

subroutine cvncep(fgrid,maxgrd,kpds,kgds,kens,lbms,ivar)

! invert CMC data from north to south  
!
!  parameters

!        fgrid    ---> ensemble forecast
!        lpds     ---> grid descraption sction from NCEP GEFS data
!                      CMC global ensemble data kgds(1-11) = 0 360 181 -90000 0 136  90000 359000 1000 1000 64
!                      start point ( -90.0 0), end point (  90.0, 359) 
!                      NCEP global ensemble data kgds(1-11)= 0 360 181  90000 0 128 -90000 -1000 1000 1000 0   
!                      start point (  90.0 0), end point ( -90.0, -1.0) 
!                      the difinination of lon 359 and -1.0 are for the same point
!
!         input:  fgrid before invert
!
!         output: fgrid after invert
!

implicit none

integer    maxgrd,i,j,ij,ijcv,ilon,ilat,ivar,iret
integer    kpds(200),kgds(200),kens(200),lgds(11)
data       lgds/0,360,181,90000,0,128,-90000,-1000,1000,1000,0/
real       fgrid(maxgrd),temp(maxgrd)
logical(1) lbms(maxgrd)

! judge if all read in  data have the same format as NCEP GEFS

if(kgds(4).eq.lgds(4).and.kgds(7).eq.lgds(7)) return

! invert forecast data from north to south                              

print *, '   '
print *, '----- Reading In Data Before Invert, South to North ------'
call message(fgrid,maxgrd,kpds,kens,lbms,ivar)

ilon=kgds(2)
ilat=kgds(3)

do i = 1, ilon
  do j = 1, ilat
   ij=(j-1)*ilon + i
   ijcv=(ilat-j)*ilon + i
   temp(ijcv)=fgrid(ij)
 enddo
enddo

fgrid=temp

do i=1,11
  kgds(i)=lgds(i)
enddo

print *, '----- Reading In Data After Invert, North to South ------'
call message(fgrid,maxgrd,kpds,kens,lbms,ivar)

return
end

subroutine message(grid,maxgrd,kpds,kens,lbms,ivar)

! print data information

implicit none

integer    kpds(200),kens(200),ivar,maxgrd,i
real       grid(maxgrd),dmin,dmax
logical(1) lbms(maxgrd)

call grange(maxgrd,lbms,grid,dmin,dmax)

print*, 'Irec pds5 pds6 pds7 pds8 pds9 pd10 pd11 pd14 pd15 pd16 e2  e3  ndata   Maximun    Minimum   Example'
print '(i4,10i5,2i4,i8,3f10.2)',ivar,(kpds(i),i=5,11),(kpds(i),i=14,16),(kens(i),i=2,3),maxgrd,dmax,dmin,grid(8601)
print *, '   '

return
end

subroutine biastmaxtmin(fgrid,t2m_cmcm06,t2m_cmc,t2m_biasm06,t2m_bias,anl_bias,maxgrd)

!     get Tmax and Tmin bias 
!
!         bias=a*t2m_biasm06+b*t2m_bias
!
!     parameters
!                  fgrid        ---> tmax or tmin forecast
!                  t2m_cmcm06   ---> t2m ensemble forecas 6hr ago
!                  t2m_cmc    ---> t2m ensemble forecast 
!                  t2m_biasm06 ---> t2m analysis bias 6hr ago
!                  t2m_bias    ---> t2m analysis bias
!

implicit none

integer maxgrd,ij
real t2m_biasm06(maxgrd),t2m_bias(maxgrd),t2m_cmc(maxgrd),t2m_cmcm06(maxgrd)
real fgrid(maxgrd),anl_bias(maxgrd)
real lmta,ym,y0,y1,a,b

do ij=1,maxgrd
  ym=fgrid(ij)
  y0=t2m_cmcm06(ij)
  y1=t2m_cmc(ij)
  if(ym.gt.-9999.0.and.ym.lt.999999.0.and.y0.gt.-9999.0.and.y0.lt.999999.0.and.y1.gt.-9999.0.and.y1.lt.999999.0) then
    if(ym.ne.y1.and.ym.ne.y0) then
      lmta=sqrt(abs((ym-y0)/(ym-y1)))
      a=lmta/(1+lmta)
      b=1/(1+lmta)
    else
      if(ym.eq.y1.and.ym.ne.y0) then
        a=0.0
        b=1.0
      endif
      if(ym.eq.y1.and.ym.eq.y0) then
        a=0.5
        b=0.5
      endif
      if(ym.ne.y1.and.ym.eq.y0) then
        a=1.0
        b=0.0
      endif
    endif
  endif
  anl_bias(ij)=b*t2m_biasm06(ij)+a*t2m_bias(ij)
!if(ij.eq.8601) then 
! print *, 'a=',a,' b=', b, ' bias=', anl_bias(ij)
! print *, 't2m_biasm06=',t2m_biasm06(ij),' t2m_bias(ij)=',t2m_bias(ij) 
!endif
enddo

!print *, 'in tmaxtmin'

return
end









