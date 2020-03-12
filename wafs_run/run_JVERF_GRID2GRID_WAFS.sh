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


set -xa

date


########################################################
#### inputs for US forecast and GCIP                #### 
########################################################

if [[ `hostname` =~ ^h ]] ; then

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

export DATA=$DATA/$vday
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
### Send signal to archive vsdb results to HPSS     ####
########################################################
echo > $DATA/$vday

date
exit 0
