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
  conus) nesdisdir=$DCOM/$vday/wgrdbul/smoke_west
         jmax=1473
         imax=1025
         vgrid="227" 
##         ftype="G13" ;;
         ftype="GW" ;;
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
export OUTDIR=$COM_OUT/smoke.$vday

# Select NESDIS SAT Algorithm
export algorithm=5

# fhead should be in consistent with file prefix opened in sorc/convert_*.f
#export fhead=aod-smoke

tbeg=${tbeg:-11}
tend=${tend:-23}

cp $nesdisdir/${ftype}.$vday*.2smoke.combaod.hmshysplitcomb2.NAM3.grd .
if [ $SENDCOM = YES ]
then
  echo "DO NOT SAVE THE ORIGINAL FILES"
  cp $nesdisdir/${ftype}.$vday*.2smoke.combaod.hmshysplitcomb2.NAM3.grd $OUTDIR/.
fi

t=$tbeg
while [ $t -le ${tend} ]
do
  if [[ ${algorithm} == '1' ]] ; then
    file=${ftype}.$vday${t}15.smoke.aod_conc.NAM3.grd
  elif [[ ${algorithm} == '4' ]] ; then
    file=${ftype}.$vday${t}.2smoke.combaod.hmshysplitcomb.NAM3.grd
  elif [[ ${algorithm} == '5' ]] ; then
    file=${ftype}.$vday${t}.2smoke.combaod.hmshysplitcomb2.NAM3.grd
  else
    file=${ftype}.$vday${t}15.$algorithm"smoke.aod_conc.NAM3.grd"
  fi

  if [[ -e ${file} ]]; then
    if [[ -e ${ftype}.t${t}z.f00 ]]; then
      rm -f ${ftype}.t${t}z.f00
    fi


cat >input.prd2 <<EOF
$jmax
$imax
EOF

     pgm=verf_g2g_change.nesdis.unit
    . $DATA/prep_step

#    export XLFUNIT_10="$file"
#    export XLFUNIT_50="${ftype}.t${t}z.f00"

    ln -sf $file fort.10
    ln -sf ${ftype}.t${t}z.f00 fort.50

    $EXECverf_g2g/verf_g2g_change.nesdis.unit <input.prd2 >change.nesdis.out 2>&1
    export err=$?; err_chk
    $COPYGB -g${vgrid} -i2,1 -x ${ftype}.t${t}z.f00 ${ftype}-grib${vgrid}.t${t}z.f00

    if [ $SENDCOM = YES ]; then
       cp ${ftype}*t${t}z.f00 $OUTDIR/.
    fi
  else
    echo "NESDIS SMOKE data is not available in /dcom"
    echo "Skipping..."
  fi

  t=`expr $t + 1`
done

# Get the first 3 hours of the next day's data as well for AK and HI region:
if [ $nest = ak -o $nest = hi ]
then
  tbeg1=0
  tend1=3
  

  next_day=`/nwprod/util/ush/finddate.sh $vday d+1`
  nesdisdir_p=$DCOM/$next_day/wgrdbul/smoke_west
  OUTDIR_P=$COM_OUT/smoke.${next_day}

  if [ -d $OUTDIR_P ]; then mkdir -p $OUTDIR_P; fi

  cp $nesdisdir_p/${ftype}.${next_day}*.2smoke.combaod.hmshysplitcomb2.NAM3.grd .
  if [ $SENDCOM = YES ]
  then
    echo "DO NOT SAVE THE ORIGINAL FILES"
    cp $nesdisdir_p/${ftype}.${next_day}*.2smoke.combaod.hmshysplitcomb2.NAM3.grd $OUTDIR_P/.
  fi
 
  t=$tbeg1
  while [ $t -le ${tend1} ]
  do
    if [[ ${algorithm} == '1' ]] ; then
       file=${ftype}.${next_day}${t}15.smoke.aod_conc.NAM3.grd
    elif [[ ${algorithm} == '4' ]] ; then
       file=${ftype}.${next_day}${t}.2smoke.combaod.hmshysplitcomb.NAM3.grd
    elif [[ ${algorithm} == '5' ]] ; then
       file=${ftype}.${next_day}${t}.2smoke.combaod.hmshysplitcomb2.NAM3.grd
    else
       file=${ftype}.${next_day}${t}15.$algorithm"smoke.aod_conc.NAM3.grd"
    fi

    if [[ -e ${file} ]]; then
       if [[ -e ${ftype}.t${t}z.f00 ]]; then
          rm -f ${ftype}.t${t}z.f00
       fi

       pgm=verf_g2g_change.nesdis.unit
       . $DATA/prep_step

#       export XLFUNIT_10="$file"
#       export XLFUNIT_50="${ftype}.t${t}z.f00"

       ln -sf $file fort.10
       ln -sf ${ftype}.t${t}z.f00 fort.50

       $EXECverf_g2g/verf_g2g_change.nesdis.unit >change.nesdis.out 2>&1
       export err=$?; err_chk

       $COPYGB -g${vgrid} -i2,1 -x ${ftype}.t${t}z.f00 ${ftype}-grib${vgrid}.t${t}z.f00
       if [ $SENDCOM = YES ]; then
          cp ${ftype}*t${t}z.f00 $OUTDIR_P/.
       fi
    else
       echo "NESDIS SMOKE data is not available in /dcom"
       echo "Skipping..."
    fi
    t=`expr $t + 1`
  done
fi
