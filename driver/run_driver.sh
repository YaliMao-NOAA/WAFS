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

PDY=20220218
HOMEgfs=/lfs/h2/emc/vpppg/noscrub/Yali.Mao/git/fork.implement2023

sed -e "s|PDY=.*|PDY=$PDY|" -e "s|HOMEgfs=.*|HOMEgfs=$HOMEgfs|" \
    $HOMEgfs/driver/$driver > $TMP/$driver

qsub < $TMP/$driver
