#!/bin/bash

########################################################
# WAFS Verification package
# a sequential job
# Suggestion: allow 3 hours for each run to complete
#
# Modification needed later on:
# COMROOT after each implementation
# add cyc to $COMROOT related locations in jobs/JVERF_GRID2GRID_WAFS after 2019 GFS implementation
########################################################

# 1) /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/wafs_run/run_JVERF_GRID2GRID_WAFS.sh
# 2) HOMEverf_g2g=$HOMEgit/verf_g2g.v3.0.12
#      jobs/JVERF_GRID2GRID_WAFS
#      scripts/exverf_g2g_wafs.sh.ecf
#      / ush/verf_g2g_get_wafs2.sh
#      | ush/verf_g2g_get_wafs.sh
#      \ ush/verf_g2g_wafs.sh
#        / verf_g2g_prepg2g_grib2.sh
#        \ verf_g2g_fitsg2g_grib2.sh
#      !!! needs compiling !!! $HOMEverf_g2g/exec/verf_g2g_icing_convert.$MACHINE
#      !!! needs compiling !!! $HOMEverf_g2g/exec/verf_g2g_grid2grid_grib2.$MACHINE

########################################################
# Only run the script on develop machine:
# 1st letter of developMachine & thisMachine must match
########################################################
if [[ ! `hostname` =~ ^tfe ]] ; then
  developMachine=`cat /etc/dev`
  thisMachine=`hostname` 
  if [ `echo $developMachine | cut -c 1-1` != `echo $thisMachine | cut -c 1-1` ] ; then
      exit
  fi
fi


#*******************************************************
# It is loaded by .bashrc as well
if [[ `hostname` =~ ^tfe ]] ; then
   . /scratch4/NCEPDEV/global/noscrub/Yali.Mao/git/save/envir_setting.sh
else
   . /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/envir_setting.sh
fi

set -x

date

########################################################
#### arguments, cyc, vday                           ####
########################################################

export envirp=$1   # prod or para, forecast product
export envirv=$2   # prod or para, valication data

# cyc doesn't matter for verification.
# export cyc=${cyc:-12}


########################################################
#### inputs for US forecast and GCIP                #### 
########################################################

if [[ `hostname` =~ ^tfe ]] ; then

  # On Theia, data are from HPSS, which are available at least 2 days ago.
  # On Theia, gcip needs to be archived one day earlier then extracted later
  # On Theia, data are from HPSS, input data need to be extracted and have the same COMROOT
  # On Theia, only do prod.prod verification

  COMIN=$TMP/wafs.vrfy.com
  rm -rf $COMIN
  mkdir -p $COMIN

  ystday=`$NDATE -24 | cut -c1-8`

  # Archive real time gcip of yesterday
  cd $COMROOT/gfs/prod
  if [[ -z $vday ]] ; then
      # only archive data in near 'real-time'. When vday is assigned a value, it's for history verification
      htar -Pcvf /NCEPDEV/emc-global/5year/Yali.Mao/gcip/$ystday.tar ./gfs.$ystday/*/*gcip*
  fi

  if [[ -z $vday ]] ; then
      # only archive data in near 'real-time'. When vday is assigned a value, it's for history verification
      # Archive real time GFIP (high resolution) of yesterday
      for cyc in 00 06 12 18 ; do
	  mkdir -p $COMIN/gfs.$ystday/$cyc
	  cd $COMIN/gfs.$ystday/$cyc
	  for fh in 06 09 12 15 18 21 24 27 30 33 36 ; do
	      ff="$(printf "%03d" $(( 10#$fh )) )"
	      masterfile=$COMROOT/gfs/prod/gfs.$ystday/$cyc/gfs.t${cyc}z.master.grb2f$ff
	      $WGRIB2 $masterfile | grep ":ICIP:\|:ICSEV:" | $WGRIB2 -i $masterfile -grib gfs.t${cyc}z.master.grb2f$ff
	  done
      done
      cd $COMIN
      htar -Pcvf /NCEPDEV/emc-global/5year/Yali.Mao/gfip/$ystday.tar ./gfs.$ystday/*/*master*
  fi

  # verfication is 2 days before today unless it's predefined.
  export vday=${vday:-`$NDATE -48 | cut -c1-8`}

  # For archived UKMET and CIP/FIP DCOM data
  mkdir -p $COMIN/$vday

  ### extract GCIP
  cd $COMIN
  htar -xvf  /NCEPDEV/emc-global/5year/Yali.Mao/gcip/$vday.tar
  ### extract GFIP (high resolution)
  htar -xvf  /NCEPDEV/emc-global/5year/Yali.Mao/gfip/$vday.tar

  # extract US UK BLENDED icing forecast and CIP/FIP, U/V/T forecast and analysis
  year=`echo $vday | cut -c1-4`
  yearmonth=`echo $vday | cut -c1-6`
  for cyc in 00 06 12 18 ; do
    ### extract u/v/t analysis
    cd $COMIN
    tarball=/NCEPPROD/hpssprod/runhistory/rh$year/$yearmonth/$vday/gpfs_dell1_nco_ops_com_gfs_prod_gfs.${vday}_${cyc}.gfs_pgrb2.tar
    htar -xvf $tarball ./gfs.$vday/$cyc/gfs.t${cyc}z.pgrb2.0p25.anl 
    for fh in 06 09 12 15 18 21 24 27 30 33 36 ; do
      ### extract u/v/t forecast
      cd $COMIN
      tarball=/NCEPPROD/hpssprod/runhistory/rh$year/$yearmonth/$vday/gpfs_dell1_nco_ops_com_gfs_prod_gfs.${vday}_${cyc}.gfs_pgrb2.tar
      htar -xvf $tarball ./gfs.$vday/$cyc/gfs.t${cyc}z.pgrb2.0p25.f0$fh

      ### extract US and BLENDED icing forecast
      cd $COMIN
      tarball=/NCEPPROD/hpssprod/runhistory/rh$year/$yearmonth/$vday/gpfs_dell1_nco_ops_com_gfs_prod_gfs.${vday}_${cyc}.gfs.tar
      htar -xvf $tarball ./gfs.$vday/$cyc/WAFS_blended_${vday}${cyc}f${fh}.grib2 ./gfs.$vday/$cyc/gfs.t${cyc}z.wafs_grb45f${fh}.grib2

      ### extract UK icing forecast
      cd $COMIN/$vday
      tarball=/NCEPPROD/hpssprod/runhistory/rh$year/$yearmonth/$vday/dcom_us007003_${vday}.tar
      htar -xvf $tarball ./wgrbbul/ukmet_wafs/EGRR_WAFS_unblended_${vday}_${cyc}z_t${fh}.grib2
    done
  done

  ### extract CIP/FIP
  cd $COMIN/$vday
  tarball=/NCEPPROD/hpssprod/runhistory/rh$year/$yearmonth/$vday/dcom_us007003_${vday}.tar
  htar -xvf $tarball ./wgrbbul/adds_cip/ADDS_CIP_* ./wgrbbul/adds_fip/ADDS_FIP_*

  export GCIPDIR=$COMIN/gfs
  export COMINGFIP=$COMIN/gfs

  export COMINGFSV=$COMIN/gfs
  export COMINGFSP=$COMIN/gfs

  export COMINUS=$COMIN/gfs
  export COMINBLND=$COMIN/gfs

  export COMINUK=$COMIN

  export CIPDIR=$COMIN
  export COMINFIP=$COMIN

