#!/bin/sh
if [ $# -ne 1 ] ; then echo "Usage: $0 cdate";exit 1 ;fi
cdate=$1;pdy=`echo $cdate|cut -c1-8`;cyc=t`echo $cdate|cut -c9-10`z
>fnl.$cdate.grib
for file in pgrbanl pgrbf06;do
	prodfile=/com/fnl/prod/fnl.$pdy/gdas1.${cyc}.$file
	wafsgrid=36;while [ $((wafsgrid+=1)) -le 44 ] ;do
		$g01/fnl/grid2wafs.sh $prodfile $wafsgrid $file.$wafsgrid.grib 
		cat $file.$wafsgrid.grib >> fnl.$cdate.grib
	done
done
$WGRIB fnl.$cdate.grib |more
