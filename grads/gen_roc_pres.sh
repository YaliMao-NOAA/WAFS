#!/bin/ksh
set -x

#-----------------------------------------------------------------------------
#--compute scalar variable pattern correlation, bias, mean squared error (MSE), 
#  variances, MSE by mean difference, MSE by pattern variation,
#  and MSE Skill Score (Murphy, MWR 1988). Write out RMSE instead of MSE.
#-----------------------------------------------------------------------------
# VSDB Record:   
#    X1=MEAN[f], X2=MEAN[a], X3=MEAN[f*a], X4=MEAN[f*f], X5=MEAN[a*a]
#      where f is forecast and a is analysis/observation, MEAN is domain mean.
#
#  Pattern correlation : R=( X3 - X1*X2 ) / sqrt{var(f)*var(a)}
#    where var(f)={ X4 - X1*X1 } 
#          var(a)={ X5 - X2*X2 } 
#  Mean biases:    bias= ( X1 - X2 )
#  RMSE:           rms= sqrt( X4 + X5 - 2*X3 )
#  MSE:            mse= ( X4 + X5 - 2*X3 )
#  MSE by mean difference: e_m=(X1-X2)**2
#  MSE by pattern variation: 
#     e_p={ var(f) + var(a) - 2*sqrt[var(f)*var(a)]*R }
#        =[ mse - e_m ]
#  Murphy's MSE Skill Score: 
#     msess=1-MSE/var(a)
#          =2*R*sqrt[var(f)/var(a)]-[var(f)/var(a)]-e_m/var(a)


# http://www.dtcenter.org/met/users/docs/presentations/WRF_Users_2012.pdf
#-------------------------------------------------------


export exedir=${exedir:-/ptmpp1/$LOGNAME/vsdb_stats}
if [ ! -s $exedir ]; then mkdir -p $exedir; fi
cd $exedir

export vsdb_data=${vsdb_data:-/climate/save/wx24fy/VRFY/vsdb_data06}
export NWPROD=${NWPROD:-/nwprod}
export ndate=${ndate:-$NWPROD/util/exec/ndate}
export FC=${FC:-ifort}
export FFLAG=${FFLAG:-" "}

export FHOUR0=${FHOUR0:-06}
       fhours=""


## verification type: pres
export vtype=${1:-pres}

## verification variable parameters: e.g. HGT G2/NHX 
export vnam=${2:-ICIP}
export reg=${3:-G45}
export levlist=${4:-"P800 P700 P600 P500 P400"}
       nlev=`echo $levlist |wc -w`

## verification ending date and number of days back 
export edate=${5:-20150425}
export ndays=${6:-31}
       nhours=`expr $ndays \* 24 - 24`
       tmp=`$ndate -$nhours ${edate}00 `
       sdate=`echo $tmp | cut -c 1-8`

## forecast cycles to be vefified: 00Z, 06Z, 12Z, 18Z, all
export cyclist=${7:-"00"}
       ncyc=`echo $cyclist | wc -w`

## forecast length in every 3/6 hours from f06, replacing origianl days
export vlength=${8:-36}

## forecast output frequency requried for verification
export fhout=${9:-3}
# WAFS: no f03 forecast, starting from f06
       nfcst=`expr $(( vlength - $FHOUR0 )) \/ $fhout + 1`

## create output name (first remove / from parameter names)
vnam1=`echo $vnam | sed "s?/??g" |sed "s?_WV1?WV?g"`  
reg1=`echo $reg | sed "s?/??g"`
outname1=${vnam1}_${reg1}_${sdate}${edate}
outname=${10:-$outname1}

## remove missing data from all models to unify sample size, 0-->NO, 1-->Yes
maskmiss=${maskmiss:-${11:-"1"}}

## model names and number of models
export mdlist=${mdlist:-${12:-"blndmean"}}
nmd0=`echo $mdlist | wc -w`
nmdcyc=`expr $nmd0 \* $ncyc `

## observation data (only one observation per run)
export obsv=${obsv:-${13:-"gcip"}}
obsv1=`echo $obsv |tr "[a-z]" "[A-Z]" `

# to speed up, use Fortran to parse the data, instead of 'grep' to a file
# provide data source file for Fortran
for model in $mdlist; do
  cdate=$sdate
  while [ $cdate -le $edate ]; do
    echo ${vsdb_data}/${model}_${obsv}_${cdate}.vsdb >> vsdbfiles.txt
    cdate=`$ndate +24 ${cdate}00 | cut -c 1-8 `  
  done
done

