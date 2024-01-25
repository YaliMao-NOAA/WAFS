#!/bin/sh
#PBS -j oe
#PBS -N transfer2hpss
#PBS -l walltime=01:30:00
#PBS -q dev_transfer
#PBS -A GFS-DEV
#PBS -l select=1:ncpus=1
#PBS -V

cd $PBS_O_WORKDIR
set -x

hpssdir=/NCEPDEV/emc-global/5year/Yali.Mao/evs
wcossdir=/lfs/h2/emc/vpppg/noscrub/yali.mao/stats_from_vsdb

cd $wcossdir

htar -cvf $hpssdir/stats_from_vsdb.tar ./*
