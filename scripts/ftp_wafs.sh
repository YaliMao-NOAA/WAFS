#!/bin/ksh
#**************************************************************
# Transfer data from WCOSS to RZDM by scp 
#**************************************************************

set -x

function printUsage {
  echo 'Usage: ftp_wafs.sh run product YYYYMMDD[HH[FH]] dataroot'
}

# samples:
# ksh ftp_wafs.sh dcom uk 20150929
# ksh ftp_wafs.sh prod us 20150929



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prod / para	||  us | uk | master | blend
# exp		||  gfip | gcip | turb | plot | plot
# verf		||  vsdb | plot
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run=$1
prd=$2
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

#=======================================================
# adjust some variables if there are two argument
#=======================================================
cycles="00 06 12 18"
fhours="06 09 12 15 18 21 24 27 30 33 36"
if [ $# -ge 3 ]; then
  PDY=`echo $3 | cut -c1-8`

  hh=`echo $3 | cut -c9-10`
  fh=`echo $3 | cut -c11-12`
  if [[ -n $hh ]] ; then
     cycles="$hh"
     if [[ -n $fh ]] ; then
	fhours="$fh"
     fi
  fi
else
  exit
fi

dataroot=$4

#=======================================================
# prepare local folder, data folder,  fileTemplate 
# and remote folder, then transfer data
#=======================================================


# comin/base folder, data folder and file template
#-----------------------------------------------
# fileTemplate is NULL if transferring a directory;
#   for transferring indiviual files from the original place,
#   doesn't need to be stored in another folder
moduel load prod_envir
com2=$COMROOThps
if [ $prd = us ] ; then
    comin=$com2/gfs/$run
    dataDir=gfs.$PDY
    fileTemplate=gfs.tHHz.wafs_grb45fFH.grib2
elif [ $prd = blend ] ; then
    comin=$com2/gfs/$run/gfs.$PDY
    dataDir=gfs.$PDY
    fileTemplate=WAFS_blended_${PDY}HHfFH.grib2
elif [ $prd = master ] ; then
    comin=$com2/gfs/$run/gfs.$PDY
    dataDir=gfs.$PDY
    fileTemplate=gfs.tHHz.master.grb2fFH
elif [ $prd = uk ] ; then
    comin=/dcom/us007003
    dataDir=${PDY}/wgrbbul/ukmet_wafs
    fileTemplate=EGRR_WAFS_unblended_PDY_HHz_tFH.grib2
else # all others need to be saved in another working folder
    if [[ $prd = gcip ||  $prd = gfip || $prd = gfis || $prd = gtg ]] ; then
	comin=/ptmpp1/$user/$run
    else
	comin=/ptmpp1/$user
    fi
    dataDir=$prd.$PDY
    fileTemplate=
fi


# remote server and folder
#-----------------------------------------------
if [[ $run = verf && $prd = plot ]] ; then
    remote=
    remoteServer=ymao@emcrzdm
elif [[ $run = verf && $prd = vsdb ]] ; then
    remote=
    remoteServer=
elif [[ $run = exp && $prd = plot ]] ; then
    remote=/home/www/emc/htdocs/gmb/icao/grdplot
    remoteServer=ymao@emcrzdm
elif [[ $run = dcom && $prd = uk ]] ; then
    remote=${remote:-/home/ftp/emc/unaff/ymao/wafs.prod/ukmet.$PDY}
    remoteServer=ymao@emcrzdm
else
    remote=${remote:-/home/ftp/emc/unaff/ymao/wafs.$run/$dataDir}
    remoteServer=ymao@emcrzdm
fi

# transfer data
#-----------------------------------------------
# create a corresponding data file/directory on RZDM
ssh $remoteServer "mkdir -p $remote"

if  [[ -n $fileTemplate ]] ; then

   for hh in $cycles ; do
   for fh in $fhours ; do

      file2ftp=`echo $dataDir/$fileTemplate | sed -e "s|PDY|$PDY|g" -e "s|HH|$hh|g" -e "s|FH|$fh|g"`

      local=$comin
      scp -p $local/$file2ftp ${remoteServer}:$remote
   done
   done
else
   local=$comin
   rsync -avP $local/$dataDir/. ${remoteServer}:${remote}/.
fi
