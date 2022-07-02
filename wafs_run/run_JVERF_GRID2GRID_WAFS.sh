#!/bin/bash

########################################################
# WAFS Verification package
# a sequential job
# Suggestion: allow 3 hours for each run to complete
#
# Modification needed later on:
# COMROOT after each implementation
# add cyc to $COMROOT related locations in jobs/JVERF_GRID2GRID_WAFS (actually ush/verf_g2g_get_wafs.sh)  after 2019 GFS implementation
# add atmos to $COMROOT related locations in jobs/JVERF_GRID2GRID_WAFS (actually ush/verf_g2g_get_wafs.sh) after 2021 GFS implementation
########################################################

# 1) $HOMEsave/wafs_run/run_JVERF_GRID2GRID_WAFS.sh
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

export GCIPDIR=$COMIN/gfs
export COMINGFIP=$COMIN/gfs

export COMINGFSV=$COMIN/gfs # U/V/T analysis
export COMINGFSP=$COMIN/gfs # U/V/T forecast

export COMINUS=$COMIN/gfs
export COMINBLND=$COMIN/gfs

export COMINUK=$COMIN

export CIPDIR=$COMIN
export COMINFIP=$COMIN

########################################################
#### outputs for verification                       #### 
########################################################
DATA=${DATA:-$TMP/wafs.vrfy.${envirp}_${envirv}.working}
export DATA=$DATA/$vday
rm -f $DATA/*

# Re-organize data as inputs for verification
export COM_OUT=$TMP/wafs.vrfy.${envirp}_${envirv}.grib2

export COMVSDB=$TMP/wafs.vrfy.${envirp}_${envirv}.vsdb

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
