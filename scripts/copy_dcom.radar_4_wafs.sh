#!/bin/sh

CDATE=$1
if [ -z $CDATE ] ; then
    echo Usage: sh copy_dcom.radar_4_wafs.sh YYYYMMDDCC
    exit
fi
set -x
YY=`echo $CDATE | cut -c1-4`
YYMM=`echo $CDATE | cut -c1-6`
PDY=`echo $CDATE | cut -c1-8`
CYC=`echo $CDATE | cut -c9-10`
CYC2=$(( 3 + $CYC ))
CYC2="$(printf "%02d" $(( 10#$CYC2 )) )"
echo $PDY $CYC $CYC2

testfolder=satellite_test_2023sep/

com_radar=/lfs/h2/emc/vpppg/noscrub/yali.mao/${testfolder}com
dcomfolder=/lfs/h2/emc/vpppg/noscrub/yali.mao/${testfolder}dcom/$PDY


# copy radar data for GCIP
radarVersion=v1.2
mkdir -p $com_radar/radarl2/$radarVersion/radar.$PDY
cd $com_radar/radarl2/$radarVersion/radar.$PDY
cp $(compath.py radarl2/$radarVersion)/radar.$PDY/refd3d.t${CYC}z.grb2f00 .
cp $(compath.py radarl2/$radarVersion)/radar.$PDY/refd3d.t${CYC2}z.grb2f00 .

# copy satellite data for GCIP
mkdir -p $dcomfolder/mcidas
cd $dcomfolder/mcidas
cp $DCOMROOT/$PDY/mcidas/*$PDY$CYC .
cp $DCOMROOT/$PDY/mcidas/*$PDY$CYC .

# copy bufr files for GCIP
mkdir -p $dcomfolder/b000
cp $DCOMROOT/$PDY/b000/xx0* $dcomfolder/b000/.
cp $DCOMROOT/$PDY/b000/xx1* $dcomfolder/b000/.
cp -r $DCOMROOT/$PDY/b001 $dcomfolder/.
cp -r $DCOMROOT/$PDY/b003 $dcomfolder/.
cp -r $DCOMROOT/$PDY/b004 $dcomfolder/.
cp -r $DCOMROOT/$PDY/b007 $dcomfolder/.

# copy UK data for 2 blending jobs
mkdir -p $dcomfolder/wgrbbul/ukmet_wafs
cp $DCOMROOT/$PDY/wgrbbul/ukmet_wafs/*_${CYC}z* -p $dcomfolder/wgrbbul/ukmet_wafs/.
