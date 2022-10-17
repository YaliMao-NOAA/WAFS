#!/bin/sh

set -xa

fh=$1

# PDY, cyc and fh must be exported by the caller

prod=${prod:-prod}

# For GCIP:
if [[ $fh = "000" ]] || [[ $fh = "003" ]] ; then
  cyc2=$(( cyc + fh ))
  cyc2=`printf "%02d" $cyc2`
fi

fhour=$fh
if [ $prod = para ] ; then
  fh="$(printf "%02d" $(( 10#$fh )) )"
fi

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
# Experimental needs to run own job card
if [ $prod = test ] ; then
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#

#----------------------------------------------------#
#             Prepare own $COMIN                     #
#----------------------------------------------------#

  # vrfyarch doesn't include log file which will be waited by exgfs script
  # so prepare own COMIN and generate a log file
  COMINvrfy=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/vrfyarch/gfs.${PDY}/${cyc}
  COMINvrfy=/gpfs/dell1/nco/ops/com/gfs/para/gfs.${PDY}/${cyc}
  COMIN=$TMP/fv3_para_ROTDIRS/gfs.${PDY}/${cyc}
  COMOUT=$TMP/fv3_para_prod/gfs.$PDY/$cyc

  MAX_WAIT=43200 ## wait for 12 hour for nemsio data to be ready
  SLEEP_INT=60

  waiting=0
  SIZE_ATM_STD=16986972692
  SIZE_SFC_STD=2831169944
  while [ $waiting -lt $MAX_WAIT ] ; do
    atmfile=$COMINvrfy/gfs.t${cyc}z.atmf${fh}.nemsio
    sfcfile=$COMINvrfy/gfs.t${cyc}z.sfcf${fh}.nemsio
    if [ -e $atmfile ] ; then
	size_atm=`wc -c < $atmfile`
    else
	size_atm=0
    fi
    if [ -e $sfcfile ] ;  then
	size_sfc=`wc -c < $sfcfile`
    else
	size_sfc=0
    fi
