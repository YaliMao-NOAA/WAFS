#!/bin/bash

module load prod_envir
module load prod_util

#PDY=$($NDATE)
PDY=${PDY:0:8}
cyc=${cyc:-12}

envirs=${envirs:-"prod"}

DATA=/lfs/h2/emc/ptmp/$USER/missing_blending
rm -rf $DATA ; mkdir $DATA
cd $DATA || err_exit "FATAL ERROR: Could not 'cd ${DATA}'; ABORT!"

fhours="6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 27 30 33 36 39 42 45 48"
for envir in $envirs ; do
  for cyc in 00 06 12 18 ; do
    if [ $envir = 'prod' ] ; then
	gfs_ver=v16.3
	export COMPATH=$COMROOT/gfs
	COMIN=$(compath.py "gfs/${gfs_ver}")/gfs.${PDY}/${cyc}/atmos
    elif [ $envir = 'para' ] ; then
	wafs_ver=v7.0
	export COMPATH=/lfs/h2/emc/ptmp/yali.mao/wafsx001/prod/com/wafs
	COMIN=$(compath.py "wafs/${wafs_ver}")/wafs.${PDY}/${cyc}/grib2/0p25/blending
    fi

    for fhr in $fhours ; do
	if [ $envir = 'prod' ] ; then
	    fhr="$(printf "%02d" $(( 10#$fhr )) )"
	elif [ $envir = 'para' ] ; then
	    fhr="$(printf "%03d" $(( 10#$fhr )) )"
	fi
	file=WAFS_0p25_blended_$PDY${cyc}f${fhr}.grib2
	if [[ ! -f $COMIN/$file ]] ; then
	    echo $COMIN/$file >> missing_files_$envir.$cyc
	fi
    done

    if [[ -f missing_files_$envir.$cyc ]] ; then
	echo "Missing $envir files" >> missing_files.$cyc
	echo "--------------------" >> missing_files.$cyc
	cat missing_files_$envir >> missing_files.$cyc
	echo >> missing_files.$cyc
    fi
  done
done


if [[ -f missing_files ]] ; then
    subject="Missing blended data $PDY $cyc"
    cat missing_files | mail -s "$subject" "yali.mao@noaa.gov"
fi
