#!/bin/sh

job=$1
# job be one of GCIP, GRIB2, GRIB2_0P25, BLENDING, BLENDING_0P25, GRIB
if [ $# -lt 1 ] ; then
    echo "Must specifiy a job to run: GCIP, GRIB2, GRIB2_0P25, BLENDING, BLENDING_0P25, GRIB"
    exit
fi

source ~/.bashrc
mkdir -p /lfs/h2/emc/ptmp/yali.mao/working_wafs

set -x

driver="run_JGFS_WAFS_${job}.$MACHINE"
if [ $job = GRIB ] ; then
    driver="run_JGFS_WAFS.$MACHINE"
fi

PDY=20230308
HOMEgfs=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/fork.implement2023
#FHOURS=48
SHOUR=
EHOUR=
cyc=00
ICAO2023=no
FHOUT_GFS=
COMIN=/lfs/h2/emc/vpppg/noscrub/yali.mao/4uk_blending/gfs.$PDY/$cyc/atmos
#for GCIP
#COMIN=/lfs/h1/ops/prod/com/gfs
#For blending
if [[ $job =~ 'BLENDING' ]] ; then
    if [ $job = 'BLENDING' ] ; then
	if [ "$ICAO2023" = 'yes' ] ; then
	    COMIN=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs_dwn2023_1p25/com/gfs
	else
	    COMIN=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs_dwn2022_1p25/com/gfs
	fi
#	DCOMROOT=/lfs/h2/emc/vpppg/noscrub/yali.mao/dcom_2022
    else # BLENDING_0P25
	if [ "$ICAO2023" = 'yes' ] ; then
	    COMIN=/lfs/h2/emc/ptmp/yali.mao/wafs_dwn/com/gfs/v16.3/gfs.$PDY/$cyc/atmos
	    DCOMROOT=/lfs/h2/emc/vpppg/noscrub/yali.mao/4uk_blending
	else
	    COMIN=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs_dwn2022/com/gfs
	    COMIN=/lfs/h1/ops/prod/com/gfs/v16.3/gfs.$PDY/$cyc/atmos
	    DCOMROOT=/lfs/h2/emc/vpppg/noscrub/yali.mao/4uk_blending
	fi
    fi
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
if [[ ! -z $COMIN ]] ; then
    sed -e "s|COMIN=.*|COMIN=$COMIN|" -i $TMP/$driver
    if [[ $job = 'GCIP' ]] ; then
	sed -e "s|COMIN=.*|COMIN=$COMIN:/lfs/h1/ops/prod/com/radarl2|" -i $TMP/$driver
    fi
fi
if [[ ! -z $DCOMROOT ]] ; then
    sed -e "s|DCOMROOT=.*|DCOMROOT=$DCOMROOT|" -i $TMP/$driver
fi
qsub < $TMP/$driver

if [[ $job = 'GRIB' ]] ; then
    for fcsthrs in 00 03 06 09 12 15 18 21 24 27 30 33 36 42 48 54 60 66 72 78 84 90 96 102 108 114 120 ; do
	sed -e "s|fcsthrs=.*|fcsthrs=$fcsthrs|" -i $TMP/$driver
	qsub < $TMP/$driver
    done
fi
