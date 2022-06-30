# For 0p25 icing severity verification data: GCIP, US blended/unblended, UK unblended
#
# 1. Synchronize GCIP @ T and T+3, blended/unblended WAFS, UK unblended WAFS
#    to noscrub/Yali.Mao/icesev_verif
# 2. Not HPSS related

module load ips/18.0.5.274
module load prod_util/1.1.6
module load prod_envir
set -x

# Make the following 3 changes for different machines
cd /lfs/h2/emc/vpppg/noscrub/yali.mao/icesev_verif
gfsVer=`ls $COMROOT/gfs | tail -1`
COMROOT=$COMROOT/gfs/$gfsVer
DCOMROOT=$DCOMROOT

date=`$NDATE -24`
nday=2
while [ $nday -le 9 ] ; do
    PDY=${date:0:8}
    for cyc in 00 06 12 18 ; do
	if [ -d $COMROOT/gfs.${PDY} ] ; then
	    mkdir -p gcip/gfs.${PDY}/$cyc/atmos
	    cyc1=$(( cyc + 3 ))
	    cyc1="$(printf "%02d" $(( 10#$cyc1 )) )"
	    rsync -avp $COMROOT/gfs.${PDY}/$cyc/atmos/gfs.t${cyc}z.gcip.f00.grib2 ./gcip/gfs.${PDY}/$cyc/atmos/gfs.t${cyc}z.gcip.f00.grib2
	    rsync -avp $COMROOT/gfs.${PDY}/$cyc/atmos/gfs.t${cyc1}z.gcip.f00.grib2 ./gcip/gfs.${PDY}/$cyc/atmos/gfs.t${cyc1}z.gcip.f00.grib2

	    mkdir -p fcst/gfs.${PDY}/$cyc/atmos
	    rsync -avp $COMROOT/gfs.${PDY}/$cyc/atmos/WAFS_0p25_blend* ./fcst/gfs.${PDY}/$cyc/atmos/.
	    rsync -avp $COMROOT/gfs.${PDY}/$cyc/atmos/gfs.t${cyc}z.wafs_0p25_unblended.f*.grib2 ./fcst/gfs.${PDY}/$cyc/atmos/.
	fi

        if [ -d $DCOMROOT/$PDY/wgrbbul/ukmet_wafs ] ; then
	    mkdir -p uk/$PDY/wgrbbul/ukmet_wafs
            rsync -avp $DCOMROOT/*/wgrbbul/ukmet_wafs/EGRR_WAFS_0p25_icing_unblended_${PDY}_${cyc}z_t*.grib2 uk/$PDY/wgrbbul/ukmet_wafs/.
	fi
    done

    hours=$(( $nday * 24 ))
    date=`$NDATE -$hours`
    nday=$(( nday + 1 ))
done

#$COMROOT/gfs.*/??/atmos/*gcip*
