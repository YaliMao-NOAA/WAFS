#!/bin/sh
if [ $# -lt 1 -o $# -gt 2 ] ; then 
echo "Usage: $0 PDY [PDY2]";exit 1 
fi
set -xeua

export HOME_scripts=${HOME_scripts:-/gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/wafs_faa}
export WHO=`whoami`
export COPYGB=${COPYGB:-/gpfs/dell1/nco/ops/nwprod/grib_util.v1.1.0/exec/copygb}
export WGRIB=${WGRIB:-/gpfs/dell1/nco/ops/nwprod/grib_util.v1.1.0/exec/wgrib}
export COPYGB_PARM=${COPYGB_PARM:-$HOME_scripts/merge_copygb.parm}
export COPYGB_IOPT=${COPYGB_IOPT:-1}

#export TARGET_rzdm_scp="ymao@emcrzdm:/home/people/emc/ftp/mmb/mmbpll/wafs/"
export TARGET_rzdm="ymao@emcrzdm:/home/people/emc/ftp/gmb/wafs/faa/"

export TMP=${TMP:-/gpfs/dell3/ptmp/$WHO}

NDATE=${NDATE:-/gpfs/dell1/nco/ops/nwprod/prod_util.v1.1.0/exec/ips/ndate}

PDY1=$1;PDY2=$1; [ $# -eq 2 ] && PDY2=$2
if [ ${#PDY1} -ne 8 -o ${#PDY2} -ne 8 ] ; then
	echo invalid $0 input $*
	echo "Usage: $0 PDY [PDY2]";exit 1 
	exit 1
fi
PDY=$PDY2
while [ $PDY -ge $PDY1 ] ; do
  export DATA=$TMP/faa/faa.$PDY

  # run scripts for cdate
  # ----------------------
  echo 'before 00'
  $HOME_scripts/grid2gdas.sh  ${PDY}00 gdas 
  echo 'before 06'
  $HOME_scripts/grid2gdas.sh  ${PDY}06 gdas 
  echo 'before 12'
  $HOME_scripts/grid2gdas.sh  ${PDY}12 gdas 
  echo 'before 18'
  $HOME_scripts/grid2gdas.sh  ${PDY}18 gdas 
  echo 'before wafs00'
  $HOME_scripts/grid2wafs.sh ${PDY}00 gdas 
  echo 'before wafs12'
  $HOME_scripts/grid2wafs.sh ${PDY}12 gdas 

  PDY=$($NDATE -24 ${PDY}00|cut -c1-8)

done
