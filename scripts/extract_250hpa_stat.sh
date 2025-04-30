#!/bin/sh
#PBS -j oe
#PBS -o /lfs/h2/emc/ptmp/yali.mao/extract4UK.log
#PBS -N extract_stat
#PBS -l walltime=03:30:00
#PBS -q dev_transfer
#PBS -A GFS-DEV
#PBS -l select=1:ncpus=1
#PBS -V

# Extract EVS WAFS uvt stat file from HPSS

module load prod_util

set -x

datafolder=/lfs/h2/emc/ptmp/yali.mao/evs_plot/data

extractfromHPSS=no

if [ $extractfromHPSS = 'yes' ] ; then
    mkdir -p $datafolder/tmp
    cd $datafolder/tmp
    YYYY=2025
    MMs="04"
    for MM in $MMs ; do
	DD=21
	while [ $DD -lt 31 ] ; do
	    DD=$((10#$DD + 1))
	    if [ $DD -lt 10 ] ; then
		DD="0$DD"
	    fi
	    htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YYYY/$YYYY$MM/$YYYY$MM$DD/com_evs_v1.0.stats.tar ./stats/wafs/wafs.$YYYY$MM$DD/evs.stats.wafs.atmos.grid2grid_uvt1p25.v$YYYY$MM$DD.stat
	done
    done
    
    mkdir $datafolder/new$YYYY
    cp $datafolder/tmp/stats/wafs/*/* $datafolder/new$YYYY
    exit
fi

cd $datafolder
years="2024 2025"
for year in $years ; do
    cd $datafolder/$year
    files="ls *uvt*"
    grep "P250    ANALYS \(TROPICS\|NHEM\|SHEM\)" *uvt* | grep -v "WIND80" | grep " 240000    $year" > $datafolder/extract_$year.stat.tropics.hemisphere
    grep "P250    ANALYS \(NATL_AR2\|NPO\)" *uvt* | grep "WIND" | grep " 240000    $year" > $datafolder/extract_$year.stat.area2.npo.wind
    grep "P250    ANALYS \(NATL_AR2\|NPO\)" *uvt* | grep "TMP"  | grep " 240000    $year" > $datafolder/extract_$year.stat.area2.npo.tmp
done

: '
datafolder_in=/lfs/h2/emc/vpppg/noscrub/yali.mao/vsdb/wafs/prod.prod
datafolder_out=/lfs/h2/emc/ptmp/yali.mao/uk_vsdb
cd $datafolder_in
files=`ls twind*vsdb`
for file in $files ; do
    grep "P250 =" $file | grep "\(NPCF\|AR2\)" > $datafolder_out/p250_$file
done
'

