#!/bin/bash

module load prod_envir
module load prod_util

set -eu

PDY=$($NDATE)
cycles="18 12 06 00"

envirs=${envirs:-"prod"}

DATA=/lfs/h2/emc/ptmp/$USER/missing_blending
rm -rf $DATA ; mkdir $DATA
cd $DATA || err_exit "FATAL ERROR: Could not 'cd ${DATA}'; ABORT!"

function find_missing_blended_files() { # for a single PDY, cyc, envir
    local PDY=$1
    local cyc=$2
    local envir=$3

    if [ $envir = 'prod' ] ; then
	wafs_ver=v7.0
	COMIN=$(compath.py "wafs/${wafs_ver}")/wafs.${PDY}/${cyc}/grib2/0p25/blending
    fi

    [ ! -d "${COMIN%/*/*/*}" ] && return
    
    #seq0="0"
    #seq1=$(seq -s ' ' 6 1 24)
    #seq2=$(seq -s ' ' 27 3 48)
    #fhours="${seq1} ${seq2}"
    fhours=($(seq -s ' ' -f "%03g" 6 1 24; seq -s ' ' -f "%03g" 27 3 48))

    for fhr in ${fhours[@]}; do
	#fhr="$(printf %03d $(( 10#$fhr )) )"
	file=WAFS_0p25_blended_$PDY${cyc}f${fhr}.grib2
	if [[ ! -f $COMIN/$file ]] ; then
	    echo $COMIN/$file >> missing_files_$envir.$PDY$cyc
	fi
    done
}

##########################################################
# Run loop to find missing files in PDYs cycles and envirs
##########################################################
for envir in $envirs ; do
    idays=0
    while [[ $idays -lt 7 ]] ; do
	PDY=${PDY:0:8}
	for cyc in $cycles ; do
	    find_missing_blended_files $PDY $cyc $envir
	    
	    if [[ -f missing_files_$envir.$PDY$cyc ]] ; then
		echo "Missing blending files $envir $PDY $cyc" >> missing_files
		echo "--------------------" >> missing_files
		cat missing_files_$envir.$PDY$cyc >> missing_files
		echo >> missing_files
	    fi
	done
	idays=$(( idays + 1 ))
	PDY=$($NDATE -1 "${PDY}00")
    done
done


if [[ -f missing_files ]] ; then
    subject="Missing blended data $PDY $cyc"
#    cat missing_files | mail -s "$subject" "yali.mao@noaa.gov"
    cat missing_files
fi