#    if [[ -e $COMINvrfy/gfs.t${cyc}z.atmf${fh}.nemsio ]] && [[ -e $COMINvrfy/gfs.t${cyc}z.sfcf${fh}.nemsio ]] ; then
#	sleep 600 # wait enough time for data transferring completed
    if [[ $size_atm -ge $SIZE_ATM_STD ]] && [[ $size_sfc -ge $SIZE_SFC_STD ]] ; then
	break
    else
      sleep $SLEEP_INT
      waiting=$(( waiting + $SLEEP_INT ))
    fi
    if [ $waiting -ge $MAX_WAIT ] ; then
      echo "Warning!!!! Real time nemsio data are not ready yet"
      exit 1
    fi
  done

  mkdir -p $COMIN
  ln -s $COMINvrfy/gfs.t${cyc}z.atmf${fh}.nemsio $COMIN/gfs.t${cyc}z.atmf${fh}.nemsio
  ln -s $COMINvrfy/gfs.t${cyc}z.sfcf${fh}.nemsio $COMIN/gfs.t${cyc}z.sfcf${fh}.nemsio
  echo $PDY$cyc$fh > $COMIN/gfs.t${cyc}z.logf${fh}.nemsio


  #----------------------------------------------------#
  #   ICING and GTG 1/2: modify and submit job card    #
  #----------------------------------------------------#

  HOMEgfs=$HOMEgit/EMC_gtg_ncar

  cp $HOMEsave/wafs_run/run_post_gfs_Grib2.nemsio.driver.$MACHINE ./run_post_fv3_Grib2.$MACHINE.$fh
  sed -e "s|#BSUB -oo.*|#BSUB -oo $DATA/fv3_post.${PDY}_${cyc}_${fh}.o%J|" \
      -e "s|#BSUB -eo.*|#BSUB -eo $DATA/fv3_post.${PDY}_${cyc}_${fh}.o%J|" \
      -e "s|#BSUB -W .*|#BSUB -W 00:10|" \
      -e "s|#BSUB -q .*|#BSUB -q dev|" \
      -e "s|export HOMEgfs=.*|export HOMEgfs=$HOMEgfs|" \
      -e "s|export COMIN=.*|export COMIN=$COMIN|" \
      -e "s|export COMOUT=.*|export COMOUT=$COMOUT|" \
      -e "s|export DATA=.*|export DATA=$DATA/fv3_working.$PDY$cyc$fh|" \
      -e "/^#/! s/export PDY=.*/export PDY=$PDY/g" \
      -e "/^#/! s/export cyc=.*/export cyc=$cyc/g" \
      -e "s/post_times=.*/post_times=$fh/" \
      -e "s|export MSTF=.*|export MSTF=YES |" \
      -e "s|export GTGF=.*|export GTGF=YES |" \
      -i run_post_fv3_Grib2.$MACHINE.$fh
  bsub < run_post_fv3_Grib2.$MACHINE.$fh

  #----------------------------------------------------#
  #     ICING and GTG 2/2: wait for job completion     #
  #----------------------------------------------------#

  # master file is the basic:
  #    GCIP depends on master file
  #    GTG is just a few minutes later than master file
  #    There is a master file for each forecast hour

  #------ For master file ------#

  MAX_WAIT=7200 # wait master file for 2 hour
  SLEEP_INT=60

  modelfilei=$COMOUT/gfs.t${cyc}z.master.grb2if$fh
  waiting=0
  while [ $waiting -lt $MAX_WAIT ] ; do
    if [[ -s $modelfilei ]] ; then
      break
    else
      sleep $SLEEP_INT
      waiting=$(( waiting + $SLEEP_INT ))
    fi
    if [ $waiting -ge $MAX_WAIT ] ; then
      echo "Warning: UPP is not completed for $PDY$cyc$fh !"
      exit 1
    fi
  done


  #------ For GTG file ------#

  if [[ $fh != "000" ]] ; then

    MAX_WAIT=600 # wait GTG file for 10 minutes, as a second product after master file
    SLEEP_INT=5

    modelfilei=$COMOUT/gfs.t${cyc}z.gtg.grb2if$fh
    waiting=0
    while [ $waiting -lt $MAX_WAIT ] ; do
	if [[ -s $modelfilei ]] ; then
	    break
	else
	    sleep $SLEEP_INT
	    waiting=$(( waiting + $SLEEP_INT ))
	fi
    done
  fi

  #----------------------------------------------------#
  #        GCIP 1/2: modify and submit job card        #
  #----------------------------------------------------#

  # will run GCIP at T and T+3 within one job
  if [[ $fh = "000" ]] ; then # 003 will be run together with 000

    # GCIP, COMINgfs is COMOUT of UPP, COMOUT is the same as COMOUT of UPP
    HOMEgfs=$HOMEgit/EMC_wafs_branch

    COMINgfs=$COMOUT

    cp $HOMEsave/wafs_run/run_WAFS_GCIP.driver.$MACHINE ./run_WAFS_GCIP.driver.$MACHINE.$fh
    sed -e "s|#BSUB -oo.*|#BSUB -oo $DATA/wafs_gcip.${PDY}_${cyc}_${fh}.o%J|" \
	-e "s|#BSUB -eo.*|#BSUB -eo $DATA/wafs_gcip.${PDY}_${cyc}_${fh}.o%J|" \
	-e "s|#BSUB -q .*|#BSUB -q debug|" \
	-e "s|export HOMEgfs=.*|export HOMEgfs=$HOMEgfs|" \
	-e "s|export COMINgfs=.*|export COMINgfs=$COMINgfs|" \
	-e "s|export COMOUT=.*|export COMOUT=$COMOUT|" \
	-e "s|export DATA=.*|export DATA=$DATA/gcip_working.$PDY$cyc$fh|" \
	-e "/^#/! s/export PDY=.*/export PDY=$PDY/g" \
	-e "/^#/! s/export cyc=.*/export cyc=$cyc/g" \
	-i run_WAFS_GCIP.driver.$MACHINE.$fh
    bsub < run_WAFS_GCIP.driver.$MACHINE.$fh

  fi

  #----------------------------------------------------#
  #         GCIP 2/2: wait for job completion          #
  #----------------------------------------------------#
  if [[ $fh = "000" ]] || [[ $fh = "003" ]] ; then

    MAX_WAIT=3600 # wait for 1 hour for GCIP
    SLEEP_INT=30

    # operational GCIP doesn't have a log file or index file
    modelfilei=$COMOUT/gfs.t${cyc2}z.gcip.f00.grib2
    waiting=0
    while [ $waiting -lt $MAX_WAIT ] ; do
      if [[ -s $modelfilei ]] ; then
	sleep 60 # to be safe to get a complete GCIP output
	break
      else
	sleep $SLEEP_INT
	waiting=$(( waiting + $SLEEP_INT ))
      fi
    done

  fi

