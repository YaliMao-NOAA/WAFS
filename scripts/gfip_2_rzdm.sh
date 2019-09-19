#!/bin/ksh

set -x

#######################################################
developMachine=`cat /etc/dev` # stratus / cirrus
thisMachine=`hostname` # c1n6.ncep.noaa.gov / s1n6.ncep.noaa.gov
# The first letters of $developMachine and $thisMachine must match; otherwise exit
if [ `echo $developMachine | cut -c 1-1` != `echo $thisMachine | cut -c 1-1` ] ; then
  exit
fi


#**************************************************************
# Transfer data from CCS to RZDM by scp (Real Time)
#-------------------------------------------------------------
#
# Notes: 
# 1) On CCS, RZDM can be identified; not vice versa
# 2) Considering data delay, gfip is generated one day after.
#    This script will transfer the data of yesterday and the
#    day before yesterday, to guarantee no data is left behind    
# 
#**************************************************************

function printUsage {
  echo 'Usage: gfip_2_rzdm.sh [YYYYMMDD[HH[FH]]'
}

localDir=/ptmpp1/wx20yam/fip/gfs/
remoteDir=/home/ftp/emc/unaff/ymao/gfip/gfs/
remoteServer=ymao@emcrzdm

cd $localDir

# rsync -urtv  -e ssh ${remoteServer}:${remoteDir} .

cycles="00 06 12 18"
fhours="03 06"

ndays=2 # yesterday and the day before yesterday
n=1
today00=`date "+%Y%m%d"`00 # add "00" to convert to YYYYMMDDHH
whichday00=`ndate $(( $n * -24 )) $today00` # start from yesterday then even earlier
whichday=${whichday00%??}

#=======================================================
# adjust some variables if there is one argument
#=======================================================
if [ $# -eq 1 ]; then
  ndays=1
  whichday=`echo $1 | cut -c1-8`
  if [ `ndate 0 ${whichday}00 ` != ${whichday}00 ] ; then
      echo "You have a wrong YYYYMMDD input."
      printUsage
      exit
  fi

  hh=`echo $1 | cut -c9-10`
  fh=`echo $1 | cut -c11-12`
  if [[ -n $hh ]] ; then
    if [ $hh -ge 0 -a $hh -le 23 ] ; then
      cycles="$hh"
      if [[ -n $fh ]] ; then
        fhours="$fh"
      fi
    else
      echo "Wrong cycle time."
      printUsage
      exit
    fi
  fi
fi

#=======================================================
# transfer data
#=======================================================
while [[ $n -le $ndays ]] ; do

  dataDir=gfs.${whichday}
  if [ -e  $dataDir ] ; then
    # create a corresponding data directory on RZDM
    ssh $remoteServer "mkdir -p $remoteDir$dataDir"
    for hh in $cycles ; do
      for fh in $fhours ; do
        whichfile=${dataDir}/gfs.t${hh}z.fip.grbf${fh}
	remotefile=${remoteDir}$whichfile

        # do not transfer the file if it exists.
 	if  [ `ssh $remoteServer "ls -l $remotefile " 2>/dev/null | awk '{ print $5}' ` -gt 130000000 ] ; then
          continue
        fi
 
        scp -p $whichfile ${remoteServer}:$remotefile
      done
    done
  fi

  n=$(( n + 1))
  whichday00=`ndate $(( $n * -24 )) $whichday00`
  whichday=${whichday00%??}

done

