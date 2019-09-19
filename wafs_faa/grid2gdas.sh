#!/bin/sh
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:          grid2gdas.sh
#
# Script description: Creates wafs grib file from gdas anl / f06
#
# Author: Robert E. Kistler W/NP23 301-763-8000x7232 bkistler@ncep.noaa.gov
#
# Abstract: Creates a sub set of gdas anl + gdas anl at T+6
#
# Script history log:
# 2000-12-15 
# 2003-06-11 upgraded to hpss from hsm
#
# Usage: grid2gdas.sh gfs|gdas CDATE 
#
#   Input script positional parameters:
#                   file        :input precip grib filename
#                   wafsgrid    :wafs grid # (39 or 40)
#                   wafs.grib   :output merge wafs grib file
#                   wafs.index  :output merge wafs grib index file
#
#   Imported Shell Variables:
#                   WGRIB       :grib inventory utility
#                   NHOUR       :date manipulation utility
#                   GRBINDEX    :grib index file utilty
#                   COPYGB      :grib file interpolation utility
#                   COPYGB_PARM :grib file interpolation utility parameter file
#                   COPYGB_IPOPT :grib file interpolation option 
#
#   Exported Shell Variables:
#
#   Modules and files referenced:
#
#     programs   :
#                   WGRIB       :grib inventory utility
#                   NHOUR       :date manipulation utility
#                   GRBINDEX    :grib index file utilty
#                   COPYGB      :grib file interpolation utility
#
#     fixed data :  NONE
#
#     input data :
#                   file        :input precip grib filename
#
#     output data:
#                   wafs_grib   :merge wafs grib file
#                   wafs_index  :merge wafs grib index file
#
#     scratch    :
#                   wgrib       :WGRIB text output
#                   wafs_wgrib  :WGRIB text output matching merge selection
#                   wafs_grib   :WGRIB output grib file matching merge selection
#
# Remarks:  called by merge_grib.sh
#
#   Condition codes
#      0 - no problem encountered
#     >0 - some problem encountered
#
#  Control variable resolution priority
#    1 Command line argument.
#    2 Environment variable.
#    3 Inline default.
#
# Attributes:
#   Language: POSIX shell
#   Machine: IBM SP
#
####
################################################################################
#

if [ $# -ne 2 ] ; then
	echo "Usage: $0 CDATE gfs|gdas"
	exit 8
fi

# Variables are assigned by the caller
# WHO
# COPYGB
# WGRIB
# COPYGB_PARM
# COPYGB_IOPT
#
# TARGET_rzdm

mkdir -p $TMP/faa/wafs
rm $TMP/faa/wafs/*
cd $TMP/faa/wafs

# extracts selected grid variables/levels from input gib files 
set -aux
CDATE=$1
rmdays=${RMDAYS:-7}
cdatem7=`$NDATE -$((24*rmdays)) $CDATE`
if [ ${#CDATE} -ne 10 ] ;then 
	echo "Usage: $0 YYYYMMDDHH gfs|gdas wafs_file";exit 1
fi
prodsuite=$2
pdy=`echo $CDATE|cut -c1-8`
cyc=t`echo $CDATE|cut -c9-10`z
if   [ $prodsuite = gfs ] ; then qual=gfs
elif [ $prodsuite = gdas ] ; then
  if [ $pdy -ge 20170720 ] ; then
    qual=gdas
  else
    qual=gdas1
  fi
else echo "Usage: $0 CDATE gdas|gfs wafs_file";exit 1
fi

wafs_grib=gdas.zt.${CDATE}_tmp
wafs_grib2=gdas.zt.$CDATE
wafs_grib_old=gdas.zt.$cdatem7

>$wafs_grib
proddir=$COMROOT/gfs/prod/$prodsuite.$pdy

# make grib file of selected  wafs variables
#-------------------------------------------

file=pgrbanl
prodfile=$proddir/$qual.$cyc.$file
if [ ! -s $prodfile ] ; then 
        if [ ! -d $DATA ] ; then mkdir -p $DATA;fi
	proddir=$DATA
	prodfile=$proddir/$qual.$cyc.$file
	if [ ! -s $prodfile ] ; then
		cd $proddir
		$HOME_scripts/hpss_gdas_faa.sh $qual $pdy `echo $cyc|cut -c2-3` 
		prodfile=$proddir/$qual.$cyc.$file
	fi
fi
$WGRIB -v $prodfile >wgrib
f=wgrib ;if [ ! -s $f ]  ;then echo $f empty;exit 1;fi

>wafs_wgrib

# define array of selected variable names/levels
# value match utility $WGRIB output
# -----------------------------------------------------------

for var in TMP HGT ;do
	pmand=1050;while [ $((pmand-=50)) -ge 100 ] ; do  
		grep "${var}:${pmand} mb:" wgrib >> wafs_wgrib
	done
done
for var in TMP HGT PRES;do
	for pmand in 'tropopause';do 
		grep "${var}:${pmand}:" wgrib >> wafs_wgrib
	done
done
f=wafs_wgrib ;if [ ! -s $f ] ;then echo $f empty;exit 1;fi

cat  wafs_wgrib| $WGRIB -v -i -grib -o $wafs_grib $prodfile

$COPYGB -x -i ${COPYGB_IPOPT:-0}  -N $COPYGB_PARM $wafs_grib $wafs_grib2
scp $wafs_grib2 $TARGET_rzdm

#ftpdir="/home/people/emc/ftp/mmb/mmbpll/wafs"
#. /u/Geoffrey.Manikin/.Utils
#export w1=wd20mg
#export w2=$rzdm

#ftp -n -v << EOF > /meso/save/Geoffrey.Manikin/wafs/gdasftp${cyc}.out
#open emcrzdm
#user $w1 $w2
#bin
#cd $ftpdir
#del $wafs_grib_old
#put $wafs_grib2
#quit
#EOF

cp $wafs_grib wafs_hold
rm  wafs_wgrib wgrib $wafs_grib
#return
