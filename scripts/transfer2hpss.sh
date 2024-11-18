#!/bin/sh
#PBS -j oe
#PBS -N transfer2hpss
#PBS -l walltime=00:30:00
#PBS -q dev_transfer
#PBS -A GFS-DEV
#PBS -l select=1:ncpus=1
#PBS -V

cd $PBS_O_WORKDIR
set -x

HTAR_COMMAND=${HTAR_COMMAND:-"htar -tvf /NCEPPROD/hpssprod/runhistory/rh2024/202409/20240903/com_gfs_v16.3_gfs.20240903_00.gfs.tar"}
$HTAR_COMMAND
