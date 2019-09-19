#!/bin/sh
s1=nfsuser/g01/wx23bk/scripts
if [ $# -ne 4 ] ; then echo "Usage: pdy sec1 sec2 FL lat1 lat2 lon1 lon2;exit 1 ;fi
pdy=$1 ; [ ${#pdy} -ne 8 ] && exit 1
sec1=$2;sec2=$3;FL=$4;lat1=$5;lat2=$6;lon1=$7;lon2=$8
# PR(Z) = 1013.25 * (((288.15 - (.0065 * Z))/288.15)**5.256)
pres=$(echo $FL|$g01/BUFR/FL2P)
((hh1=sec1/3600));((hh1=hh1/6*6))
((hh2=sec2/3600));((hh2=hh2/6*6))
mkdir -p  $p1/gdas
cd $p1/gdas
FREQ=6 $s1/s_gdas.sh $p1/gdas $pdy$hh1 $pdy$hh2 
FREQ=6 cdate1=$$pdy$hh1 cdate2=$pdy$hh2 GRADS_TEMPLATE=%y4%m2%d2%h2 $s1/grib2ctl.sh pgbf00.gdas.%y4%m2%d2%h2

cat <<EOF >faa.gs
\'open pgbf00.gdas.$cdate1.ctl\'
\'set lat $lat1 $lat2\'
\'set lat $lon1 $lon2\'
\'set lev $pres\'
\'set gxout shaded\'
\'set mpdset mres\'
\'d tmpprs -273.16\'
\` run cbarnew.gs\`
\'set gxout contour\'
\' d hgtprs'\
\'draw title NCEP ANL $pdy$hh1\ Z,tmp \'pres\'(mb)\'
printim faa.p$pres.$pdy$hh1.gif gif x800 y600 
EOF


