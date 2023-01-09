#!/bin/sh
set -x

. /usrx/local/Modules/default/init/bash
module load prod_util/v1.0.2
module load grib_util/v1.0.1

module load lsf ics ibmpe
module list
module load GrADS
module load grib_util

#export WCOSSSAVE=${WCOSSSAVE:-/sss/emc/global/shared/Yali.Mao/save}
export WCOSSSAVE=${WCOSSSAVE:-/global/save/Yali.Mao/save}

PDY=${PDY:-`/nwprod/util/exec/ndate | cut -c1-8`}

user=`whoami`
DATAROOT=/ptmpp1/${user}

cd $DATAROOT

COMPLOT=$DATAROOT/plot.$PDY
DATAPLOT=$DATAROOT/plot.$PDY.working

runGFIP=prod

# operational GFIP
if [[ $runGFIP == prod || $runGFIP == para ]] ; then
    COMINGFIP=/com2/gfs/$runGFIP/gfs.$PDY
else
#   for expemental, doesn't need extra folder, so $COMOUTGFIP == $COMINGFIP
    COMINGFIP=$DATAROOT/$runGFIP/gfip.$PDY
fi
COMOUTGFIP=$DATAROOT/$runGFIP/gfip.$PDY

# operational GFIS 
runGFIS=prod
if [[ $runGFIS == prod || $runGFIS == para ]] ; then
#   (operational is public, doesn't need to be FTPed)
    COMINGFIS=/com2/gfs/$runGFIS/gfs.$PDY
else
    COMINGFIS=$DATAROOT/$runGFIS/gfip.$PDY
fi
COMOUTGFIS=$DATAROOT/$runGFIS/gfip.$PDY

# opreational GCIP
runGCIP=prod
if [[ $runGCIP == prod || $runGCIP == para ]] ; then
    COMINGCIP=/com2/gfs/$runGCIP/gfs.$PDY
else
    COMINGCIP=$DATAROOT/$runGCIP/gcip.$PDY
fi
COMOUTGCIP=$DATAROOT/$runGCIP/gcip.$PDY
cyc2=$(( cyc + 3 ))
cyc2=`printf "%02d" $cyc2`

########################################################
#### Step 1: collect data from /com2                ####
########################################################
# GFIP needs to be extracted from master file if operational or experimental
mkdir -p $COMOUTGFIP
fhours="06 09 12 15 18 21 24 27 30 33 36"

if [[ $runGFIP == prod || $runGFIP == para  ]] ; then
  for fh in $fhours ; do
#    $WGRIB2 $COMINGFIP/gfs.t${cyc}z.master.grb2f$fh | grep ":ICIP:\|:ICSEV:" | $WGRIB2 -i $COMINGFIP/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTGFIP/gfs.t${cyc}z.master.grb2f$fh
    $WGRIB2 $COMINGFIP/gfs.t${cyc}z.master.grb2f$fh | grep ":ICIP:" | $WGRIB2 -i $COMINGFIP/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTGFIP/gfs.t${cyc}z.master.grb2f$fh
  done
fi

# GFIS is appended to extracted GFIP
if [[ $runGFIS == para  ]] ; then # operational, not FTPed; experimental, folder and file are ready
  for fh in $fhours ; do
    if [[ -e gfs.t${cyc}z.master.grb2f$fh ]] ; then
      $WGRIB2 $COMINGFIS/gfs.t${cyc}z.master.grb2f$fh | grep ":ICSEV:" | $WGRIB2 -i $COMINGFIS/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTGFIS/gfs.t${cyc}z.master.grb2f$fh.sev
      cat $COMOUTGFIP/gfs.t${cyc}z.master.grb2f$fh.sev >> $COMOUTGFIP/gfs.t${cyc}z.master.grb2f$fh
      rm $COMOUTGFIP/gfs.t${cyc}z.master.grb2f$fh.sev
    else
      $WGRIB2 $COMINGFIS/gfs.t${cyc}z.master.grb2f$fh | grep ":ICSEV:" | $WGRIB2 -i $COMINGFIS/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTGFIS/gfs.t${cyc}z.master.grb2f$fh
    fi
  done
