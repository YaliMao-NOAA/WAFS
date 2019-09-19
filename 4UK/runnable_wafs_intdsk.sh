#!/bin/sh
#
#  UTILITY SCRIPT NAME :  wafs_intdsk.sh
#               AUTHOR :  Boi Vuong 
#         DATE WRITTEN :  06/12/2000
#
#  Abstract:  This utility script produces the GFS WAFS  
#             for grib grids i37,38,39,40,41,42,43 and 44
#             for international desk. These grid files
#             send to TOC.
#
#     Input:  1 argument is passed to this script.
#             1st argument - Forecast Hour (00 to 120)
#
echo "History: June  2000 - First implementation of this utility script"
echo " "
#

#---------------------------------------------------------
# To make this script run directly, specifiy the following:
#  - Y Mao
#export PDY=`/nwprod/util/exec/ndate -24 | cut -c 1-8`
export PDY=20130910
export DATA=/ptmpp1/`whoami`/4UK
echo $DATA
export COMOUT=$DATA/wafs.$PDY
export parmlist=/nwprod/util/parm/grib_wafsgfs_intdsk
#---------------------------------------------------------

set +x
fcsthrs_list="$1"
num=$#

if test $num -ne 1
then
   echo ""
   echo "   Usage: wafs_intdsk.sh  forecast_hour"
   echo ""
   echo "   Example:"
   echo '           wafs_intdsk.sh  "06 12 18 24" '
   echo ""
   echo ""
   exit 16
fi


set -x

mkdir -p $DATA
mkdir -p $COMOUT
cd $DATA

#####################################
# Define Script/Exec and Variables
#####################################

export jlogfile=${jlogfile:-jlogfile}
export envir=${envir:-prod}

export GRBIDX=/nwprod/util/exec/grbindex
export WGRIB2=/nwprod/util/exec/wgrib2
export CNVGRIB=/nwprod/util/exec/cnvgrib
export EXECutil=${EXECutil:-/nwprod/util/exec}
export PARMutil=${PARMutil:-/nwprod/util/parm}
export SENDCOM=${SENDCOM:-NO}
export SENDDBN=${SENDDBN:-NO}
export RUN=${RUN:-gfs}
export NET=${NET:-gfs}
export COMIN=${COMIN:-/com/$NET/$envir/$NET.$PDY}

echo " ------------------------------------------"
echo " BEGIN MAKING ${NET} WAFS PRODUCTS"
echo " ------------------------------------------"

msg="Enter Make WAFS utility."
postmsg "$jlogfile" "$msg"
echo " "


for cyc in 00 # 06 12 18
do

export cyc
export cycle=t${cyc}z

for hour in $fcsthrs_list 
do 
   if test ! -f grbf${hour}
   then
      cp $COMIN/${RUN}.${cycle}.master.grbf${hour} grbf${hour}
   fi

   for gid in 37 38 39 40 41 42 43 44;
#   for gid in 45;
   do
      $EXECutil/wgrib grbf${hour} | grep -F -f $parmlist | $EXECutil/wgrib -i -grib -o tmpfile grbf${hour}
      $EXECutil/copygb -g${gid} -i2 -x tmpfile wafs${NET}${gid}.t${cyc}z.gribf${hour}
#      /global/save/Mark.Iredell/neighbor-pole/copygb.src03/copygb -g${gid} -i2 -x tmpfile wafs${NET}${gid}.t${cyc}z.gribf${hour}
     
      ##########################
      # Convert to grib2 format
      ##########################
      $CNVGRIB -g12 -p40 wafs${NET}${gid}.t${cyc}z.gribf${hour} wafs${NET}${gid}.t${cyc}z.gribf${hour}.grib2
      $WGRIB2 wafs${NET}${gid}.t${cyc}z.gribf${hour}.grib2 -s >wafs${NET}${gid}.t${cyc}z.gribf${hour}.grib2.idx
 
      mv wafs${NET}${gid}.t${cyc}z.gribf${hour}   $COMOUT
      mv wafs${NET}${gid}.t${cyc}z.gribf${hour}.grib2 $COMOUT
      mv wafs${NET}${gid}.t${cyc}z.gribf${hour}.grib2.idx $COMOUT

      chmod 775 $COMOUT/wafs${NET}${gid}.t${cyc}z.gribf${hour}
      if [ "$SENDDBN" = "YES" ]
      then
         $DBNROOT/bin/dbn_alert MODEL GFS_WAFS_INT $job $COMOUT/wafs${NET}${gid}.t${cyc}z.gribf${hour}
         $DBNROOT/bin/dbn_alert MODEL GFS_WAFSG  $job $COMOUT/wafs${NET}${gid}.t${cyc}z.gribf${hour}

         if [ $SENDDBN_GB2 = YES ]
         then

         $DBNROOT/bin/dbn_alert MODEL GFS_WAFSG_GB2 $job $COMOUT/wafs${NET}${gid}.t${cyc}z.gribf${hour}.grib2
         $DBNROOT/bin/dbn_alert MODEL GFS_WAFSG_GB2_WIDX $job $COMOUT/wafs${NET}${gid}.t${cyc}z.gribf${hour}.grib2.idx

         fi

      fi

 
      ##########################
      # check max wind
      ##########################
      /global/save/Yali.Mao/4UK/checkMaxWind.exe  $COMOUT/wafs${NET}${gid}.t${cyc}z.gribf${hour}       $gid >> checkMaxWind.txt1.$PDY 
      /global/save/Yali.Mao/4UK/checkMaxWind2.exe $COMOUT/wafs${NET}${gid}.t${cyc}z.gribf${hour}.grib2 $gid >> checkMaxWind.txt2.$PDY

   done # gid
   rm tmpfile grbf${hour}

done # forecast hour

done # CYC

msg="wafs_intdsk completed normally"
postmsg "$jlogfile" "$msg"

exit
