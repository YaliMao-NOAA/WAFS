#!/bin/sh
#**************************************************************
# Re-orgnaize icing turbulence data and do plotting, then 
# transfer to RZDM ftp/www server
#**************************************************************

# The following variables need attention:
# COMINprod
# SAVEdir: on Cray (if save instead of noscrub is available)
# cyc: must be transferred from the caller
# COMINmine: with com/ as COMINprod

user=`whoami`

#=====================================================#
if [[ `hostname` =~ ^[g|t][0-9]{1} ]] ; then
#     `cat /etc/dev` # gyre/tide/luna/surg
#=====================================================#

  #========== Gyre/Tide =====================#

  export SAVEdir=/global/save/Yali.Mao/save
  export TMPdir=/ptmpp1/${user}

  if [ ! -z $MODULESHOME ]; then
    . $MODULESHOME/init/bash
  else
    . /usrx/local/Modules/default/init/bash
  fi
  module load lsf ics ibmpe

  module load prod_envir/v1.0.1

#=====================================================#
else
#=====================================================#

  #========== Surge/Luna ====================#

  export SAVEdir=/gpfs/hps3/emc/global/noscrub/Yali.Mao/save
  export TMPdir=/gpfs/hps/ptmp/$user

  if [ ! -z $MODULESHOME ]; then
    . $MODULESHOME/init/bash
  else
    . /opt/modules/default/init/bash
  fi

  module use -a /opt/cray/craype/default/modulefiles
  module use -a /opt/cray/ari/modulefiles
  module use -a /opt/cray/alt-modulefiles
  module use -a /gpfs/hps/nco/ops/nwprod/modulefiles
  module use -a /usrx/local/prod/modulefiles

  module load PrgEnv-intel
  module load cray-mpich
  module load xt-lsfhpc/9.1.3

  module load prod_envir/1.0.1

#=====================================================#
fi
#=====================================================#

COMINprod=$COMROOTp2
COMINmine=/gpfs/hps/ptmp/$user/com

module load prod_util
module load grib_util

module load GrADS

set -xa

fhours="06 09 12 15 18 21 24 27 30 33 36"

# cyc must be transferred from the caller

DATAROOT=$TMPdir/wafs2rzdm.data
mkdir -p $DATAROOT
cd $DATAROOT

########################################################
#### Step 0: prepare PDY COMIN COMOUT               ####
########################################################

PDY=${PDY:-`$NDATE | cut -c1-8`}

RUNgfip=prod
############## operational GFIP ##############
##############################################
if [[ $RUNgfip == prod || $RUNgfip == para ]] ; then
    COMINgfip=$COMINprod/gfs/$RUNgfip/gfs.$PDY
else
#   for expemental, doesn't need extra folder, so $COMOUTgfip == $COMINgfip
    COMINgfip=$COMINmine/gfs/$RUNgfip/gfip.$PDY
fi
COMOUTgfip=$DATAROOT/$RUNgfip/gfip.$PDY

############## operational GFIS ##############
##############################################
RUNgfis=prod
if [[ $RUNgfis == prod || $RUNgfis == para ]] ; then
#   (operational is public, doesn't need to be FTPed)
    COMINgfis=$COMINprod/gfs/$RUNgfis/gfs.$PDY
else
    COMINgfis=$COMINmine/gfs/$RUNgfis/gfip.$PDY
fi
COMOUTgfis=$DATAROOT/$RUNgfis/gfip.$PDY

############## opreational GCIP ##############
##############################################
RUNgcip=prod
if [[ $RUNgcip == prod || $RUNgcip == para ]] ; then
    COMINgcip=$COMINprod/gfs/$RUNgcip/gfs.$PDY
else
    COMINgcip=$COMINmine/gfs/$RUNgcip/gcip.$PDY
fi
COMOUTgcip=$DATAROOT/$RUNgcip/gcip.$PDY
cyc2=$(( cyc + 3 ))
cyc2=`printf "%02d" $cyc2`

#############   parallel G-GTG   #############
##############################################
# GTG has its own PDYgtg to have more control
date
RUNgtg=test
if [[ $RUNgtg == prod || $RUNgtg == para ]] ; then
    PDYgtg=$PDY
    COMINgtg=
