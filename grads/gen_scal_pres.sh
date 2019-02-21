#!/bin/sh
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
#-------------------------------------------------------


export exedir=${exedir:-/ptmpp1/$LOGNAME/vsdb_stats}
if [ ! -s $exedir ]; then mkdir -p $exedir; fi
cd $exedir

export vsdb_data=${vsdb_data:-/climate/save/wx24fy/VRFY/vsdb_data06}
export NWPROD=${NWPROD:-/nwprod}
export FC=${FC:-ifort}
export FFLAG=${FFLAG:-" "}

export FHOUR0=${FHOUR0:-06}
       fhours=""

## verification type: pres
export vtype=${1:-pres}

## verification variable parameters: e.g. HGT G2/NHX 
export vnam=${2:-T}
export reg=${3:-G45}
export levlist=${4:-"P850 P700 P600 P500 P400 P300 P250 P200 P150 P100"}
       nlev=`echo $levlist |wc -w`

## verification ending date and number of days back 
export edate=${5:-20150425}
export ndays=${6:-31}
       nhours=`expr $ndays \* 24 - 24`
       tmp=`$NDATE -$nhours ${edate}00 `
       sdate=`echo $tmp | cut -c 1-8`

## forecast cycles to be vefified: 00Z, 06Z, 12Z, 18Z, all
export cyclist=${7:-"00"}
       ncyc=`echo $cyclist | wc -w`

## forecast length in every 3/6 hours from f06, replacing origianl days
export vlength=${8:-36}

## forecast output frequency requried for verification
export fhout=${9:-6}
# WAFS: no f03 forecast, starting from f06
       nfcst=`expr $(( vlength - 06 )) \/ $fhout + 1`

## create output name (first remove / from parameter names)
vnam1=`echo $vnam | sed "s?/??g" |sed "s?_WV1?WV?g"`  
reg1=`echo $reg | sed "s?/??g"`
outname1=${vnam1}_${reg1}_${sdate}${edate}
outname=${10:-$outname1}

## remove missing data from all models to unify sample size, 0-->NO, 1-->Yes
maskmiss=${maskmiss:-${11:-"1"}}

## model names and number of models
export mdlist=${mdlist:-${12:-"twind"}}
nmd0=`echo $mdlist | wc -w`
nmdcyc=`expr $nmd0 \* $ncyc `

## observation data (only one observation per run)
export obsv=${obsv:-${13:-"gfs"}}
obsv1=`echo $obsv |tr "[a-z]" "[A-Z]" `

set -A mdname $mdlist
set -A cycname $cyclist
if [ -s modelname.txt ]; then rm modelname.txt ;fi
>modelname.txt
n=0
while [ $n -lt $nmd0 ]; do
 m=0
 while [ $m -lt $ncyc ]; do
  echo "${mdname[n]}${cycname[m]}" >>modelname.txt
  m=`expr $m + 1 `
 done
 n=`expr $n + 1 `
done

if [ -s ${outname}.txt ]; then rm ${outname}.txt ;fi
if [ -s ${outname}.bin ]; then rm ${outname}.bin ;fi
if [ -s ${outname}.ctl ]; then rm ${outname}.ctl ;fi

# to speed up, use Fortran to parse the data, instead of 'grep' to a file
# provide data source file for Fortran
for model in $mdlist; do
  cdate=$sdate
  while [ $cdate -le $edate ]; do
    echo ${vsdb_data}/${model}_${obsv}_${cdate}.vsdb >> vsdbfiles.txt
    cdate=`$NDATE +24 ${cdate}00 | cut -c 1-8 `  
  done
done

fhour=$FHOUR0;
while [ $fhour -le $vlength ]; do
  fhour=`printf "%02d" $fhour`
  fhours="$fhours $fhour" 
  fhour=` expr $fhour + $fhout `
done

#------------------------------------------------------------
# compute scores and save output in binary format for GrADS 
#------------------------------------------------------------
rm convert.f convert.x tmp.txt
yyyymm=`echo $edate | cut -c 1-6`

# delimit values by comma instead of by space, for numbers Fortran code
levlists=`echo $levlist | sed "s?P??g" |  sed 's/ \{1,\}/,/g' `
fhours=`echo $fhours | sed 's/ \{1,\}/,/g' | sed "s/^,//g"`
cyclist=`echo $cyclist | sed 's/ \{1,\}/,/g'`
# delimite by comma and quoted, for strings in Fortran code
mdnames=""
#regnum=`echo $reg | sed -e "s?/.*??g" -e "s?^G??g"`
for model in $mdlist ; do
  mdnames='"'$model'",'$mdnames
