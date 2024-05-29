PDY=20240522
: <<'COMMENT'
source=/lfs/h1/ops/prod/com/gfs/v16.3/gfs.$PDY/00/atmos
target=/lfs/h2/emc/vpppg/noscrub/yali.mao/separation/com.wafs/wafs/v7.0/wafs.$PDY/00

mkdir -p $target

cd $source
files=`ls *wafs.grb2f*`
for file in $files ; do
    waffile=`echo $file | sed "s/wafs.//g"`
    waffile=`echo $waffile | sed "s/gfs/wafs/g"`
    ln -s $source/$file $target/$waffile
done
COMMENT



# change UK forecast hour to 3 digits
source=/lfs/h1/ops/prod/dcom/$PDY/wgrbbul/ukmet_wafs
target=/lfs/h2/emc/vpppg/noscrub/yali.mao/separation/dcom/$PDY/wgrbbul/ukmet_wafs

mkdir -p $target

cd $source
hours="06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 27 30 33 36 39 42 45 48"
products=
for hour in $hours ; do
    newhour="$(printf "%03d" $(( 10#$hour )) )"
    files=`ls EGRR_WAFS_0p25*_t${hour}.grib2`
    for file in $files ; do
	newfile=`echo $file | sed "s/_t${hour}.grib2/_t${newhour}.grib2/g"` 
        ln -s $source/$file $target/$newfile
    done
done
