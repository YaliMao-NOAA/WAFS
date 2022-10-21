module load envvar/1.0
module load intel/19.1.3.304 PrgEnv-intel/8.1.0 craype/2.7.8
module load wgrib2/2.0.7

set -x

cmp_grib2_grib2=/u/yali.mao/bin/cmp_grib2_grib2_new
folder1=/lfs/h2/emc/ptmp/yali.mao/wafs_dwn/com/gfs/v16.2/gfs.20210824/00/atmos
folder2=/lfs/h1/ops/canned/com/gfs/v16.2/gfs.20210824/00/atmos
cd $folder1
files=`ls -p | grep -v /`
for afile in $files ; do
    cmp $afile $folder2/$afile
    err=$?
    if [ $err -ne 0 ] ; then
	if [[ $afile == *grib2 ]] ; then 
	    mkdir -p diff
	    echo cmp_grib2_grib2 $afile
	    $cmp_grib2_grib2 $afile $folder2/$afile > diff/${afile}.diff
	fi
    fi
done

files=`ls wmo/*`
for afile in $files ; do
    cmp $afile $folder2/$afile
done
