#!/bin/sh
################################################################################
####  UNIX Script Documentation Block
#                      .                                             .
# Script name:          grid2wafs.sh
#
# Script description: Creates wafs grib file from gdas anl / f06
#
# Author: Robert E. Kistler W/NP23 301-763-8000x7232 bkistler@ncep.noaa.gov
#
# Abstract: Creates merge wafs grib file from avn,ruc,or eta input grib file
#			Grids of the merge variables are extracted form the input grib file
#           by matching text strings with the WGRIB output.
#			The extracted grids are then interpolated to the selected wafs grid.
#           Precip is handled in a separate script
#
# Script history log:
# 2000-12-15 
# 2003-06-11 upgraded to hpss from hsm
#
# Usage: grid2wafs.sh file CDATE 
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
# interpolates from input grib grid to wafs grid
set -aux
CDATE=$1
rmdays=${RMDAYS:-7}
cdatem7=`$NDATE -$((24*rmdays)) $CDATE`
if [ ${#CDATE} -ne 10 ] ;then 
	echo "Usage: $0 YYYYMMDDHH gdas|gfs wafs_file";exit 1
fi
prodsuite=$2
pdy=`echo $CDATE|cut -c1-8`
cyc=t`echo $CDATE|cut -c9-10`z
if   [ $prodsuite = gfs ] ; then qual=gblavs
elif [ $prodsuite = gdas ] ; then
  if [ $pdy -ge 20170720 ] ; then
    qual=gdas
  else
    qual=gdas1
  fi
else echo "Usage: $0 CDATE gdas|gfs wafs_file";exit 1
fi

wafs_grib=wafs.zt.$CDATE
wafs_grib_old=wafs.zt.$cdatem7

>$wafs_grib
proddir=$COMROOT/gfs/prod/$prodsuite.$pdy

# make grib file of selected  wafs variables
#-------------------------------------------

>$wafs_grib.unsorted
for file in pgrbanl pgrbf06;do

	prodfile=$proddir/$qual.$cyc.$file
	if [ ! -s $prodfile ] ; then 
	        if [ ! -d $DATA ] ; then mkdir -p $DATA;fi
		proddir=$DATA
		prodfile=$proddir/$qual.$cyc.$file
		cd $proddir 
		$HOME_scripts/hpss_gdas_faa.sh $qual $pdy `echo $cyc|cut -c2-3`
		prodfile=$proddir/$qual.$cyc.$file
	fi
        $WGRIB -v $prodfile >wgrib
	f=wgrib ;if [ ! -s $f ]  ;then echo $f empty;exit 1;fi

	>wafs_wgrib

	# define array of selected variable names/levels
	# value match utility $WGRIB output
	# -----------------------------------------------------------

	for pmand in 1000 850 700 500 400 300 250 200 150 100 ;do 
		for var in TMP HGT ;do
			grep "${var}:${pmand} mb:" wgrib >> wafs_wgrib
		done
	done
	f=wafs_wgrib ;if [ ! -s $f ] ;then echo $f empty;exit 1;fi

	cat  wafs_wgrib| $WGRIB -v -i -grib -o wafs_grib $prodfile
	f=wafs_wgrib ;if [ ! -s $f ] ;then echo $f empty;exit 1;fi
	wafsgrid=36;while [ $((wafsgrid+=1)) -le 44 ] ;do
		$COPYGB -x -i ${COPYGB_IPOPT:-0}  -N $COPYGB_PARM -g $wafsgrid wafs_grib ${file}_$wafsgrid
		f=${file}_$wafsgrid ;if [ ! -s $f ] ;then echo $f empty;exit 1;fi
		cat ${file}_$wafsgrid>>$wafs_grib.unsorted
	done
	f=$wafs_grib.unsorted;if [ ! -s $f ] ;then echo $f empty;exit 1;fi

done
#   1:      2:         3:  4:     5:       6:     7:       8:
#284:1436104:d=00121700:TMP:100 mb:6hr fcst:NAve=0:grid=29h:
#286:1446044:d=00121700:HGT:100 mb:6hr fcst:NAve=0:grid=29h:
#306:1548020:d=00121700:TMP:100 mb:6hr fcst:NAve=0:grid=2ah:
#308:1557960:d=00121700:HGT:100 mb:6hr fcst:NAve=0:grid=2ah:
#328:1658212:d=00121700:TMP:100 mb:6hr fcst:NAve=0:grid=2bh:
#330:1667720:d=00121700:HGT:100 mb:6hr fcst:NAve=0:grid=2bh:
#350:1768836:d=00121700:TMP:100 mb:6hr fcst:NAve=0:grid=2ch:
#352:1778776:d=00121700:HGT:100 mb:6hr fcst:NAve=0:grid=2ch:

#wgrib $wafs_grib.unsorted -PDS -s |sed 's/PDS=............\(..\)[0-9a-f]*:*/grid=\1h:/' 
#echo "break break 0"
#wgrib $wafs_grib.unsorted -PDS -s |sed 's/PDS=............\(..\)[0-9a-f]*:*/grid=\1h:/' | \
#	sed -e s/grid=25h/grid=5h/ -e s/grid=26h/grid=6h/ -e s/grid=27h/grid=7h/ -e s/grid=28h/grid=8h/ \
#		-e s/grid=29h/grid=1h/ -e s/grid=2bh/grid=3h/ -e s/grid=2ch/grid=4h/ -e s/grid=2ah/grid=2h/ |\
#	sort -t: -k6,6ir -k4,4 -k5.1,5.4rn -k8,8  |  \
#	sed -e s/grid=5h/grid=25h/ -e s/grid=6h/grid=26h/ -e s/grid=7h/grid=27h/ -e s/grid=8h/grid=28h/ \
#		-e s/grid=1h/grid=29h/ -e s/grid=3h/grid=2bh/ -e s/grid=4h/grid=2ch/ -e s/grid=2h/grid=2ah/ 
#echo "break break 1"

$WGRIB $wafs_grib.unsorted -PDS -s |sed 's/PDS=............\(..\)[0-9a-f]*:*/grid=\1h:/' | \
	sed -e s/grid=25h/grid=5h/ -e s/grid=26h/grid=6h/ -e s/grid=27h/grid=7h/ -e s/grid=28h/grid=8h/ \
		-e s/grid=29h/grid=1h/ -e s/grid=2bh/grid=3h/ -e s/grid=2ch/grid=4h/ -e s/grid=2ah/grid=2h/ |\
	sort -t: -k6,6ir -k4,4 -k5.1,5.4rn -k8,8  |  \
	sed -e s/grid=5h/grid=25h/ -e s/grid=6h/grid=26h/ -e s/grid=7h/grid=27h/ -e s/grid=8h/grid=28h/ \
		-e s/grid=1h/grid=29h/ -e s/grid=3h/grid=2bh/ -e s/grid=4h/grid=2ch/ -e s/grid=2h/grid=2ah/ |
	$WGRIB $wafs_grib.unsorted -i -s -grib -o $wafs_grib

f=$wafs_grib;if [ ! -s $f ] ;then echo $f empty;exit 1;fi

#echo "break break 2"
#wgrib $wafs_grib         -PDS -s |sed 's/PDS=............\(..\)[0-9a-f]*:*/grid=\1h:/' | \
#	sed -e s/grid=25h/grid=5h/ -e s/grid=26h/grid=6h/ -e s/grid=27h/grid=7h/ -e s/grid=28h/grid=8h/ \
#		-e s/grid=29h/grid=1h/ -e s/grid=2bh/grid=3h/ -e s/grid=2ch/grid=4h/ -e s/grid=2ah/grid=2h/ |\
#	sort -t: -k6,6ir -k4,4 -k5.1,5.4rn -k8,8  |  \
#	sed -e s/grid=5h/grid=25h/ -e s/grid=6h/grid=26h/ -e s/grid=7h/grid=27h/ -e s/grid=8h/grid=28h/ \
#		-e s/grid=1h/grid=29h/ -e s/grid=3h/grid=2bh/ -e s/grid=4h/grid=2ch/ -e s/grid=2h/grid=2ah/ 

scp $wafs_grib $TARGET_rzdm

#ftpdir="/home/people/emc/ftp/mmb/mmbpll/wafs"
#. /u/Geoffrey.Manikin/.Utils
#export w1=wd20mg
#export w2=$rzdm
 
#ftp -n -v << EOF > /meso/save/Geoffrey.Manikin/wafs/wafsftp${cyc}.out
#open emcrzdm
#user $w1 $w2
#bin
#cd $ftpdir
#del $wafs_grib_old
#put $wafs_grib
#quit
#EOF

#rm $wafs_grib.unsorted ${file}_?? wafs_wgrib wgrib $wafs_grib