else
    PDYgtg=$PDY
    COMINgtg=$COMINmine/gfs/$RUNgtg/gfs.$PDYgtg
    # wait till all input data available
    SLEEP_TIME=18000 # wait for 5 hours
    SLEEP_INT=30
    SLEEP_LOOP_MAX=`expr $SLEEP_TIME / $SLEEP_INT`
    ic=1
    for fh in $fhours ; do
	while [ $ic -le $SLEEP_LOOP_MAX ] ; do
	    if [ -f $COMINgtg/gfs.t${cyc}z.gtg.grb2f$fh ] ; then
		break
	    else
		ic=`expr $ic + 1`
		sleep $SLEEP_INT
                # If we reach this point, assume fcst job has never reached.
		if [ $ic -eq $SLEEP_LOOP_MAX ] ; then
		    echo "Warning!!!! GTG files not generated, GTG plotting will not be executed."
		    mailx -s "GTG plotting, non-existing $COMINgtg/gfs.t${cyc}z.gtg.grb2f$fh." yali.mao@noaa.gov
		    # PDYgtg=""
		fi
	    fi
	done
    done
fi
COMOUTgtg=$DATAROOT/$RUNgtg/gtg.$PDYgtg

########################################################
#### Step 1: collect data from $COMINprod           ####
########################################################
mkdir -p $COMOUTgfip ; rm $COMOUTgfip/*
mkdir -p $COMOUTgfis ; rm $COMOUTgfis/*
mkdir -p $COMOUTgcip ; rm $COMOUTgcip/*
if [[ -n $PDYgtg ]] ; then
  mkdir -p $COMOUTgtg ; rm $COMOUTgtg/*
fi

# GFIP needs to be extracted from master file if operational or experimental

if [[ $RUNgfip == prod || $RUNgfip == para  ]] ; then
  for fh in $fhours ; do
#    $WGRIB2 $COMINgfip/gfs.t${cyc}z.master.grb2f$fh | grep ":ICIP:\|:ICSEV:" | $WGRIB2 -i $COMINgfip/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTgfip/gfs.t${cyc}z.master.grb2f$fh
    $WGRIB2 $COMINgfip/gfs.t${cyc}z.master.grb2f$fh | grep ":ICIP:" | $WGRIB2 -i $COMINgfip/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTgfip/gfs.t${cyc}z.master.grb2f$fh
  done
fi

# GFIS is appended to extracted GFIP
if [[ $RUNgfis == para  ]] ; then # operational, not FTPed; experimental, folder and file are ready
  for fh in $fhours ; do
    if [[ -e $COMOUTgfis/gfs.t${cyc}z.master.grb2f$fh ]] ; then
      $WGRIB2 $COMINgfis/gfs.t${cyc}z.master.grb2f$fh | grep ":ICSEV:" | $WGRIB2 -i $COMINgfis/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTgfis/gfs.t${cyc}z.master.grb2f$fh.sev
      cat $COMOUTgfis/gfs.t${cyc}z.master.grb2f$fh.sev >> $COMOUTgfis/gfs.t${cyc}z.master.grb2f$fh
      rm $COMOUTgfis/gfs.t${cyc}z.master.grb2f$fh.sev
    else
      $WGRIB2 $COMINgfis/gfs.t${cyc}z.master.grb2f$fh | grep ":ICSEV:" | $WGRIB2 -i $COMINgfis/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTgfis/gfs.t${cyc}z.master.grb2f$fh
    fi
  done
fi

# GCIP
cp $COMINgcip/gfs.t${cyc}z.gcip.f00.grib2 $COMOUTgcip/.
cp $COMINgcip/gfs.t${cyc2}z.gcip.f00.grib2 $COMOUTgcip/.

# GTG

if [[ -n $PDYgtg ]] ; then
  for fh in $fhours ; do
    cp $COMINgtg/gfs.t${cyc}z.gtg.grb2f$fh $COMOUTgtg/gfs.t${cyc}z.gtg.grb2f$fh
  done
fi


########################################################
#### Step 2: ftp grib2 data to RZDM FTP server      ####
########################################################
# GFIP, extracted from master file
sh $SAVEdir/scripts/ftp_wafs1.sh $RUNgfip gfip -file $PDY$cyc $COMOUTgfip

# GCIP
sh $SAVEdir/scripts/ftp_wafs1.sh $RUNgcip gcip -file $PDY${cyc}00 $COMOUTgcip
sh $SAVEdir/scripts/ftp_wafs1.sh $RUNgcip gcip -file $PDY${cyc2}00 $COMOUTgcip

# GFIS, need to be uploaded when it's experimental.
# Operational ones are available on NOMADS
if [[ $RUNgfis != prod ]] ; then
    sh $SAVEdir/scripts/ftp_wafs1.sh $RUNgfis gfis -file $PDY$cyc $COMOUTgfis
fi

# GTG
if [[ -n $PDYgtg ]] ; then
    sh $SAVEdir/scripts/ftp_wafs1.sh $RUNgtg gtg -file $PDYgtg$cyc $COMOUTgtg
fi


########################################################
### Step 3: grads plots. ftp to RZDM icao WEB server ###
########################################################

# for operational, GFIS doesn't need to be sent to FTP server but needs to be plotted
# GFIS is appended to extracted GFIP
if [[ $RUNgfis == prod ]] ; then
  for fh in $fhours ; do
    $WGRIB2 $COMINgfis/gfs.t${cyc}z.master.grb2f$fh | grep ":ICSEV:" | $WGRIB2 -i $COMINgfis/gfs.t${cyc}z.master.grb2f$fh -grib $COMOUTgfis/gfs.t${cyc}z.master.grb2f$fh.sev
    cat $COMOUTgfip/gfs.t${cyc}z.master.grb2f$fh.sev >> $COMOUTgfip/gfs.t${cyc}z.master.grb2f$fh
    rm $COMOUTgfip/gfs.t${cyc}z.master.grb2f$fh.sev
  done
fi


# Generate plots of icing and ftp to web server first

COMPLOT=$DATAROOT/plot.$PDY
DATAPLOT=$DATAROOT/plot.$PDY.working.$$
mkdir -p $COMPLOT
mkdir -p $DATAPLOT

cd $DATAPLOT
rm -f *

# copy GCIP data
cp $COMOUTgcip/*t${cyc}z.gcip.f00.grib2 .
cp $COMOUTgcip/*t${cyc2}z.gcip.f00.grib2 .

# copy GFIP data
cp $COMOUTgfip/gfs.t${cyc}z.master.grb2f?? .

for grb2file in `ls` ; do
   sh $SAVEdir/grads/plotWafs.sh original potential $grb2file
   sh $SAVEdir/grads/plotWafs.sh original severity  $grb2file
   sh $SAVEdir/grads/plotWafs.sh conus  potential $grb2file
   sh $SAVEdir/grads/plotWafs.sh conus  severity  $grb2file
   sh $SAVEdir/grads/plotWafs.sh hawaii  potential $grb2file
   sh $SAVEdir/grads/plotWafs.sh hawaii  severity  $grb2file
   sh $SAVEdir/grads/plotWafs.sh alaska  potential $grb2file
   sh $SAVEdir/grads/plotWafs.sh alaska  severity  $grb2file
done

mv *.png $COMPLOT/.
rm -r $DATAPLOT

sh $SAVEdir/scripts/ftp_wafs1.sh test plot -file $PDY$cyc $COMPLOT

# Generate plots of GTG and ftp to web server second
if [[ -n $PDYgtg ]] ; then
  COMPLOT=$DATAROOT/plot.$PDYgtg
  DATAPLOT=$DATAROOT/plot.$PDYgtg.working.$$
  mkdir -p $COMPLOT
  mkdir -p $DATAPLOT

  cd $DATAPLOT
  if [ $PDY != $PDYgtg ] ; then rm -f * ; fi

# copy GTG data
  cp $COMOUTgtg/*t${cyc}z.gtg.grb2f?? .
  for grb2file in `ls *gtg*` ; do
      sh $SAVEdir/grads/plotWafs.sh original turbulence $grb2file
      sh $SAVEdir/grads/plotWafs.sh conus turbulence $grb2file
      sh $SAVEdir/grads/plotWafs.sh hawaii turbulence $grb2file
      sh $SAVEdir/grads/plotWafs.sh alaska turbulence $grb2file
  done

  mv *.png $COMPLOT/.
  cd $COMPLOT/.
  rm -r $DATAPLOT
  ksh $SAVEdir/scripts/ftp_wafs1.sh test plot -file $PDY$cyc $COMPLOT

fi

########################################################
#### Step 4: cleanup grib data and plottings if     ####
####         older than 'endDate', keep up to 3 days ####
########################################################                                                                                                             
dates=$PDY
dates="$dates "`/nwprod/util/exec/ndate -1 ${PDY}00 | cut -c1-8`
if [[ $cyc <  18 ]] ; then
    dates="$dates "`/nwprod/util/exec/ndate -25 ${PDY}00 | cut -c1-8`
fi
ssh ymao@emcrzdm "ksh ~/scripts/wafs_web.ftp_maintenance.sh $RUNgfip $RUNgcip $RUNgtg $cyc $dates"
