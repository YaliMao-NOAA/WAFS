#!/bin/sh

# 1) Check whether satellite sensor numbers match GCIP configuration
# satellite sensor data: $DCOMROOT/us007003/*/mcidas/GLOBCOMPSSR.*00
# GCIP cfg: /gpfs/dell1/nco/ops/nw*/gfs.v*/parm/wafs/wafs_gcip_gfs.cfg
#
# Satellite sensor numbers are written in grib2
#
# 2) Email warning if a new satellite sensor number is found
#
# 3) Plot satellite sensor numbers and save in png image

. /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/envir_setting.sh
set -xa

DATA=$TMP/match.gcip.sat.cfg
rm -rf $DATA
mkdir -p $DATA
cd $DATA

PDY=`$NDATE | cut -c1-8`
cp $DCOMROOT/us007003/$PDY/mcidas/GLOBCOMPSSR.${PDY}00 GLOBCOMPSSR.${PDY}00
# cp `ls -t /gpfs/dell1/nco/ops/nw*/gfs.v*/parm/wafs/wafs_gcip_gfs.cfg | head -1` wafs_gcip_gfs.cfg
cp $HOMEgit/EMC_wafs_branch/parm/wafs/wafs_gcip_gfs.cfg wafs_gcip_gfs.cfg

pgm=$HOMEsave/gcip_satellite/gcip_satellite

$pgm GLOBCOMPSSR.${PDY}00 wafs_gcip_gfs.cfg > out.txt

cfgss=`grep "cfg ss=" out.txt | sed s/.*=//g`
satss=`grep "sat ss=" out.txt | sed s/.*=//g`

for sat in $satss ; do
   if [[ ! $cfgss =~ $sat ]] ; then
       echo "Warning! New GCIP satellite! $sat" 
       echo "Warning! New GCIP satellite! $sat" | mailx -s "Please contact NCO. New GCIP satellite! $sat" yali.mao@noaa.gov
   fi
done


$G2CTL -verf sat${PDY}00.grib2 >  sat${PDY}00.grib2.ctl
gribmap -i sat${PDY}00.grib2.ctl

cp $HOMEsave/grads/cbar.gs .

cat <<EOF > tmp.gs
'open sat${PDY}00.grib2.ctl'
'set gxout shaded'
'set clevs $satss'
'd pressfc'
'cbar.gs'
'printim satss.png png'
EOF

grads -lbxc tmp.gs
rm tmp.gs
