#!/bin/sh
#PBS -j oe
#PBS -o /lfs/h2/emc/ptmp/yali.mao/evs_plot/extract_evs_data.log
#PBS -N extract_evs
#PBS -l walltime=01:30:00
#PBS -q dev_transfer
#PBS -A GFS-DEV
#PBS -l select=1:ncpus=1
#PBS -V

set -x

# The first month of archived EVS stat file
FIRSTMONTH=202312

mkdir -p $DATAevs; cd $DATAevs

hpssdir=/NCEPDEV/emc-global/5year/Yali.Mao/evs

############## Step 1 ###################
# Extract vsdb data prior to $FIRSTMONTH
#########################################
if [ $VDAY1 -le 20231231 ] ; then
    htar -xvf $hpssdir/stats_from_vsdb.tar
fi

############## Step 2 ###################
# Soft link of the most recent two month data which is still available on WCOSS2
#########################################

# this month
YYYY=`echo $VDAY2 | cut -c1-4`
month=`echo $VDAY2 | cut -c1-6`
mkdir -p $YYYY

# last month
day=`$NDATE -24 ${month}0100 | cut -c 1-8`
year=`echo $day | cut -c1-4`
lastmonth=`echo $day | cut -c1-6`
mkdir -p $year

day=${lastmonth}01
while [ $day -le $VDAY2 ] ; do
    year=`echo $day | cut -c1-4`
    evsdir=`find /lfs/h1/ops/*/com/evs/*/stats/wafs -name wafs.$day | tr ' ' '\n' | sort -nr | head -1`
    if [ ! -z $evsdir ] ; then
        ln -s $evsdir/* $year/.
    fi
    day=`$NDATE 24 ${day}00 | cut -c1-8`
done

############## Step 3 ###################
# Extract monthly stat file between $FIRSTMONTH and the month before last month
#########################################
# the month before last month
day=`$NDATE -24 ${lastmonth}0100 | cut -c 1-8`
lastmonth=`echo $day | cut -c1-6`

month=$FIRSTMONTH
while [ $month -le $lastmonth ] ; do
    htar -xvf $hpssdir/${month}.tar

    # move data from a month folder to a year folder
    year=`echo $month | cut -c1-4`
    mkdir -p $year
    mv ${month}/* $year
    rm -r ${month}

    # 31 days later
    day=`$NDATE 744 ${month}0100 | cut -c 1-8`
    month=`echo $day | cut -c1-6`
done
