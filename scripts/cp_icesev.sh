module load ips/18.0.5.274
module load prod_util/1.1.6
set -x

cd /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/icesev_verif
date=`$NDATE -24`
nday=2
while [ $nday -le 9 ] ; do
    PDY=${date:0:8}
    for cyc in 00 06 12 18 ; do
	if [ -d /gpfs/dell1/nco/ops/com/gfs/prod/gfs.${PDY} ] ; then
	    
	    mkdir -p gcip/gfs.${PDY}/$cyc/atmos
	    cyc1=$(( cyc + 3 ))
	    cyc1="$(printf "%02d" $(( 10#$cyc1 )) )"
	    rsync -avp /gpfs/dell1/nco/ops/com/gfs/prod/gfs.${PDY}/$cyc/atmos/gfs.t${cyc}z.gcip.f00.grib2 ./gcip/gfs.${PDY}/$cyc/atmos/gfs.t${cyc}z.gcip.f00.grib2
	    rsync -avp /gpfs/dell1/nco/ops/com/gfs/prod/gfs.${PDY}/$cyc/atmos/gfs.t${cyc1}z.gcip.f00.grib2 ./gcip/gfs.${PDY}/$cyc/atmos/gfs.t${cyc1}z.gcip.f00.grib2

	    mkdir -p fcst/gfs.${PDY}/$cyc/atmos
	    rsync -avp /gpfs/dell1/nco/ops/com/gfs/prod/gfs.${PDY}/$cyc/atmos/WAFS_0p25_blend* ./fcst/gfs.${PDY}/$cyc/atmos/.
	    rsync -avp /gpfs/dell1/nco/ops/com/gfs/prod/gfs.${PDY}/$cyc/atmos/gfs.t${cyc}z.wafs_0p25_unblended.f*.grib2 ./fcst/gfs.${PDY}/$cyc/atmos/.
	fi

        if [ -d /gpfs/dell1/nco/ops/dcom/prod/$PDY/wgrbbul/ukmet_wafs ] ; then

	    mkdir -p uk/$PDY/wgrbbul/ukmet_wafs
            rsync -avp /gpfs/dell1/nco/ops/dcom/prod/*/wgrbbul/ukmet_wafs/EGRR_WAFS_0p25_icing_unblended_${PDY}_${cyc}z_t*.grib2 uk/$PDY/wgrbbul/ukmet_wafs/.
	fi
    done

    hours=$(( $nday * 24 ))
    date=`$NDATE -$hours`
    nday=$(( nday + 1 ))
done

#/gpfs/dell1/nco/ops/com/gfs/prod/gfs.*/??/atmos/*gcip*
