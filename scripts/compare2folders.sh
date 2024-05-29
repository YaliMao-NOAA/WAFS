#!/bin/bash
set -x

folder2Btested=/lfs/h2/emc/vpppg/noscrub/yali.mao/before.separation/com.blending_0p25/gfs/v16.3/gfs.20240522/00/atmos
folder2Btested=/lfs/h2/emc/vpppg/noscrub/yali.mao/after.separation/com.grib2_0p25/wafs/v7.0/wafs.20240522/00
folder2Btested=/lfs/h2/emc/ptmp/yali.mao/wafs_dwn/para/com/wafs/v7.0/wafs.20240522/00
folderstandard=/lfs/h1/ops/prod/com/gfs/v16.3/gfs.20240522/00/atmos

function my_cmp() {
    cd $folder2Btested
    files=`ls *grib2 grib2*`
    n=0
    for file in $files ; do
	cmp $file $folderstandard/$file
	n=$(( n+1))
    done
    echo $n files are compared!!!
}

function my_cmp_diffname() {
    cd $folder2Btested
    n=0
    hours="0 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 27 30 33 36 39 42 45 48 54 60 66 72 78 84 90 96 102 108 114 120"
    for hour in $hours ; do
	hour="$(printf "%03d" $(( 10#$hour )) )"
	files=`ls *f$hour.*`
	newhour="$(printf "%02d" $(( 10#$hour )) )"
	for file in $files ; do
            gfsfile=`echo $file | sed 's/^wafs/gfs/g'`
            gfsfile=`echo $gfsfile | sed 's/\.0p25/\.wafs_0p25/g'`
            gfsfile=`echo $gfsfile | sed 's/\.grd45/\.wafs_grd45/g'`
	    gfsfile=`echo $gfsfile | sed "s/WAFS_0p25_blended_2024052200f${hour}./WAFS_0p25_blended_2024052200f${newhour}./g"`
	    gfsfile=`echo $gfsfile | sed "s/gfs.t00z.gcip.f${hour}./gfs.t00z.gcip.f${newhour}./g"`
	    gfsfile=`echo $gfsfile | sed "s/gfs.t03z.gcip.f${hour}./gfs.t03z.gcip.f${newhour}./g"`
	    gfsfile=`echo $gfsfile | sed "s/gfs.t00z.wafs_grd45f${hour}./gfs.t00z.wafs_grb45f${newhour}./g"`
	    gfsfile=`echo $gfsfile | sed "s/gfs.t00z.wafs_0p25_unblended.f${hour}./gfs.t00z.wafs_0p25_unblended.f${newhour}./g"`
	    gfsfile=`echo $gfsfile | sed "s/gfs.t00z.awf_grd45f${hour}./gfs.t00z.awf_grb45f${newhour}./g"`
            gfsfile=`echo $gfsfile | sed "s/f${hour}.45/f${newhour}.45/g"`
	    cmp $file $folderstandard/$gfsfile
	    n=$(( n+1))
	done
    done
    echo $n files are compared!!!
}


my_cmp_diffname
folder2Btested=$folder2Btested/wmo
folderstandard=$folderstandard/wmo
my_cmp_diffname

# Check results:
# grep "No such file"
# grep diff 
