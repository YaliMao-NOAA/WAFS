#!/bin/sh
TMPDIR=/nfstmp/wx23bk/ftp.$$
if [ ! -s $TMPDIR ]  ; then mkdir -p $TMPDIR ;fi
if [ $# -ne 3 ] ; then echo "Usage: $0 cdate ndays ftpdir";exit 1 ;fi
set -ue
cdatez=$1
ndays=$2
ftpdir=$3
cdate=`/nwprod/util/exec/ndate -$((24*ndays)) $cdatez`

ftp -vi ftp.ncep.noaa.gov <<EOF |grep $ftpdir >$TMPDIR/ftp_filelist
ls $ftpdir
quit
EOF
#check for file older then ndays
#-------------------------------

rmlist=""
nlines=`cat $TMPDIR/ftp_filelist|wc -l`
n=0;while [ $((n+=1)) -le $nlines ] ;do
	line=`sed -n $n,${n}p $TMPDIR/ftp_filelist` 
	filename=`basename $line`
	filedate=`echo $filename|awk -F. '{print $3}'`
	if [ `echo $filedate|grep "[12][90][0-9][0-9][01][0-9][0123][0-9][01][0628]"` -ne $filedate ]; then echo "filedate = $filedate -ne date"; exit 1 ;fi
	if [ $filedate -lt $cdate ] ; then rmlist="$rmlist $filename";fi
done
if [ -n "$rmlist" ] ; then
ftp -vi  ftp.ncep.noaa.gov <<EOF 
cd $ftpdir
mdel $rmlist
quit
EOF
fi
while [ $cdate -le $cdatez ] ;do  
	set +e;grep $cdate $TMPDIR/ftp_filelist;set -e
	if [ $? -ne 0 ] ; then 
		pdy=`echo $cdate |cut -c1-8`;hh=`echo $cdate |cut -c9-10`
		SUBMIT=NO PDY=$pdy HH=$hh /nfsuser/g01/wx23bk/fnl/faa_qsub.sh 
	fi
	cdate=`/nwprod/util/exec/ndate ${FINC:-12} $cdate`
done
rm -f -r $TMPDIR

