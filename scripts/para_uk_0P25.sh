#!/bin/sh
set -x

if [ -z $MACHINE ] ; then
    . ~/envir_setting.sh
fi
# If run on WCOSS2, only run on dev machine.
if [ $MACHINE_DEV = 'no' ] ; then
    echo "This is not a dev $MACHINE machine, quit job"
    exit 1
fi
date


mkdir -p $TMP/para_uk.working
rm $TMP/para_uk.working/*
cd $TMP/para_uk.working

export PDY=${PDY:-`$NDATE | cut -c1-8`}
export ICAO2023=yes
export cyc=${cyc:-00}

sh $HOMEsave/driver/run_driver.sh GRIB2_0P25 > tmp.log 2>&1

jobid=`grep "dbqs" tmp.log`
jobid=`echo $jobid | sed "s/.dbqs.*//g"`


ic=1
sleep_loop_max=200
while [ $ic -le $sleep_loop_max ]; do
    nfiles=`ls $TMP/wafs_dwn/com/gfs/v16.3/gfs.$PDY/$cyc/atmos/*unblended*grib2.idx | wc -l`
    if [ $nfiles -eq 27 ] ; then
	remoteDir=/home/ftp/emc/gmb/wafs/uk/unblended_for_uk
	ssh ymao@emcrzdm.ncep.noaa.gov "sh $remoteDir/newfolder.sh $PDY"
	scp $TMP/wafs_dwn/com/gfs/v16.3/gfs.$PDY/$cyc/atmos/*unblended*grib2  ymao@emcrzdm:$remoteDir/$PDY/.
	break
    else
	ic=`expr $ic + 1`
	sleep 15
    fi
done

date