fcstthrds=${fcstthrds:-"0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9"}  #forecast threshold
nfcstthrds=`echo $fcstthrds | wc -w`
obsvthrds=${obsvthrds:-"0.2 0.4 0.6 0.8"}                      #observation threshold
nobsvthrds=`echo $obsvthrds | wc -w`

fhour=$FHOUR0; fhour=`printf "%02d" $fhour`
while [ $fhour -le $vlength ]; do
  fhours="$fhours $fhour" 
  fhour=` expr $fhour + $fhout ` ; fhour=`printf "%02d" $fhour`
done

#------------------------------------------------------------
# compute scores and save output in text format for Python
#------------------------------------------------------------
rm convert.f convert.x tmp.txt
yyyymm=`echo $edate | cut -c 1-6`

# delimit values by comma instead of by space, for numbers Fortran code
fcstthrds=`echo $fcstthrds | sed 's/ \{1,\}/,/g'` 
levlist=`echo $levlist | sed "s?P??g" |  sed 's/ \{1,\}/,/g' `
fhours=`echo $fhours | sed 's/ \{1,\}/,/g' | sed "s/^,//g"`
cyclist=`echo $cyclist | sed 's/ \{1,\}/,/g'`
obsvthrds=`echo $obsvthrds | sed 's/ \{1,\}/,/g'`
# delimite by comma and quoted, for strings in Fortran code
mdnames=""
#regnum=`echo $reg | sed -e "s?/.*??g" -e "s?^G??g"`
for model in $mdlist ; do
  mdnames='"'$model'",'$mdnames
done
mdnames=`echo $mdnames | sed "s/,$//g"`

if [ -s ${outname}.roc ]; then rm ${outname}.roc ;fi
rm *html

cat >convert.f <<EOF
!
! read data from vsdb database, compute anomaly correlation, mean-saured-error MSE, bias, 
! squared error of mean bias (e_m) and squared error of pattern variation (e_p),
! and variance of forecast (var_f) and variance of analysis (var_a)
! write out in binary format for graphic display
       integer, parameter :: nlev=${nlev}
       integer, parameter :: nday=${ndays}, fday=${nfcst}
       integer, parameter :: nmd=${nmd0}, ncyc=${ncyc}, ns=4
       integer, parameter :: nfthrd=${nfcstthrds}, nothrd=${nobsvthrds}
! for array dimensions
       real, parameter    :: fthrds(nfthrd)=(/ $fcstthrds /)
       integer, parameter :: plev(nlev)=(/ $levlist /)
       integer, parameter :: fhours(fday)=(/ $fhours /)
       integer, parameter :: cycles(ncyc)=(/ $cyclist /)
       real, parameter    :: othrds(nothrd)=(/ $obsvthrds /)
       character*20, parameter :: mdnames(nmd)=(/ $mdnames /)
       character*20, parameter :: obsreg=" $obsv1 $reg CFHO>", vnam=" $vnam"
       real*8             :: vsdb(ns,nfthrd,nlev,fday,nday,ncyc,nothrd,nmd), avsdb(ns)
       integer            :: num(nfthrd,nlev,fday,ncyc,nothrd,nmd)
       real*8             :: roca(nfthrd,nlev,fday,ncyc,nothrd,nmd)
       real*8             :: rocb(nfthrd,nlev,fday,ncyc,nothrd,nmd)
       real*8             :: rocac(nfthrd,nlev,fday,ncyc,nothrd,nmd)
       real*8             :: rocbd(nfthrd,nlev,fday,ncyc,nothrd,nmd)
       real*8             :: ac, bd, aa, bb
       real*4             :: fmiss(nfthrd,nlev,fday,nday,ncyc,nothrd), &
                             fmissmdl(nfthrd,nlev,fday,nday,ncyc,nothrd,nmd)
       character (1000)   :: line, string, header
       character(1)       :: substring
       integer            :: nchar, nhead, ii, nsum, istat
!      for reading header
       character*20       :: mdl, tmpstrings(9)
       integer            :: fhour, vhr,lev1
       real               :: othrd,fthrd
       data bad/-99.9/,substring/"="/
       data maskmiss /${maskmiss}/

       open(9,file="vsdbfiles.txt",form="formatted",status="old")
       open(20,file="${outname}.roc",form="formatted",status="new")

!-------------------------------------------------------------
! read data
!-------------------------------------------------------------
       ! models
       m0=0
       vsdb=bad;fmissmdl=bad

       DO
         READ(9,"(1A)",IOSTAT=istat)  line
         IF (istat > 0)  THEN
           write(*,*) "vsdbfiles.txt is not readable"
           exit
         ELSE IF (istat < 0) THEN
           exit
         ELSE

