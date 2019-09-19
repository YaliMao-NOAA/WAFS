#!/bin/sh
if [ $# -lt 1 -o $# -gt 2 ] ; then 
echo "Usage: $0 PDY [PDY2]";exit 1 
fi
set -xeua
FINC=${FINC:-12}
SCRIPTS=/meso/save/Geoffrey.Manikin/wafs/
COPYGB=${COPYGB:-/nwprod/util/exec/copygb}
NDATE=${NDATE:-${UTIL:-/nwprod/util/exec}/ndate}

PDY1=$1;PDY2=$1; [ $# -eq 2 ] && PDY2=$2
if [ ${#PDY1} -ne 8 -0 ${#PDY2} -ne 8 ] ; then
	echo invalid $0 input $*
	echo "Usage: $0 PDY [PDY2]";exit 1 
	exit 1
fi
PDY=$PDY2
while [ $PDY -ge $PDY1 ] ; do
DATA=/stmpp1/$LOGNAME/faa.$PDY
if [ ! -d $DATA ] ; then mkdir -p $DATA;fi
cd $DATA

# run scripts for cdate
# ----------------------
echo 'before 00'
#/meso/save/Geoffrey.Manikin/wafs/grid2gdas.sh  ${PDY}00 gdas 
echo 'before 06'
#/meso/save/Geoffrey.Manikin/wafs/grid2gdas.sh  ${PDY}06 gdas 
echo 'before 12'
#/meso/save/Geoffrey.Manikin/wafs/grid2gdas.sh  ${PDY}12 gdas 
echo 'before 18'
#/meso/save/Geoffrey.Manikin/wafs/grid2gdas.sh  ${PDY}18 gdas 
echo 'before wafs00'
#/meso/save/Geoffrey.Manikin/wafs/grid2wafs_test.sh ${PDY}00 gdas 
echo 'before wafs12'
/meso/save/Geoffrey.Manikin/wafs/grid2wafs_test.sh ${PDY}12 gdas 

PDY=$($NDATE -24 ${PDY}00|cut -c1-8)

done
