#!/bin/ksh
#@ account_no=SREF-T2O
#@ output = out.post_bin
#@ error = err.post_bin
##@ arguments = 20091123 12
##@ executable= /meso/save/wx20bz/vsref/exe/ruc_grb2_to_grib1_prod.sh
#@ job_type = parallel
#@ class = dev
#@ total_tasks = 1
#@ blocking = unlimited
#@ wall_clock_limit = 00:20:00
#@ resources = ConsumableCpus(1)ConsumableMemory(3000mb)
#@ queue

# usage: convert_cip.sh 20120221
if [ $# -lt 1 ] ; then
  echo "usage: convert_cip.sh YYYYMMDD [data source folder]"
  exit
fi


#export TODAY=`date +%Y%m%d`
export DAY=$1
UTIL=/nwprod/util/exec

if [ $# -eq 2 ] ; then
  COMIN=$2
else
  COMIN=/dcom/us007003/$DAY/wgrbbul/adds_cip
fi


DATA=/ptmpp1/`whoami`/cip.$DAY
mkdir -p $DATA
cd $DATA
rm -f $DATA/${head}*.f00  $DATA/x.* 

output=cipAWC

YYMMDD=`echo ${DAY} | cut -c 3-8`
for cyc in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 ; do
  for lvl in 30 32 33 34 36 38 39 41 43 45 46 48 50 53 55 57 60 62 65 67 70 73 75 78 81 84 85 90 95 93 ; do
    # YIXA - CIP 20km Total Icing Probality
    # YJXA - CIP 20km SLD
    # YLXA - CIP 20km Severity
    for head in YIXA YJXA YLXA ; do
      file=$COMIN/${head}${lvl}.grb
      if [ -e $file ] ; then
        search=${YYMMDD}${cyc}  
	$UTIL/wgrib $file |grep "d=${search}:" |/$UTIL/wgrib -i -grib $file -o x.$lvl
	cat x.$lvl >> ${output}.t${cyc}z.f00
      else
        echo $file does not exist
      fi
    done
  done 
  rm -f x.*
done