fi

# GCIP
mkdir -p $COMOUTGCIP
cp $COMINGCIP/gfs.t${cyc}z.gcip.f00.grib2 $COMOUTGCIP/.
cp $COMINGCIP/gfs.t${cyc2}z.gcip.f00.grib2 $COMOUTGCIP/.

########################################################
#### Step 2: ftp grib2 data to RZDM FTP server      ####
########################################################
# GFIP, extracted from master file
sh $WCOSSSAVE/scripts/ftp_wafs.sh $runGFIP gfip $PDY$cyc

# GCIP, no need extra transfer for $cyc2 because the whole folder is transferred
sh $WCOSSSAVE/scripts/ftp_wafs.sh $runGCIP gcip $PDY$cyc
#sh $WCOSSSAVE/scripts/ftp_wafs.sh $runGCIP gcip $PDY$cyc2

# GFIS, doesn't need to be uploaded for operational ones
if [[ $runGFIS != prod ]] ; then
    sh $WCOSSSAVE/scripts/ftp_wafs.sh $runGCIS gfis $PDY$cyc
fi

########################################################
### Step 3: grads plots. ftp to RZDM icao WEB server ###
########################################################

# for operational, GFIS doesn't need to be sent to FTP server but needs to be plotted
# GFIS is appended to extracted GFIP
if [[ $runGFIS == prod ]] ; then
  for fh in $fhours ; do
    $WGRIB2 $COMINGFIS/gfs.t${cyc}z.master.grb2f$fh | grep ":ICSEV:" | $WGRIB2 -i $COMINGFIS/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTGFIS/gfs.t${cyc}z.master.grb2f$fh.sev
    cat $COMOUTGFIP/gfs.t${cyc}z.master.grb2f$fh.sev >> $COMOUTGFIP/gfs.t${cyc}z.master.grb2f$fh
    rm $COMOUTGFIP/gfs.t${cyc}z.master.grb2f$fh.sev
  done
fi

mkdir -p $COMPLOT

mkdir -p $DATAPLOT
cd $DATAPLOT
rm -f *

# copy GCIP data
cp $COMOUTGCIP/*t${cyc}z.gcip.f00.grib2 .
cp $COMOUTGCIP/*t${cyc2}z.gcip.f00.grib2 .

# copy GFIP data
cp $COMOUTGFIP/gfs.t${cyc}z.master.grb2f?? .

for grb2file in `ls` ; do
   sh $WCOSSSAVE/grads/plotWafs.sh original potential $grb2file
   sh $WCOSSSAVE/grads/plotWafs.sh original severity  $grb2file
   sh $WCOSSSAVE/grads/plotWafs.sh conus  potential $grb2file
   sh $WCOSSSAVE/grads/plotWafs.sh conus  severity  $grb2file
   sh $WCOSSSAVE/grads/plotWafs.sh hawaii  potential $grb2file
   sh $WCOSSSAVE/grads/plotWafs.sh hawaii  severity  $grb2file
   sh $WCOSSSAVE/grads/plotWafs.sh alaska  potential $grb2file
   sh $WCOSSSAVE/grads/plotWafs.sh alaska  severity  $grb2file
done

mv *.png $COMPLOT/.
cd $COMPLOT/.
rm -r $DATAPLOT
sh $WCOSSSAVE/scripts/ftp_wafs.sh exp plot $PDY$cyc

########################################################
#### Step 4: cleanup if data  48 hours before       ####
####         update grib plotting web page as well  ####
########################################################                                                                                                             
dates=$PDY
dates="$dates "`/nwprod/util/exec/ndate -1 ${PDY}00 | cut -c1-8`
if [[ $cyc <  18 ]] ; then
    dates="$dates "`/nwprod/util/exec/ndate -25 ${PDY}00 | cut -c1-8`
fi
ssh ymao@emcrzdm "sh ~/scripts/wafs_gcip_maintenance.sh $runGCIP $cyc $dates"
ssh ymao@emcrzdm "sh ~/scripts/wafs_web.ftp_maintenance.sh $runGFIP $runGCIP $cyc $dates"