done
mdnames=`echo $mdnames | sed "s/,$//g"`

#------------------------------------------------------------
# compute scores and save output in binary format for GrADS 
#------------------------------------------------------------
rm convert.f convert.x tmp.txt
yyyymm=`echo $edate | cut -c 1-6`

cat >convert.f <<EOF
!
! read data from vsdb database, compute anomaly correlation, mean-saured-error MSE, bias, 
! squared error of mean bias (e_m) and squared error of pattern variation (e_p),
! and variance of forecast (var_f) and variance of analysis (var_a)
! write out in binary format for graphic display
       integer, parameter :: nlev=${nlev}
       integer, parameter :: nday=${ndays}, fday=${nfcst}, bin=nday
       integer, parameter :: nmd=${nmdcyc}, ns=5,nmd0=${nmd0}, ncyc=${ncyc}
       integer, parameter :: bin0=20
       integer, parameter :: plev(nlev)=(/ $levlists /)
       integer, parameter :: fhours(fday)=(/ $fhours /)
       integer, parameter :: cycles(ncyc)=(/ $cyclist /)
       character*20, parameter :: mdnames0(nmd0)=(/ $mdnames /)
       character*20, parameter :: obsreg=" $obsv1 $reg SL1L2", vnam=" $vnam"
       character*20       :: mdname(nmd) ! model name // cycle
       real*4             :: points
       real*8             :: vsdb(ns)
       real*4             :: cor(nlev,fday,nday,nmd), rms(nlev,fday,nday,nmd)
       real*4             :: mse(nlev,fday,nday,nmd), bias(nlev,fday,nday,nmd)   
       real*4             :: e_m(nlev,fday,nday,nmd), e_p(nlev,fday,nday,nmd),msess(nlev,fday,nday,nmd)
       real*4             :: var_f(nlev,fday,nday,nmd), var_a(nlev,fday,nday,nmd), rvar(nlev,fday,nday,nmd)    
       real*4             :: num(nlev,fday,nmd), numbin(nlev,fday,nmd), mcor(nlev,fday,nmd)
       real*4             :: mrms(nlev,fday,nmd), mmse(nlev,fday,nmd), mbias(nlev,fday,nmd)   
       real*4             :: me_m(nlev,fday,nmd),me_p(nlev,fday,nmd),mvar_f(nlev,fday,nmd)
       real*4             :: mvar_a(nlev,fday,nmd),mrvar(nlev,fday,nmd),mmsess(nlev,fday,nmd)
       real*4             :: bincor(nlev,fday,bin,nmd), binbnd(bin+1)
       real*4             :: bincor0(nlev,fday,bin0), binbnd0(bin0+1)
       real*4             :: fmiss(nlev,fday,nday), fmissmdl(nlev,fday,nday,nmd)
       character (1000)   :: line, string, header
       character(1)       :: substring
       integer            :: nchar, nhead, ii, nsum, istat
!      for reading header
       character*20       :: mdl, tmpstrings(9)
       integer            :: fhour, vhr,lev1
       data bad/-99.9/,substring/"="/
       data maskmiss /${maskmiss}/

       open(8,file="modelname.txt",form="formatted",status="old")
       open(9,file="vsdbfiles.txt",form="formatted",status="old")
       open(20,file="${outname}.bin",form="unformatted",status="new")

       do m=1,nmd
        read(8,'(a)') mdname(m)
       enddo

! create bounds of bins for frequency distribution of anomaly correlations (0,1)
       delcor=1.0/bin
       do i=1,bin+1
        binbnd(i)=(i-1)*delcor
       enddo
! for ndays >bin0 cases, use maximum bin0
       delcor0=1.0/bin0
       do i=1,bin0+1
        binbnd0(i)=(i-1)*delcor0
       enddo


!-------------------------------------------------------------
! read data
!-------------------------------------------------------------
       ! models
       m0=0

       cor=bad; rms=bad; mse=bad; bias=bad;e_m=bad;e_p=bad
       msess=bad;var_f=bad;var_a=bad;rvar=bad;fmissmdl=bad

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
          do m = 1, nmd0
            if(trim(mdnames0(m)) .eq. trim(mdl)) exit
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
              read(string,*) points, (vsdb(k),k=1,ns)
