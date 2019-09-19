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

# usage: convert_fip.sh 20120221
if [ $# -lt 1 ] ; then
  echo "usage: convert_cip.sh YYYYMMDD"
  exit
fi


#export TODAY=`date +%Y%m%d`
export DAY=$1
UTIL=/nwprod/util/exec

COMIN=/dcom/us007003/$DAY/wgrbbul/adds_fip

DATA=/ptmpp1/`whoami`/fip.$DAY
mkdir -p $DATA
cd $DATA
rm -f $DATA/${head}*.f00  $DATA/x.* 

output=fipAWC

YYMMDD=`echo ${DAY} | cut -c 3-8`
#for cyc in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 ; do
for cyc in 00 03 06 09 12 15 18 21 ; do
  for lvl in 30 32 33 34 36 38 39 41 43 45 46 48 50 53 55 57 60 62 65 67 70 73 75 78 81 84 85 90 95 93 ; do
    # YAW - FIP Icing probability
    # YAX - FIP SLD
    # YLX - FIP Icing Severity
    #    B - 1 hour
    #    C - 2 hour
    #    D - 3 hour
    #    G - 6 hour
    #    J - 9 hour     
    #    M - 12 hour
    for head in YAW YAX YLX ; do
      for fh in B C D G J M; do

	if [ $fh == 'B' ] ;then
	  hh="01"
	elif [ $fh == 'C' ] ;then
	  hh="02"
	elif [ $fh == 'D' ] ;then
	  hh="03"
	elif [ $fh == 'G' ] ;then
	  hh="06"
	elif [ $fh == 'J' ] ;then
	  hh="09"
	elif [ $fh == 'M' ] ;then
	  hh="12"
	fi

        file=$COMIN/${head}${fh}${lvl}.grb
	if [ -e $file ] ; then
          search=${YYMMDD}${cyc}  
          $UTIL/wgrib $file |grep "d=${search}:" |/$UTIL/wgrib -i -grib $file -o x.$lvl
          cat x.$lvl >> ${output}.t${cyc}z.f${hh}
	else
          echo $file does not exist
	fi
      done
    done
  done 
  rm -f x.*
done



