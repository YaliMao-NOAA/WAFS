#!/bin/ksh
##############################################################################
# Script Name: verf_g2g_wafs.sh
# Purpose:  This script Prepare OBS and FCST input files and run grid2grid
#           to generate VSDB files
#
# History:  2011-11-18  Julia Zhu modified from Binbin Zhou's version to 
#                       prepare for production implementation
#           2014-11-15 B. Zhou upgraded to grib2
#           2015-03-15 Y. Mao modified for WAFS verification
# Usage:  verf_g2g_wafs.sh vday model obsv
###############################################################################
set -x

PAST1=$1
model=$2
obsv=$3

OBSVDIR=${OBSVDIR:-/com/verf/prod/wafs}
FCSTDIR=${FCSTDIR:-/com/verf/prod/wafs}

#(1) Set parameters
# Observation and model files are copied and stored   

#vgrid was  set by exverf_g2g_wafs.sh.ecf
if [[ $obsv = 'cip' || $obsv = 'gcip' || $obsv = 'gcipconus' ]] ; then
   export fcstdir=$FCSTDIR
   export fhead=$model
   export fgrbtype=grd$vgrid.f
   export ftm=.grib2
   export mdl=`echo $model | tr '[a-z]' '[A-Z]'`

   
   export obsvdir=$OBSVDIR
   export ohead=$obsv
   export ogrbtype=grd$vgrid
   export otm=
   export otail=.f00.grib2
   export obsvdata=`echo $obsv | tr '[a-z]' '[A-Z]'`

   HHs="00 03 06 09 12 15 18 21"
   CNTLtemplate=verf_g2g_wafs.${obsv}

  #(2) Prepare OBS and FCST input files and run grid2grid to generate VSDB files
  for HH in $HHs ; do
     cp $PARMverf_g2g/$CNTLtemplate .
     sed -e "s/MODNAM/${mdl}_$vgrid/g" -e "s/VDATE/${PAST1}${HH}/g" \
         -e "s/OBSTYPE/$obsvdata/g" $CNTLtemplate >user.ctl

     $USHverf_g2g/verf_g2g_prepg2g.sh < user.ctl >output.prepg2g.${obsv}.${model}

     $USHverf_g2g/verf_g2g_fitsg2g.sh<temp

     echo "verf_g2g_ref.sh done for " ${PAST1}${HH} $vgrid
  done

fi

# Combine the vsdb files for each model
if [ ! -d $COMVSDB/wafs ] ; then
  mkdir -p $COMVSDB/wafs
fi
rm -rf ${model}_${PAST1}.vsdb
MODEL=`echo $model | tr '[a-z]' '[A-Z]'`
for HH in $HHs ; do
  cat ${MODEL}_${vgrid}_${PAST1}${HH}.vsdb >> $COMVSDB/wafs/${model}_${obsv}_${PAST1}.vsdb
done

rm -rf *${MODEL}*.vsdb