!-------------------------------------------------
              if(points.gt.0) then
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
                read(tmpstrings(8),"(1X,I)")lev1

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

                m=(m0-1)*nmd0+mc

                fmissmdl(n,i,j,m)=0.0

                var_f(n,i,j,m)=max(0.0d0,vsdb(4)-vsdb(1)**2)
                var_a(n,i,j,m)=max(0.0d0,vsdb(5)-vsdb(2)**2)
                cor(n,i,j,m)=(vsdb(3)-vsdb(1)*vsdb(2))/  &
                        sqrt(var_f(n,i,j,m)*var_a(n,i,j,m))
                mse(n,i,j,m)=max(0.0d0,(vsdb(4)+vsdb(5)-2*vsdb(3)))
                rms(n,i,j,m)=sqrt(mse(n,i,j,m))
                bias(n,i,j,m)=vsdb(1)-vsdb(2)
                e_m(n,i,j,m)=bias(n,i,j,m)*bias(n,i,j,m)
                e_p(n,i,j,m)=max(0.0,mse(n,i,j,m)-e_m(n,i,j,m))
                if(var_a(n,i,j,m).ne.0) then 
                  rvar(n,i,j,m)=var_f(n,i,j,m)/var_a(n,i,j,m)
                  msess(n,i,j,m)=1.0-mse(n,i,j,m)/var_a(n,i,j,m)
                else
                  rvar(n,i,j,m)=bad
                  msess(n,i,j,m)=bad
                endif

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

       bincor=0.0;numbin=0
       num=0; mcor=0; mrms=0; mmse=0; mbias=0
       me_m=0; me_p=0; mvar_f=0; mvar_a=0; mrvar=0; mmsess=0
       fmiss=0.0

       do m=1,nmd
       do i=1,fday
       do n=1,nlev
         ! set the appropriate missing before deriving mean scores
         do j=1,nday
           if(fmissmdl(n,i,j,m) .eq.bad) fmiss(n,i,j)=bad
         enddo
       enddo
       enddo
       enddo

       do 200 m=1,nmd
       bincor0=0.0
       do 100 i=1,fday
       do 100 n=1,nlev
         do j=1,nday
          if(fmissmdl(n,i,j,m) .eq.0.0) then

           ! set bincor
           numbin(n,i,m)=numbin(n,i,m)+1
           do k=1,bin
             if(cor(n,i,j,m).gt.binbnd(k).and.cor(n,i,j,m).le.binbnd(k+1)) bincor(n,i,k,m)=bincor(n,i,k,m)+1.0
           enddo
           do k=1,bin0
             if(cor(n,i,j,m).gt.binbnd0(k).and.cor(n,i,j,m).le.binbnd0(k+1)) bincor0(n,i,k)=bincor0(n,i,k)+1.0 
           enddo

           if(maskmiss .gt. 0) then
             if(fmiss(n,i,j).ne.bad) then
               num(n,i,m)=num(n,i,m)+1
               mcor(n,i,m)=mcor(n,i,m)+cor(n,i,j,m)
               mrms(n,i,m)=mrms(n,i,m)+rms(n,i,j,m)
               mmse(n,i,m)=mmse(n,i,m)+mse(n,i,j,m)
               mbias(n,i,m)=mbias(n,i,m)+bias(n,i,j,m)
               me_m(n,i,m)=me_m(n,i,m)+e_m(n,i,j,m)
               me_p(n,i,m)=me_p(n,i,m)+e_p(n,i,j,m)
               mvar_f(n,i,m)=mvar_f(n,i,m)+var_f(n,i,j,m)
               mvar_a(n,i,m)=mvar_a(n,i,m)+var_a(n,i,j,m)
             else ! set the variables to bad even they were valid
               cor(n,i,j,m)=bad
               rms(n,i,j,m)=bad
               mse(n,i,j,m)=bad
               bias(n,i,j,m)=bad
               e_m(n,i,j,m)=bad
               e_p(n,i,j,m)=bad
               msess(n,i,j,m)=bad
               var_f(n,i,j,m)=bad
               var_a(n,i,j,m)=bad
               rvar(n,i,j,m)=bad
             endif
           else
             num(n,i,m)=num(n,i,m)+1
             mcor(n,i,m)=mcor(n,i,m)+cor(n,i,j,m)
             mrms(n,i,m)=mrms(n,i,m)+rms(n,i,j,m)
             mmse(n,i,m)=mmse(n,i,m)+mse(n,i,j,m)
             mbias(n,i,m)=mbias(n,i,m)+bias(n,i,j,m)
             me_m(n,i,m)=me_m(n,i,m)+e_m(n,i,j,m)
             me_p(n,i,m)=me_p(n,i,m)+e_p(n,i,j,m)
             mvar_f(n,i,m)=mvar_f(n,i,m)+var_f(n,i,j,m)
             mvar_a(n,i,m)=mvar_a(n,i,m)+var_a(n,i,j,m)
           endif ! maskmiss

          endif  ! fmissmdl

         enddo ! nday

         ! set bincor
         if(numbin(n,i,m).gt.0) then
          bincor(n,i,:,m)=bincor(n,i,:,m)/numbin(n,i,m)
          bincor0(n,i,:)=bincor0(n,i,:)/numbin(n,i,m)
         else
          bincor(n,i,:,m)=bad
          bincor0(n,i,:)=bad
         endif

         if(num(n,i,m).gt.0) then
          mcor(n,i,m)=mcor(n,i,m)/num(n,i,m)
          mrms(n,i,m)=mrms(n,i,m)/num(n,i,m)
          mmse(n,i,m)=mmse(n,i,m)/num(n,i,m)
          mbias(n,i,m)=mbias(n,i,m)/num(n,i,m)
          me_m(n,i,m)=me_m(n,i,m)/num(n,i,m)
          me_p(n,i,m)=me_p(n,i,m)/num(n,i,m)
          mvar_f(n,i,m)=mvar_f(n,i,m)/num(n,i,m)
          mvar_a(n,i,m)=mvar_a(n,i,m)/num(n,i,m)
          mrvar(n,i,m)=mvar_f(n,i,m)/mvar_a(n,i,m)
          mmsess(n,i,m)=1.0-mmse(n,i,m)/mvar_a(n,i,m)
        else
          mcor(n,i,m)=bad
          mrms(n,i,m)=bad
          mmse(n,i,m)=bad
          mbias(n,i,m)=bad
          me_m(n,i,m)=bad
          me_p(n,i,m)=bad
          mvar_f(n,i,m)=bad
          mvar_a(n,i,m)=bad
          mrvar(n,i,m)=bad
          mmsess(n,i,m)=bad
          num(n,i,m)=bad
        endif

