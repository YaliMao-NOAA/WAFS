#!/bin/sh

# 1) Check whether satellite sensor numbers match GCIP configuration
# satellite sensor data: $DCOMROOT/*/mcidas/GLOBCOMPSSR.*00
# GCIP cfg: $HOMEgit/*/parm/wafs/wafs_gcip_gfs.cfg
#
# Satellite sensor numbers are written in grib2
#
# 2) Email warning if a new satellite sensor number is found
#
# 3) Plot satellite sensor numbers and save in png image

. $HOMEsave/envir_setting.sh
set -xa

DATA=$TMP/match.gcip.sat.cfg
rm -rf $DATA
mkdir -p $DATA
cd $DATA

wafsfolder=fork.implement2023

PDY=`$NDATE | cut -c1-8`
PDY=20230929
CC=06
inputfile=GLOBCOMPSSR.$PDY$CC
#cp $DCOMROOT/$PDY/mcidas/GLOBCOMPSSR.${PDY}00 GLOBCOMPSSR.${PDY}00
cp /lfs/h2/emc/vpppg/noscrub/yali.mao/satellite_test_2023sep/dcom/$PDY/mcidas/GLOBCOMPSSR.${PDY}$CC GLOBCOMPSSR.$PDY$CC
# cp `ls -t /gpfs/dell1/nco/ops/nw*/gfs.v*/parm/wafs/wafs_gcip_gfs.cfg | head -1` wafs_gcip_gfs.cfg
cp $HOMEgit/$wafsfolder/parm/wafs/wafs_gcip_gfs.cfg wafs_gcip_gfs.cfg

pgm=$HOMEsave/gcip_satellite/gcip_satellite

$pgm GLOBCOMPSSR.$PDY$CC wafs_gcip_gfs.cfg > out.txt

cfgss=`grep "cfg ss=" out.txt | sed s/.*=//g`
satss=`grep "sat ss=" out.txt | sed s/.*=//g`

for sat in $satss ; do
   if [[ ! $cfgss =~ $sat ]] ; then
       echo "Warning! New GCIP satellite! $sat" 
       echo "Warning! New GCIP satellite! $sat" | mailx -s "Please contact NCO. New GCIP satellite! $sat" yali.mao@noaa.gov
   fi
done

outputfile=`ls *grib2`

$G2CTL -verf $outputfile >  ${outputfile}.ctl
gribmap -i ${outputfile}.ctl

cp $HOMEsave/grads/cbar.gs .

cat <<EOF > tmp.gs
'open ${outputfile}.ctl'
'set gxout shaded'
'set clevs $satss'
'd pressfc'
'cbar.gs'
'printim satss.png png'
EOF

grads -lbxc tmp.gs
rm tmp.gs
