#!/bin/ksh

set -x

user=`whoami`
cd /ptmpp1/$user

# called minutes after GFIS is done
#sleep 120
maxsleep=18000 # 5 hours
waittime=0
dates=`ls gfip.??????????.ok`
while [ -z $dates ] ; do
  if [ $waittime -gt $maxsleep ] ; then
    break
  fi    
  waittime=$(( waittime + 60 ))
  sleep 60
  dates=`ls gfip.??????????.ok`
done
dates=`echo $dates | sed -e "s/gfip.//g"`

remoteSever=ymao@emcrzdm.ncep.noaa.gov

#dirs="gfip gfip_g217 gfip_g4"
dirs=$1
if [[ -z $2 ]] ; then
  fhours="06 09 12 15 18 21 24 27 30 33 36"
else
  fhours=$2
fi

for PDYs in $dates ; do
  for dir in $dirs ; do

    PDY=`echo $PDYs | cut -c 1-8`
    cyc=`echo $PDYs | cut -c 9-10`

    remoteDir=/home/ftp/emc/unaff/ymao/$dir/gfip.$PDY

    cd /ptmpp1/$user/gfip.$PDY/
    ssh $remoteSever "mkdir -p $remoteDir" 2>/dev/null # create the folder if not existing
    for fhour in $fhours ; do
      if [ $dir = 'gfip' ] ; then
        scp -p gfs.t${cyc}z.gfip.grbf$fhour $remoteSever:$remoteDir/.   2>/dev/null 
      elif [ $dir = 'gfip_g217' ] ; then
        scp -p gfs.gfip.grd217.${PDY}${cyc}f$fhour.grib2 $remoteSever:$remoteDir/.  2>/dev/null
      elif [ $dir = 'gfip_g4' ] ; then
        scp -p gfs.gfip.grd4.grb${PDY}${cyc}f$fhour $remoteSever:$remoteDir/.  2>/dev/null
      else
        scp -p gfs.t${cyc}z.gfip.grbf$fhour $remoteSever:$remoteDir/.   2>/dev/null
      fi
    done

  done #dir
  rm /ptmpp1/$user/gfip.$PDYs
done  #PDYs

exit

