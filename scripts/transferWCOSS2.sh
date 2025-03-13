#!/bin/sh
#PBS -j oe
#PBS -N transferWCOSS2
#PBS -l walltime=00:30:00
#PBS -q dev_transfer
#PBS -A GFS-DEV
#PBS -l select=1:ncpus=1
#PBS -V

cd $PBS_O_WORKDIR
set -x
rsync -ravP --min-size=1 ddxfer04.wcoss2.ncep.noaa.gov:/lfs/h1/ops/para/com/wafs/v7.0/wafs.20241028/06 /lfs/h2/emc/ptmp/yali.mao/.
# cdxfer04.wcoss2.ncep.noaa.gov:


# To Hera:
# Terminal 1: ssh -Y -L47311:localhost:47311 Yali.Mao@hera-rsa.rdhpcs.noaa.go
# Terminal 2: (command line, not a job card) rsync -ravP ./* Yali.Mao@dtn-hera.fairmont.rdhpcs.noaa.gov:
