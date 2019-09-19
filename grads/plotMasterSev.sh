#!/usr/bin/ksh

# plot icing severity from Grib 1 master forecast file over CONUS
usage="Usage: ksh /global/save/Yali.Mao/grads/plotMasterSev.sh   master_grib1_file"

set -x 

cp /global/save/Yali.Mao/grads/cbar.gs .
cp /global/save/Yali.Mao/grads/icingColors.gs .


dataFile=$1
if [[ -z $dataFile ]] ; then
  echo $usage
  exit
fi
#/nwprod/util/exec/copygb -g 130 -x $dataFile CONUS.$dataFile
#wait 15
#$dataFile=CONUS.$dataFile
ctlFile=$dataFile.ctl

/global/save/Yali.Mao/grads/grib2ctl.pl -verf $dataFile > $ctlFile
/usrx/local/GrADS/2.0.2/bin/gribmap -i $ctlFile

wait 5

datetime=`grep -i title $ctlFile | cut -f2 -d' '`

cat <<EOF >tmp.gs
*
'open $ctlFile'
'set lat 18 58'
'set lon 225 300'
EOF

heights="400 500 600"

for hgt in $heights ; do

cat <<EOF >>tmp.gs
*
'c'
'set lev $hgt'
'set rbcols 99 42 43 45 22'
'set rbrange 0 4'
'set clevs 0 1 2 3'
'd ICSEVprs'
'cbar.gs'
'set string 1  tl 10'
'set strsiz .2'
'draw string 0.6 7.9 Icing Severity on $hgt hPa'
'set string 1  tr 1'
'set strsiz 0.15'
'draw string 10.5 7.7 Forecast valid at $datetime'
'printim $datetime.$hgt.sev.png png'
EOF

done
cat icingColors.gs tmp.gs > plotIcing.gs

grads -lbxc "plotIcing.gs"

rm tmp.gs
