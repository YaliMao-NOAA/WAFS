#! /bin/sh
set -xeua
FINC=${FINC:-12}
SCRIPTS=/meso/save/wx20mg/wafs
COPYGB=${COPYGB:-/nwprod/util/exec/copygb}
NDATE=${NDATE:-${UTIL:-/nwprod/util/exec}/ndate}

PDY=${PDY:-`date -u '+%Y%m%d'`}
HH=${HH:-`date -u '+%H'`}
HH=$((HH/FINC*FINC));if [ `expr $HH : '.*'` -eq 1 ] ; then HH=0$HH;fi
cdate=$PDY$HH
echo $cdate

DATA=/stmpp1/$LOGNAME/faa.$PDY
if [ ! -d $DATA ] ; then mkdir -p $DATA;fi
cd $DATA

# run scripts for cdate
# ----------------------
/meso/save/wx20mg/wafs/grid2wafs.sh $cdate   gdas 
/meso/save/wx20mg/wafs/grid2gdas.sh  $cdate   gdas 
cdatem6=`$NDATE -6 $cdate`
/meso/save/wx20mg/wafs/grid2gdas.sh  $cdatem6 gdas 

cdate=`$NDATE $FINC $cdate`
PDY=`echo $cdate|cut -c1-8`
HH=`echo $cdate|cut -c9-10`

# submit job for next time in future
# ----------------------------------

for fhr in 00 12 ;do
	future_hh[fhr]=7
	future_mm[fhr]=15
done

jdate=`$NDATE $((future_hh[HH]+FINC)) $cdate`
jobtime="$jdate${future_mm[HH]}" 

v=""
if [ ${LOADLBATCH:-NO} = YES ] ; then
	TMPDIR=$DATA
	v='-v'
fi

#if [ ${SUBMIT:-YES} = YES ] ; then
#/u/wx23bk/bin/sub $v \
#	-e DATA,PDY,HH,FINC -j gdas$PDY$HH -p 1 -q 1 -w $jobtime $SCRIPTS/faa_qsub.sh
#fi
