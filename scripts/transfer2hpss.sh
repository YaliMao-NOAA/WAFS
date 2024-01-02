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

$HTAR_COMMAND
