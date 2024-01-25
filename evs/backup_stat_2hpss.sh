#!/bin/sh
#PBS -j oe
#PBS -o /lfs/h2/emc/ptmp/yali.mao/backup_stat.log
#PBS -N backup_stat
#PBS -l walltime=00:30:00
#PBS -q dev_transfer
#PBS -A GFS-DEV
#PBS -l select=1:ncpus=1
#PBS -V

# Monthly backup EVS WAFS stat file of last month
# job needs to be executed before the first 20 day of the current month

module load prod_util

set -x

hpssdir=/NCEPDEV/emc-global/5year/Yali.Mao/evs
lastmonth=`$NDATE -480 | cut -c1-6`

DATA=/lfs/h2/emc/ptmp/yali.mao/backup_stat_working
mkdir -p $DATA
cd /lfs/h2/emc/ptmp/yali.mao/backup_stat_working
mkdir -p $lastmonth

DDs="01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31"
for DD in $DDs ; do
    evsdir=`find /lfs/h1/ops/*/com/evs/*/stats/wafs -name wafs.${lastmonth}${DD} | tr ' ' '\n' | sort -nr | head -1`
    if [ ! -z $evsdir ] ; then
	cp $evsdir/* $lastmonth/.
    fi
done

htar -cvf $hpssdir/${lastmonth}.tar ./$lastmonth/*
#./202312/evs.stats.wafs.atmos.grid2grid_uvt1p25.v20231208.stat
