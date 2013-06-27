#!/bin/ksh
#####################################################################
# This script obtains daily NESDIS SMOKE concentration data
#
# Author:  Jianping Huang 
# History: 2011-11-01 Modified by Julia Zhu for running in production
#          environment
#
# Usage:   verf_g2g_getnesdis_daily.sh NEST VDAY
#####################################################################
set -x

export nest=$1
export vday=$2

export COPYGB=${COPYGB:-/nwprod/util/exec/copygb}

export DCOM=${DCOM:-/dcom/us007003}

case $nest in
##  conus) nesdisdir=$DCOM/$vday/wgrdbul/smoke
   conus) nesdisdir=/meso/noscrub/$LOGNAME/aod-dust/conc/dust.${vday}
         ftype="MYDdust"
         otype="modis-dust"
         varvn=aod_conc.v6.3.4
         jmax=601
         imax=251
         vgrid="227";; 
  ak)    nesdisdir=$DCOM/$vday/wgrdbul/smoke_west
         jmax=825
         imax=553 
         vgrid="198"
         ftype="GW" ;;
  hi)    nesdisdir=$DCOM/$vday/wgrdbul/smoke_hawaii
         jmax=401
         imax=201
         vgrid="196"
         ftype="GWHI" ;;
esac

#------jp for testing  ---------------
#export   nesdisdir=/meso/noscrub/wx20jh/aod-smoke/conc/smoke5.$vday
#
export OUTDIR=$COM_OUT/dust.$vday

# Select NESDIS SAT Algorithm
export algorithm=5

# fhead should be in consistent with file prefix opened in sorc/convert_*.f
#export fhead=aod-smoke

tbeg=${tbeg:-11}
tend=${tend:-23}

#if [[  $vday -lt 20120629 ]]; then
 cp $nesdisdir/${ftype}.${varvn}.$vday.hr*grib .
#else
# cp $nesdisdir/${ftype}.${varvn}.P$vday.hr*grib .
#fi
if [ $SENDCOM = YES ]
then
  echo "DO NOT SAVE THE ORIGINAL FILES"
# if [[  $vday -lt 20120629 ]]; then 
  cp $nesdisdir/${ftype}.${varvn}.$vday.hr*grib $OUTDIR/.
# else
#  cp $nesdisdir/${ftype}.${varvn}.P$vday.hr*grib $OUTDIR/.
# fi
fi

t=$tbeg
while [ $t -le ${tend} ]
do
# below is for the days on or before June 28, 2012
# file=${ftype}.${varvn}.$vday.hr${t}.grib
# below is for the days on and after June 29,2012
#if [[ $vday -lt 20120629 ]]; then
 file=${ftype}.${varvn}.$vday.hr${t}.grib
#else
# file=${ftype}.${varvn}.P$vday.hr${t}.grib
#fi


cat >input.prd2 <<EOF
$jmax
$imax
EOF

   if [[ -e ${file} ]]; then
       if [[ -e ${ftype}.t${t}z.f00 ]]; then
          rm -f ${ftype}.t${t}z.f00
       fi


     pgm=verf_g2g_change.nesdis.unit
    . $DATA/prep_step

##    export XLFUNIT_10="$file"
##    export XLFUNIT_50="${ftype}.t${t}z.f00"

    ln -sf $file fort.10
    ln -sf ${ftype}.t${t}z.f00 fort.50

    $EXECverf_g2g/verf_g2g_change.nesdis.unit <input.prd2 >change.nesdis.out 2>&1
    export err=$?; err_chk
    $COPYGB -g${vgrid} -i2,1 -x ${ftype}.t${t}z.f00 ${otype}-grib${vgrid}.t${t}z.f00 

    if [ $SENDCOM = YES ]; then
       cp ${otype}-grib${vgrid}.t${t}z.f00 $OUTDIR/.
    fi
  else
    echo "NESDIS SMOKE data is not available in /dcom"
    echo "Skipping..."
  fi

  t=`expr $t + 1`
done