100    continue

! use maximum 20 bins for frequency
       if(nday.gt.bin0) then
        do n=1,nlev
        do i=1,fday
         do j=1,bin0
          bincor(n,i,j,m)=bincor0(n,i,j)
         enddo
         do j=bin0+1,nday
           bincor(n,i,j,m)=0
         enddo
        enddo
        enddo
       endif

200    continue

!
!write out correlation, bias, RMSE, ratio of standard deviaiton
!
       do j=1,nday
         do n=1,nlev
           write(20) ((cor(n,i,j,m),m=1,nmd),i=1,fday)
         enddo
         do n=1,nlev
           write(20) ((rms(n,i,j,m),m=1,nmd),i=1,fday)
         enddo
         do n=1,nlev
           write(20) ((bias(n,i,j,m),m=1,nmd),i=1,fday)
         enddo
         do n=1,nlev
           do i=1,fday
           do m=1,nmd 
            if (e_m(n,i,j,m).ne.bad) e_m(n,i,j,m)=sqrt(e_m(n,i,j,m))
           enddo
           enddo
           write(20) ((e_m(n,i,j,m),m=1,nmd),i=1,fday)
         enddo
         do n=1,nlev
           do i=1,fday
           do m=1,nmd 
            if (e_p(n,i,j,m).ne.bad) e_p(n,i,j,m)=sqrt(e_p(n,i,j,m))
           enddo
           enddo
           write(20) ((e_p(n,i,j,m),m=1,nmd),i=1,fday)
         enddo
         do n=1,nlev
           do i=1,fday
           do m=1,nmd 
            if (rvar(n,i,j,m).ne.bad) rvar(n,i,j,m)=sqrt(rvar(n,i,j,m))
           enddo
           enddo
           write(20) ((rvar(n,i,j,m),m=1,nmd),i=1,fday)
         enddo
         do n=1,nlev
           write(20) ((msess(n,i,j,m),m=1,nmd),i=1,fday)
         enddo
         do n=1,nlev
           write(20) ((bincor(n,i,j,m),m=1,nmd),i=1,fday)
         enddo
       enddo

