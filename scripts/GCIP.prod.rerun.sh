#!/bin/sh

########################################################
# In any case that a geostationary satellite is changed
# between GFS implementations, GCIP will lose satellite
# information of that area
# 
# later on to be modified:
# Remove 2 digits conversion in JGFS_WAFS_GCIP after GFS 2019 implementation
# COMINgfs changes to new location after GFS 2019 implementation
########################################################

# 1) $HOMEsave/wafs_run/run_WAFS_GCIP.driver.$MACHINE
# 2) HOMEgfs=$HOMEgit/EMC_wafs_branch
#      jobs/JGFS_WAFS_GCIP
#      /${SCRIPTSgfs}/exgfs_wafs_gcip.sh.ecf 000
#      \${SCRIPTSgfs}/exgfs_wafs_gcip.sh.ecf 003
#      !!! needs compiling!!! $EXECgfs/wafs_gcip

#*******************************************************
# It is loaded by .bashrc as well
. /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/envir_setting.sh

set -xa

# cyc and hb (hours back) are exported by the caller
date
export PDY=`$NDATE -$hb | cut -c1-8`


export DATA=$TMP/gcip.prod_rerun_working_$cyc
rm -r $DATA
mkdir -p $DATA
cd $DATA

COMOUT=$TMP/gcip.prod_rerun/gfs.$PDY

HOMEgfs=$HOMEgit/EMC_wafs_branch

COMINgfs=/gpfs/hps/nco/ops/com/gfs/para/gfs.$PDY

cp $HOMEsave/wafs_run/run_WAFS_GCIP.driver.$MACHINE .

#=======================================#
# needs to remove after 2019 GFS implementation
#=======================================#
cp $HOMEgfs/parm/wafs/wafs_gcip_gfs.cfg .
sed -e "s|name = FV3|name = GFS|" \
    -i wafs_gcip_gfs.cfg
cp $HOMEgfs/jobs/JGFS_WAFS_GCIP .
sed -e "s|exgfs_wafs_gcip.sh.ecf 000|exgfs_wafs_gcip.sh.ecf 00|" \
    -e "s|exgfs_wafs_gcip.sh.ecf 003|exgfs_wafs_gcip.sh.ecf 03|" \
    -e "s|export PARMgfs=.*|export PARMgfs=$DATA|" \
    -i JGFS_WAFS_GCIP
sed -e "s|sh \$HOMEgfs/jobs/JGFS_WAFS_GCIP|sh $DATA/JGFS_WAFS_GCIP|" \
    -i run_WAFS_GCIP.driver.$MACHINE
#=======================================#

sed -e "s|#BSUB -oo.*|#BSUB -oo $DATA/gcip.prod_rerun.${PDY}_${cyc}.o%J|" \
    -e "s|#BSUB -eo.*|#BSUB -eo $DATA/gcip.prod_rerun.${PDY}_${cyc}.o%J|" \
    -e "s|#BSUB -q .*|#BSUB -q debug|" \
    -e "s|export HOMEgfs=.*|export HOMEgfs=$HOMEgfs|" \
    -e "s|export COMINgfs=.*|export COMINgfs=$COMINgfs|" \
    -e "s|export COMOUT=.*|export COMOUT=$COMOUT|" \
    -e "s|export DATA=.*|export DATA=$DATA/gcip_working.$PDY$cyc|" \
    -e "/^#/! s/export PDY=.*/export PDY=$PDY/g" \
    -e "/^#/! s/export cyc=.*/export cyc=$cyc/g" \
    -i run_WAFS_GCIP.driver.$MACHINE

bsub < run_WAFS_GCIP.driver.$MACHINE
