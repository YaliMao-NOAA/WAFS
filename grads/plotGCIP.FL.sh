#!/usr/bin/ksh

## plot analysis icing potential of GCIP in GRIB 1 on hybrid level
usage="Usage: ksh /global/save/Yali.Mao/grads/plotGCIP.FL.sh a_grib_1_file"

set -x 

cp /global/save/Yali.Mao/grads/cbar.gs .
cp /global/save/Yali.Mao/grads/icingColors.gs .

# for FL 090   110  130  150
heights="2743 3353 3962 4573"
# for FL 060   100  140  180
#    hPa 800   700  600  500
#heights="1828 3048 4267 5486"                                                                                                                                       

dataFile=$1
if [[ -z $dataFile ]] ; then
  echo $usage
fi
ctlFile=$dataFile.ctl

/global/save/Yali.Mao/grads/grib2ctl.pl -verf $dataFile > $ctlFile
/usrx/local/GrADS/2.0.2/bin/gribmap -i $ctlFile

wait 15

datetime=`grep -i tdef $ctlFile | cut -f4 -d' '`

cat <<EOF >tmp.gs
*
'open $ctlFile'
'set lat 18 58'
'set lon 225 300'
EOF

for hgt in $heights ; do

fltlevel=$(( $hgt * 3.28 + 5 ))
fltlevel=$(( $fltlevel / 100 ))
fltlevel=`echo $fltlevel | cut -c1-3`
fltlevel=`printf "%03d\n" $fltlevel`

cat <<EOF >>tmp.gs
*
'c'
'set lev $hgt'
'set clevs 5 15 25 35 45 55 65 75'
'set rbcols 99 41 43 45 22 23 24 26'
'd meiphml*100'
'cbar.gs'
'set string 1  tl 10'
'set strsiz .2'
'draw string 0.6 7.9 icing Potential on FL$fltlevel'
'set string 1  tr 1'
'set strsiz 0.15'
'draw string 10.5 7.7 Analysis valid at $datetime'
'printim $datetime.FL$fltlevel.png png'
EOF

done
cat icingColors.gs tmp.gs > plotIcing.gs

grads -lbxc "plotIcing.gs"

rm tmp.gs
