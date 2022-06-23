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

PDY=20220623
HOMEgfs=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/fork.implement2023
#FHOURS=48
SHOUR=
EHOUR=
cyc=06
ICAO2023=yes
FHOUT_GFS=
COMPATH=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs2023input/com/gfs
#for GCIP
#COMPATH=/lfs/h1/ops/prod/com/gfs
#For blending
if [[ $job =~ 'BLENDING' ]] ; then
    if [ $job = 'BLENDING' ] ; then
	if [ "$ICAO2023" = 'yes' ] ; then
	    COMPATH=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs_dwn2023_1p25/com/gfs
	else
	    COMPATH=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs_dwn2022_1p25/com/gfs
	fi
	DCOMROOT=/lfs/h2/emc/vpppg/noscrub/yali.mao/dcom_2022
    else # BLENDING_0P25
	if [ "$ICAO2023" = 'yes' ] ; then
	    COMPATH=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs_dwn2023_5.3/com/gfs
	    DCOMROOT=/lfs/h2/emc/vpppg/noscrub/yali.mao/dcom_2023
	else
	    COMPATH=/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs_dwn2022/com/gfs
	    DCOMROOT=/lfs/h2/emc/vpppg/noscrub/yali.mao/dcom_2022
	fi
    fi
    COMPATH=/lfs/h2/emc/ptmp/yali.mao/wafs_dwn/com/gfs
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
    if [[ $job = 'GCIP' ]] ; then
	sed -e "s|COMPATH=.*|COMPATH=$COMPATH:/lfs/h1/ops/prod/com/radarl2|" -i $TMP/$driver
    fi
fi
if [[ ! -z $DCOMROOT ]] ; then
    sed -e "s|DCOMROOT=.*|DCOMROOT=$DCOMROOT|" -i $TMP/$driver
fi

qsub < $TMP/$driver