#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#
fi
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%#


########################################################
#### plot: Step 0: prepare COMIN DATAgrib2 fh       ####
########################################################
#DATAgrib2 is for rzdm server

if [ $prod = test ] ; then
  # COMIN is COMOUT of UPP
  COMIN=$COMOUT
else
  # COMROOT is pre-defined in job for para
  gfsVer=`ls $COMROOT/gfs | tail -1`
  COMIN=$COMROOT/gfs/$gfsVer/gfs.$PDY/$cyc/atmos
fi

########################################################
####  plot: Step 1: collect data from $COMIN         ###
########################################################
mkdir -p $DATAgrib2
cd $DATA

if [[ $fhour = "000" ]] || [[ $fhour = "003" ]] ; then
  # GCIP
  modelfile=$COMIN/gfs.t${cyc2}z.gcip.f00.grib2
  cp $modelfile  $DATAgrib2/.
else
  # GFIP needs to be extracted from wafs file
  modelfile=$COMIN/gfs.t${cyc}z.wafs_icao.grb2f$fh
  $WGRIB2 $modelfile | egrep ":ICIP:|:EDPARM:|:ICESEV:|parm=37:" | grep -v ":70 mb:" | $WGRIB2 -i $modelfile -grib gfs.t${cyc}z.master.grb2f$fh
  #Convert to 0.25 degree for blending purpose
  opt1=' -set_grib_type same -new_grid_winds earth '
  opt21=' -new_grid_interpolation bilinear -if'
  opt22="(:ICESEV|parm=37):"
  opt23=' -new_grid_interpolation neighbor -fi '
  opt3=' -set_bitmap 1 -set_grib_max_bits 16 '
  newgrid="latlon 0:1440:0.25 90:721:-0.25"

  $WGRIB2 gfs.t${cyc}z.master.grb2f$fh \
          $opt1 $opt21 $opt22 $opt23 $opt3 \
          -new_grid $newgrid $DATAgrib2/gfs.t${cyc}z.wafs_0p25.grb2f$fh

#  cat $COMIN/gfs.t${cyc}z.wafs_0p25.f${fh}.grib2 >> $DATAgrib2/gfs.t${cyc}z.wafs_0p25.grb2f$fh

fi

# Skip plotting if forecast hour is greater than 36
if [[ $fhour > 036 ]] ; then
  exit 0 
fi

########################################################
###  plot: Step 2: plots.                            ###
########################################################
remoteServer=ymao@emcrzdm.ncep.noaa.gov

DATAplot=$DATAROOTplot/plot.f$fh
mkdir -p $DATAplot
cd $DATAplot
rm $DATAplot/*

if [[ $fhour == "000" ]] || [[ $fhour == "003" ]] ; then
  # copy GCIP data
  cp $DATAgrib2/*t${cyc2}z.gcip.f00.grib2 .
else
  # copy GFIP data
  cp $DATAgrib2/gfs.t${cyc}z.wafs_0p25.grb2f$fh .
fi
for grb2file in `ls` ; do
   severity=severity

   sh $HOMEsave/grads/plotWafs.sh original potential $grb2file
   sh $HOMEsave/grads/plotWafs.sh original $severity  $grb2file
   sh $HOMEsave/grads/plotWafs.sh conus  potential $grb2file
   sh $HOMEsave/grads/plotWafs.sh conus  $severity  $grb2file
   sh $HOMEsave/grads/plotWafs.sh hawaii  potential $grb2file
   sh $HOMEsave/grads/plotWafs.sh hawaii  $severity  $grb2file
   sh $HOMEsave/grads/plotWafs.sh alaska  potential $grb2file
   sh $HOMEsave/grads/plotWafs.sh alaska  $severity  $grb2file

   if [[ $grb2file =~ "wafs" ]] ; then
       sh $HOMEsave/grads/plotWafs.sh original turbulence $grb2file
       sh $HOMEsave/grads/plotWafs.sh conus turbulence $grb2file
       sh $HOMEsave/grads/plotWafs.sh hawaii turbulence $grb2file
       sh $HOMEsave/grads/plotWafs.sh alaska turbulence $grb2file
   fi
done

# Don't upload CAT MWT to rzdm web site
rm *cat.png
rm *mwt.png

# Mark this job for $fh is finished 
echo $PDY $cyc $fh >> $TMP/GCIP_GFIP_GTG_2_rzdm.working/GCIP_GFIP_GTG_2_rzdm.list

exit 0
