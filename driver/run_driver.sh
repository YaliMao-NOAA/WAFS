#!/bin/sh

job=$1
# job be one of GCIP, GRIB2, GRIB2_0P25, BLENDING, BLENDING_0P25
if [ $# -lt 1 ] ; then
    echo "Must specifiy a job to run: GCIP, GRIB2, GRIB2_0P25, BLENDING, BLENDING_0P25"
    exit
fi

source ~/.bashrc

set -x

driver="run_JGFS_WAFS_${job}.$MACHINE"

PDY=20220503
HOMEgfs=/lfs/h2/emc/vpppg/noscrub/Yali.Mao/git/fork.implement2023
#FHOURS=18
EHOUR=18
cyc=06
ICAO2023=yes
COMPATH=/lfs/h2/emc/vpppg/noscrub/Yali.Mao/wafs2023input/com/gfs
#COMPATH=/lfs/h1/ops/prod/com/gfs
FHOUT_GFS=1

sed -e "s|PDY=.*|PDY=$PDY|" -e "s|HOMEgfs=.*|HOMEgfs=$HOMEgfs|" \
    $HOMEgfs/driver/$driver > $TMP/$driver
if [[ ! -z $FHOURS ]] ; then
    sed -e "s|FHOURS=.*|FHOURS=$FHOURS|" -i $TMP/$driver
fi
if [[ ! -z $EHOUR ]] ; then
    sed -e "s|EHOUR=.*|EHOUR=$EHOUR|" -i $TMP/$driver
fi
if [[ ! -z $cyc ]] ; then
    sed -e "s|cyc=.*|cyc=$cyc|" -i $TMP/$driver
fi
if [[ ! -z $ICAO2023 ]] ; then
    sed -e "s|ICAO2023=.*|ICAO2023=$ICAO2023|" -i $TMP/$driver
fi
if [[ ! -z $FHOUT_GFS ]] ; then
    sed -e "s|FHOUT_GFS=.*|FHOUT_GFS=$FHOUT_GFS|" -i $TMP/$driver
fi
if [[ ! -z $COMPATH ]] ; then
    sed -e "s|COMPATH=.*|COMPATH=$COMPATH|" -i $TMP/$driver
fi

qsub < $TMP/$driver
