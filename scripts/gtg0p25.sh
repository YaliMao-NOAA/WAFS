#!/bin/sh
################################################
# convert GTG data from $COM to 0p25
# (optinal) upload 0p25 GTG data to RZDM gtg_makeup
# Usage:
#  sh gtg0p25.sh PDY [rzdm]
################################################


set -xa

. /usrx/local/Modules/default/init/bash
module load prod_util/v1.0.2
module load grib_util/v1.0.1

module load lsf ics ibmpe
module list
module load GrADS
module load grib_util

PDYgtg=$1
FTP=$2

COMINgtg=/gpfs/hps/nco/ops/com/gfs/prod/gfs.$PDYgtg

dataDir=gtg.$PDYgtg

COMOUTgtg=/ptmpp1/Yali.Mao/gtg_makeup/$dataDir
mkdir -p $COMOUTgtg

fhours="06 09 12 15 18 21 24 27 30 33 36"
if [[ -n $PDYgtg ]] ; then
  for cyc in 00 06 12 18 ; do
  for fh in $fhours ; do
    if [[ -s $COMINgtg/gfs.t${cyc}z.gtg.grb2f$fh ]] ; then
      # upscale to 0.25 degree, using the same option as scripts/exglobal_pgrb2_gfs_g2_poe.sh.ecf
      opt1=' -set_grib_type same'
      opt2=' -new_grid_interpolation bilinear -new_grid_winds grid '
      grid0p25="latlon 0:1440:0.25 90:721:-0.25"
      $WGRIB2 $COMINgtg/gfs.t${cyc}z.gtg.grb2f$fh $opt1 $opt2 -new_grid $grid0p25 $COMOUTgtg/gfs.t${cyc}z.gtg.0p25.grb2f$fh
    fi
  done
  done
fi

# send 0p25 GTG data to RZDM FTP server
if [[ $FTP == 'rzdm' ]] ; then
     remote=/home/ftp/emc/unaff/ymao/gtg_makeup/$dataDir
     remoteServer=ymao@emcrzdm
     ssh $remoteServer "mkdir -p $remote"

     rsync -avP $COMOUTgtg/. ${remoteServer}:${remote}/.
fi