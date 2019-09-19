#!/bin/ksh
#**************************************************************
# Archive GTG or FLX nemsio  from Cray to HPSS
#**************************************************************

. $MODULESHOME/init/ksh
module load prod_envir prod_util HPSS/5.0.2.5

set -x

echo 'Usage: archive_wafs.sh product hpssDir [YYYYMMDD]'
# product includes gtg and flx nemsio
#     ie. gfs.t00z.gtg.grb2f36   gfs.t00z.flxf036.nemsio
# hpssDir is the relative folder under /NCEPDEV/emc-global/5year/Yali.Mao
#     ie. gtg_backup

prod=$1
rdir=$2

if [ $# -ge 3 ]; then
  PDY=$3
else
  PDY=`$NDATE -24 | cut -c1-8`
fi

comin=/gpfs/hps/nco/ops/com/gfs/prod/gfs.$PDY

tarout=/NCEPDEV/emc-global/5year/Yali.Mao/$rdir

cd $comin

if [ $prod = 'gtg' ] ; then
    htar -cvf $tarout/gfs.$prod.$PDY.tar ./gfs.t??z.gtg.grb2f??
elif [ $prod = 'flx' ] ; then
    htar -cvf $tarout/gfs.$prod.$PDY.tar ./gfs.t??z.flxf0{03,06,09,12,15,18,21,24,27,30,33,36}.nemsio
fi

exit
