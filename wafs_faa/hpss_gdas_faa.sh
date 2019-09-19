#!/bin/sh
if [ $# -ne 3 ] ; then echo "Usage: $0 pdy hh";exit 1 ;fi
set -xeua
qual=$1
pdy=$2
hh=$3

yyyy=`echo $pdy |cut -c1-4`
mm=`echo $pdy |cut -c5-6`
if [ $pdy$hh -ge 2017072000 ] ; then
  tarfile=/NCEPPROD/hpssprod/runhistory/rh$yyyy/$yyyy$mm/$pdy/gpfs_hps_nco_ops_com_gfs_prod_gdas.$pdy$hh.tar
elif [ $pdy$hh -ge 2016060100 ] ; then
  tarfile=/NCEPPROD/hpssprod/runhistory/rh$yyyy/$yyyy$mm/$pdy/com2_gfs_prod_gdas.$pdy$hh.tar
elif [ $pdy$hh -ge 20050101 ] ; then
  tarfile=/hpssprod/runhistory/rh$yyyy/$yyyy$mm/$pdy/com_gfs_prod_gdas.$pdy$hh.tar
else
  tarfile=/hpssprod/runhistory/rh$yyyy/$yyyy$mm/$pdy/com_fnl_prod_fnl.$pdy$hh.tar
fi
set +e
#k=0;while [ $((k+=1)) -le ${HPSS_RETRY:-5} ] ; do
#/u/wx20mi/bin/hpsstar get $tarfile $tarlist
htar -xvf $tarfile ./$qual.t${hh}z.pgrbanl
htar -xvf $tarfile ./$qual.t${hh}z.pgrbf06

[ $? -ne 0 ] && continue
set -e
