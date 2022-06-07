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

PDY=20220526
HOMEgfs=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/fork.implement2023
#FHOURS=48
SHOUR=
EHOUR=
cyc=06
ICAO2023=yes
FHOUT_GFS=
COMPATH=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs2023input/com/gfs
#For blending
if [[ $job =~ 'BLENDING' ]] ; then
    COMPATH=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs_dwn2023/com/gfs
    DCOMROOT=/lfs/h2/emc/vpppg/noscrub/yali.mao/dcom
fi

sed -e "s|PDY=.*|PDY=$PDY|" -e "s|HOMEgfs=.*|HOMEgfs=$HOMEgfs|" \
    $HOMEgfs/driver/$driver > $TMP/$driver
if [[ ! -z $FHOURS ]] ; then
    sed -e "s|FHOURS=.*|FHOURS=$FHOURS|" -i $TMP/$driver
fi
if [[ ! -z $SHOUR ]] ; then
    sed -e "s|SHOUR=.*|SHOUR=$SHOUR|" -i $TMP/$driver
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
if [[ ! -z $DCOMROOT ]] ; then
    sed -e "s|DCOMROOT=.*|DCOMROOT=$DCOMROOT|" -i $TMP/$driver
fi

qsub < $TMP/$driver