! save mean scores as the nday+1 record in time
       do n=1,nlev
         write(20) ((mcor(n,i,m),m=1,nmd),i=1,fday)
       enddo
       do n=1,nlev
         write(20) ((mrms(n,i,m),m=1,nmd),i=1,fday)
       enddo
       do n=1,nlev
         write(20) ((mbias(n,i,m),m=1,nmd),i=1,fday)  
       enddo
       do n=1,nlev
         do i=1,fday
         do m=1,nmd
          if (me_m(n,i,m).ne.bad) me_m(n,i,m)=sqrt(me_m(n,i,m))  
         enddo
         enddo
         write(20) ((me_m(n,i,m),m=1,nmd),i=1,fday)  
       enddo
       do n=1,nlev
         do i=1,fday
         do m=1,nmd
          if (me_p(n,i,m).ne.bad) me_p(n,i,m)=sqrt(me_p(n,i,m))  
         enddo
         enddo
         write(20) ((me_p(n,i,m),m=1,nmd),i=1,fday)  
       enddo
       do n=1,nlev
         do i=1,fday
         do m=1,nmd
          if (mrvar(n,i,m).ne.bad) mrvar(n,i,m)=sqrt(mrvar(n,i,m))  
         enddo
         enddo
         write(20) ((mrvar(n,i,m),m=1,nmd),i=1,fday)  
       enddo
       do n=1,nlev
         write(20) ((mmsess(n,i,m),m=1,nmd),i=1,fday)  
       enddo
       do n=1,nlev
         write(20) ((num(n,i,m),m=1,nmd),i=1,fday)    !note: num of records instead of bincor
       enddo

       do m=1,nmd
        do n=1,nlev
          write(13,123) $yyyymm, plev(n), trim(mdname(m)),"_cor", (mcor(n,i,m),i=1,fday) 
        enddo
        do n=1,nlev
          write(14,123) $yyyymm, plev(n), trim(mdname(m)),"_rms", (mrms(n,i,m),i=1,fday)  
        enddo
        do n=1,nlev
          write(15,123) $yyyymm, plev(n), trim(mdname(m)),"_bia", (mbias(n,i,m),i=1,fday) 
        enddo
       enddo
 123   format(i10,i10,"MB ", 2x,A,A, ${nfcst}f10.3)

       close (9)
       close (10)
       close (11)
       close (20)
      end
EOF

$FC $FFLAG -o convert.x convert.f
./convert.x
if [ $? -ne 0 ]; then
  echo "convert.x exec error, exit "
  exit 8
fi

meantxt=${vnam1}_${reg1}_${yyyymm}
mv fort.13 meancor_${meantxt}.txt
mv fort.14 meanrms_${meantxt}.txt
mv fort.15 meanbias_${meantxt}.txt


#------------------------------------------------------------
# create GrADS control file
#------------------------------------------------------------
ndaysp1=`expr $ndays + 1 `
YYYY=`echo $sdate | cut -c 1-4`
MM=`echo $sdate | cut -c 5-6`
DD=`echo $sdate | cut -c 7-8`

set -A MONCHAR Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
MMM1=`expr $MM - 1 `
MON=${MONCHAR[$MMM1]}

cat >${outname}.ctl <<EOF1
dset ^${outname}.bin  
undef -99.9   
options big_endian sequential 
title scores
xdef    $nmdcyc linear 1  1
ydef    $nfcst linear 06 $fhout
zdef    $nlev levels  `echo $levlist | sed "s?P??g"`
tdef    $ndaysp1 Linear $DD$MON$YYYY 1dy
vars    8
pcor    $nlev 0 correlation
rms     $nlev 0  root-mean squared error (RMSE)
bias    $nlev 0  mean bias   
emd     $nlev 0  RMSE by mean difference
epv     $nlev 0  RMSE by pattern variation
rsd     $nlev 0  ratio of standard deviation between forecast and analysis
msess   $nlev 0  murphy's mean-squared-error skill score                    
bincor  $nlev 0  frequency distribution of AC
endvars

EOF1

exit