! based on data file name, determine the model and date element number

          ii=index(line, "/", back=.true.)
          string=line(ii+1:1000)
          mm=index(string,"_")
          mdl=string(1:mm-1)
          do m = 1, nmd
            if(trim(mdnames(m)) .eq. trim(mdl)) exit
          enddo

          if(m0 .eq. 0 .or. m0 .ne. m) then
            j=1 ! As day element, pre-sorted
            m0 = m
          else
            j=j+1
          endif

          open(10,file=trim(line),form="formatted",status="old", IOSTAT=istat)
          if(istat /= 0) cycle
          rewind (10)
          DO

! read data from each data file. 
! This is good. If there are duplicate data, the last one will be used.

           READ(10,"(1A)",IOSTAT=istat)  line
           IF (istat > 0)  THEN
             write(*,*) trim(line), " is not readable"
             exit
           ELSE IF (istat < 0) THEN
             exit
           ELSE
!=================================================
            if (index(line, trim(obsreg)) > 0 .and. &
                index(line, trim(vnam)//" ") > 0 ) then
!=================================================
              nchar=len_trim(line)
              nhead=index(line,substring)  !find character header length before "="
              string=line(nhead+1:nchar)
              read(string,*) (avsdb(k),k=1,ns)
!-------------------------------------------------
              if(avsdb(1).gt.0) then
!-------------------------------------------------
                ! find out dimension element number then assign the value

                string=line(5:nhead-1)
                do i = 1, 9
                  ii=index(string," ")
                  tmpstrings(i)=string(1:ii-1)
                  string=string(ii+1:nhead)
                enddo
                read(tmpstrings(2),*)fhour
                read(tmpstrings(3),"(8X,I)")vhr
                read(tmpstrings(6),"(5X,F)")othrd
                read(tmpstrings(7),*)fthrd
                read(tmpstrings(9),"(1X,I)")lev1

                do mo = 1, nothrd
                  if(othrd .eq. othrds(mo)) exit
                enddo
                vhr=vhr-fhour
                if(vhr < 0) vhr=vhr+24
                if(vhr < 0) vhr=vhr+24
                do mc=1,ncyc
                  if(vhr .eq. cycles(mc)) exit
                enddo
                do i = 1, fday
                  if(fhour .eq. fhours(i)) exit
                enddo
                do n = 1, nlev
                  if(lev1 .eq. plev(n)) exit
                enddo
                do l = 1, nfthrd
                  if(fthrd .eq. fthrds(l)) exit
                enddo

                vsdb(1:ns,l,n,i,j,mc,mo,m)=avsdb(1:ns)
                fmissmdl(l,n,i,j,mc,mo,m)=0.0
!-------------------------------------------------
              endif
!-------------------------------------------------
!=================================================
            endif
!=================================================

           ENDIF
          ENDDO
          close(10)
         END IF
       END DO

!-------------------------------------------------------------
! Process data, mean scores in ndays
!-------------------------------------------------------------
!--derive mean scores.
!-- optional, maskmiss : mask out missing cases from all models
!  to force all models to have the same sample size.

       num=0
       roca=0.0;rocb=0.0;rocac=0.0;rocbd=0.0
       fmiss=0.0

       do m=1,nmd
       do mo=1,nothrd
       do mc=1,ncyc
       do i=1,fday
       do n=1,nlev
        do l=1,nfthrd
         ! set the appropriate missing before deriving mean scores
         do j=1,nday
           if(fmissmdl(l,n,i,j,mc,mo,m).eq.bad) fmiss(l,n,i,j,mc,mo)=bad
         enddo
        enddo
       enddo
       enddo
       enddo
       enddo
       enddo

       do 200 m=1,nmd
       do 200 mo=1,nothrd
       do 200 mc=1,ncyc
       do 200 i=1,fday
       do 200 n=1,nlev

       do l=1,nfthrd
         do j=1,nday
          if(fmissmdl(l,n,i,j,mc,mo,m) .eq.0.0) then

           if(maskmiss .gt. 0) then
             if(fmiss(l,n,i,j,mc,mo).ne.bad) then
              num(l,n,i,mc,mo,m)=num(l,n,i,mc,mo,m)+1
              rocb(l,n,i,mc,mo,m)=rocb(l,n,i,mc,mo,m)+vsdb(1,l,n,i,j,mc,mo,m)*vsdb(2,l,n,i,j,mc,mo,m)
              roca(l,n,i,mc,mo,m)=roca(l,n,i,mc,mo,m)+vsdb(1,l,n,i,j,mc,mo,m)*vsdb(3,l,n,i,j,mc,mo,m)
              rocac(l,n,i,mc,mo,m)=rocac(l,n,i,mc,mo,m)+vsdb(1,l,n,i,j,mc,mo,m)*vsdb(4,l,n,i,j,mc,mo,m)
              rocbd(l,n,i,mc,mo,m)=rocbd(l,n,i,mc,mo,m)+vsdb(1,l,n,i,j,mc,mo,m)*(1-vsdb(4,l,n,i,j,mc,mo,m))
             endif
           else
              num(l,n,i,mc,mo,m)=num(l,n,i,mc,mo,m)+1 
              rocb(l,n,i,mc,mo,m)=rocb(l,n,i,mc,mo,m)+vsdb(1,l,n,i,j,mc,mo,m)*vsdb(2,l,n,i,j,mc,mo,m)
              roca(l,n,i,mc,mo,m)=roca(l,n,i,mc,mo,m)+vsdb(1,l,n,i,j,mc,mo,m)*vsdb(3,l,n,i,j,mc,mo,m)
              rocac(l,n,i,mc,mo,m)=rocac(l,n,i,mc,mo,m)+vsdb(1,l,n,i,j,mc,mo,m)*vsdb(4,l,n,i,j,mc,mo,m)
              rocbd(l,n,i,mc,mo,m)=rocbd(l,n,i,mc,mo,m)+vsdb(1,l,n,i,j,mc,mo,m)*(1-vsdb(4,l,n,i,j,mc,mo,m))
           endif ! maskmiss
          endif  ! fmissmdl
         enddo ! nday

         if(num(l,n,i,mc,mo,m).gt.0) then
!          roca(l,n,i,mc,mo,m)=roca(l,n,i,mc,mo,m)/num(l,n,i,mc,mo,m)
!          rocb(l,n,i,mc,mo,m)=rocb(l,n,i,mc,mo,m)/num(l,n,i,mc,mo,m)
!          rocac(l,n,i,mc,mo,m)=rocac(l,n,i,mc,mo,m)/num(l,n,i,mc,mo,m)
!          rocbd(l,n,i,mc,mo,m)=rocbd(l,n,i,mc,mo,m)/num(l,n,i,mc,mo,m)
         else
          roca(l,n,i,mc,mo,m)=bad
          rocb(l,n,i,mc,mo,m)=bad
          rocac(l,n,i,mc,mo,m)=bad
          rocbd(l,n,i,mc,mo,m)=bad
         endif

        enddo ! nfthrd

200    continue


!mean on ncyc and nothrd
!write out h/f rate in text and roca/b/c/d for html and

      do i=1,fday
      do n=1,nlev
        write(20, "(A,I2.2,A,I5,A, I3)") "fhour: ",fhours(i),&
            "  pressure: ", plev(n), "  nmodels: ",nmd
        do m=1,nmd
         write(20, *) mdnames(m), nfthrd
         do l=1,nfthrd
          aa=0.0; bb=0.0; ac=0.0; bd=0.0; nsum=0
          do mo=1,nothrd
          do mc=1,ncyc
           ! one of a/b/c/d is valid, all others are valid
           if (roca(l,n,i,mc,mo,m).ne.bad) then
             aa=aa+roca(l,n,i,mc,mo,m)
             bb=bb+rocb(l,n,i,mc,mo,m)
             ac=ac+rocac(l,n,i,mc,mo,m)
             bd=bd+rocbd(l,n,i,mc,mo,m)
             nsum=nsum+1
           endif
          enddo
          enddo
          if(nsum .gt. 0) then
           aa=nint(aa/nsum);bb=nint(bb/nsum)
           ac=nint(ac/nsum);bd=nint(bd/nsum)
           if(ac .eq. 0.0 .or. bd .eq. 0.0) then
             write(20,"(F6.2,4I10,A)") fthrds(l),int(aa),int(bb),int(ac-aa),int(bd-bb), "  0.0000  0.0000 0.0000"
           else
             write(20,"(F6.2,4I10,2F8.4,F12.2)") fthrds(l),int(aa),int(bb),int(ac-aa),int(bd-bb),aa/ac, bb/bd, (aa+bb)/ac
           endif
          else
           write(20, *) "na na na na na 0.0 0.0"
          endif
         enddo
        enddo
      enddo
      enddo

       close (9)
       close (10)
       close (20)
      end
EOF

$FC $FFLAG -o convert.x convert.f
./convert.x
if [ $? -ne 0 ]; then
  echo "convert.x exec error, exit "
  exit 8
fi

#------------------------------------------------------------
# use python to generate ROC plots and html files
#------------------------------------------------------------
$PYTHON $srcgrads/vsdbroc.py $outname.roc $vnam1 $reg1 $obsv
$PYTHON $srcgrads/vsdbbias.py $outname.roc $vnam1 $reg1 $obsv

exit