else

  # verfication is 1 day before today unless it's predefined.
  export vday=${vday:-`$NDATE -24 | cut -c1-8`}


  # GFS forecast
  if [ $envirp = prod ] ; then
      export COMROOT=$COMROOT
  elif [ $envirp = para ] ; then
      export COMROOT=/gpfs/hps/nco/ops/com
  fi
  export envir=$envirp

  # GFS observation data
  if [ $envirv = prod ] ; then
      # global icing
      export GCIPDIR=$COMROOT/gfs/$envirv/gfs

      # u/v/t
      export COMINGFSV=$COMROOT/gfs/$envirv/gfs

  elif [ $envirv = para ] ; then
      # global icing
      # my own parallel, rerun GCIP in case satellite changes between GFS implemetations
      # export GCIPDIR=$TMP/fv3_para_prod/gfs
      # NCO parallel
      export GCIPDIR=/gpfs/hps/nco/ops/com/gfs/$envirv/gfs

      # u/v/t
      export COMINGFSV=/gpfs/hps/nco/ops/com/gfs/$envirv/gfs

  fi
fi

########################################################
#### outputs for verification                       #### 
########################################################

export DATA=$TMP/wafs.vrfy_${envirp}.${envirv}_working/$vday
rm -f $DATA/*

# Re-organize data as inputs for verification
export COM_OUT=$TMP/wafs.vrfy_${envirp}.${envirv}_grib2

export COMVSDB=$TMP/wafs.vrfy_${envirp}.${envirv}_vsdb

export jlogfile=/$DATA/jlogfile

########################################################
### send control
########################################################
export SENDDBN=NO
export SENDECF=NO

########################################################
### RUN verification package                        #### 
########################################################

export HOMEverf_g2g=$HOMEgit/verf_g2g.v3.0.12

cp $HOMEverf_g2g/exec/verf_g2g_icing_convert.$MACHINE   $HOMEverf_g2g/exec/verf_g2g_icing_convert
cp $HOMEverf_g2g/exec/verf_g2g_grid2grid_grib2.$MACHINE $HOMEverf_g2g/exec/verf_g2g_grid2grid_grib2

sh $HOMEverf_g2g/jobs/JVERF_GRID2GRID_WAFS


########################################################
### Archive vsdb results to HPSS                    ####
########################################################

cd $TMP
day=`echo $vday | cut -c1-6`
htar -Pcvf /NCEPDEV/emc-global/5year/Yali.Mao/wafs_vsdb/${envirp}.${envirv}/$day/$vday.vsdb.tar `find wafs.vrfy_${envirp}.${envirv}_vsdb/wafs -name "*$vday*" -size +1c -type f`

########################################################
### transfer vsdb to tempest and save to            ####
### /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/vsdb  #### 
########################################################
dataDir=wafs.vrfy_${envirp}.${envirv}_vsdb/wafs

cd $TMP
allfilesize=`du -c $dataDir/*$vday* | tail -1| cut -f 1`

if [[ $allfilesize  -eq 0 ]] ; then
  echo "No ${envirp}.${envirv} vsdb result is generated. Please check."
  echo "No ${envirp}.${envirv} vsdb result is generated on $vday." | mailx -s "VSDB verification is not generated." yali.mao@noaa.gov
else
  # to tempest
  if [[ ! `hostname` =~ ^tfe ]] ; then
    remote=/gmb/wd20ym/vsdb
    remoteServer=wd20ym@tempest
    # rsync -ravP --min-size=1 $TMP/$dataDir/. ${remoteServer}:${remote}/.
  fi

  # to wcoss/save folder
  mkdir -p $VSDBsave/wafs/${envirp}.${envirv}
  rsync -avP --min-size=1 $TMP/$dataDir/. $VSDBsave/wafs/${envirp}.${envirv}/.
fi

date
exit 0
