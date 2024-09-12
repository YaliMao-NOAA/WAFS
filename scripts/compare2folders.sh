#!/bin/bash
#set -x

PDY=20240910
cyc=00

suffix="upp"                 # 46 files
suffix="grib2/1p25"          # 29 files
suffix="gcip"
suffix="grib/wmo"            # 15 files
suffix="grib2/1p25/wmo"      # 29 files
suffix="grib2/0p25"          # 93 files
suffix="grib2/0p25/blending" # 27 files
#folder2Btested=/lfs/h2/emc/ptmp/yali.mao/wafsx001/com/wafs/v7.0/wafs.$PDY/$cyc/$suffix
folder2Btested=/lfs/h2/emc/ptmp/yali.mao/wafs_dwn/prod/com/wafs/v7.0/wafs.$PDY/$cyc/$suffix
#folderstandard=/lfs/h2/emc/ptmp/yali.mao/wafs_dwn.testback/prod/com/wafs/v7.0/wafs.$PDY/$cyc/$suffix
folderstandard=/lfs/h1/ops/prod/com/gfs/v16.3/gfs.$PDY/$cyc/atmos
#folderstandard=/lfs/h2/emc/ptmp/yali.mao/wafs_dwn/prod/com/wafs/v7.0/wafs.$PDY/$cyc/$suffix

echo $folder2Btested
echo $folderstandard

if [[ $suffix =~ "wmo" ]] && [[ `basename $folderstandard` = "atmos" ]] ; then
    folderstandard=$folderstandard/wmo
fi

function my_cmp() {
    cd $folder2Btested
    files=`ls -p *.* | grep -v idx`
    n=0
    for file in $files ; do
	echo cmp $file $folderstandard/$file
	cmp $file $folderstandard/$file
	n=$(( n+1))
    done
    echo $n files are compared!!!
}

if [[ $suffix == "grib/wmo" ]] ; then
    my_cmp
    exit
fi

function my_cmp_diffname() {
    cd $folder2Btested

    if [[ $suffix =~ "wmo" ]] ; then
	files=`ls -p *.* | grep -v idx`
    else
	files=`ls *wafs* WAFS* | grep -v idx`
    fi
    
    if [ `basename $folder2Btested` = "upp" ] || [ `basename $folder2Btested` = "0p25" ] ; then
	tmpdir=/lfs/h2/emc/ptmp/$USER/tmp_compWAFS
	mkdir -p $tmpdir
	rm -f $tmpdir/*
	for file in $files ; do
	    wgrib2 $file | egrep -v ":(EDPARM|CATEDR|MWTURB):127" | egrep -v "parm=37:(875|908|942|977)" | wgrib2 -i $file -grib $tmpdir/$file
	done
	folder2Btested=$tmpdir
    fi
    
    n=0
    hours="anl 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 27 30 33 36 39 42 45 48 54 60 66 72 78 84 90 96 102 108 114 120"

    for file in $files ; do
	for hour in $hours ; do

	    if [[ $hour =~ "anl" ]] ; then
		hour2=$hour
	    else
		hour="$(printf "%03d" $(( 10#$hour )) )"
		hour2="$(printf "%02d" $(( 10#$hour )) )"
	    fi

	    if [[ ! $file =~ f$hour ]] ; then
		continue
	    fi

            gfsfile=`echo $file | sed 's/^wafs/gfs/g'`

	    #upp
            gfsfile=`echo $gfsfile | sed 's/0p25.anl.grib2/wafs.0p25.anl/g'`
            gfsfile=`echo $gfsfile | sed "s/master.f${hour}.grib2/wafs.grb2f${hour}/g"`

	    #gcip
	    gfsfile=`echo $gfsfile | sed "s/gfs.t00z.gcip.f${hour}./gfs.t00z.gcip.f${hour2}./g"`
	    gfsfile=`echo $gfsfile | sed "s/gfs.t03z.gcip.f${hour}./gfs.t03z.gcip.f${hour2}./g"`
	    
	    #grib2 1p25
#           gfsfile=`echo $gfsfile | sed "s/\.grid45.f${hour}./\.wafs_grb45f${hour2}./g"`
            gfsfile=`echo $gfsfile | sed "s/\.wafs_grb45f${hour}./\.wafs_grb45f${hour2}./g"`
	    gfsfile=`echo $gfsfile | sed "s/\.awf_grid45.f${hour}\./\.awf_grb45f${hour2}\./g"`
            gfsfile=`echo $gfsfile | sed "s/grib2.wafs.t${cyc}z.awf_grid45.f${hour}/grib2.t${cyc}z.awf_grbf${hour2}.45/g"`
            gfsfile=`echo $gfsfile | sed "s/grib2.wafs.t${cyc}z.grid45.f${hour}/grib2.t${cyc}z.wafs_grbf${hour2}.45/g"`


	    #grib2 0p25
#           gfsfile=`echo $gfsfile | sed "s/z.0p25.f${hour}/z.wafs_0p25.f${hour}/g"`
            gfsfile=`echo $gfsfile | sed "s/z.wafs_0p25.f${hour}/z.wafs_0p25.f${hour}/g"`
            gfsfile=`echo $gfsfile | sed "s/z.awf.0p25.f${hour}/z.awf_0p25.f${hour}/g"`
#	    gfsfile=`echo $gfsfile | sed "s/z.unblended.0p25.f${hour}/z.wafs_0p25_unblended.f${hour2}/g"`
	    gfsfile=`echo $gfsfile | sed "s/WAFS_0p25_unblended_$PDY${cyc}f$hour/gfs.t${cyc}z.wafs_0p25_unblended.f${hour2}/g"`

	    # blended
	    gfsfile=`echo $gfsfile | sed "s/WAFS_0p25_blended_$PDY${cyc}f${hour}/WAFS_0p25_blended_$PDY${cyc}f${hour2}/g"`
	    
	    echo cmp $folder2Btested/$file $folderstandard/$gfsfile
	    cmp $folder2Btested/$file $folderstandard/$gfsfile
	    n=$(( n+1))
	done
    done
    echo $n files are compared!!!
}


my_cmp_diffname
#my_cmp


# Check results:
# grep "No such file"
# grep diff 
