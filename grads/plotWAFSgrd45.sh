#!/usr/bin/ksh

## plot forecast icing potential of wafs_grb45 in GRIB 2 on pressure
## usage: ksh /global/save/Yali.Mao/grads/plotWAFSgrd45.sh YYYYMMDD CYCLES FHOURS

set -x 

workdir=/ptmpp1/Yali.Mao/prod_para
mkdir -p $workdir
cd $workdir

cp /global/save/Yali.Mao/grads/cbar.gs .
cp /global/save/Yali.Mao/grads/icingColors.gs .


usage="Usage: ksh /global/save/Yali.Mao/grads/plotComp.sh YYYYMMDD CYCLES FHOURS"

products="para prod"

days=$1
if [[ -z $days ]] ; then
  echo $usage
fi

cycles=$2
fhours=$3
if [[ -z $cycles ]] ; then
  cycles="00 06 12 18"
fi
if [[ -z $fhours ]] ; then
  fhours="06 12 36"
fi
echo $cycles
echo $fhours

#============= LOOPS =============
for prod in $products ; do

for day in $days  ; do
for hh in $cycles ; do
for fh in $fhours ; do

#-----------inside loop ----------

fileSource=/com/gfs/$prod/gfs.$day/gfs.t${hh}z.wafs_grb45f${fh}.grib2


dataFile=$day.t${hh}z.wafs_grb45f${fh}.grib2.$prod
ctlFile=$dataFile.ctl

cp $fileSource $dataFile

/global/save/Yali.Mao/grads/g2ctl -verf $dataFile > $ctlFile
wait 5
/usrx/local/GrADS/2.0.2/bin/gribmap -i $ctlFile
wait 5

datetime="$day${hh}z.f${fh}"

cat <<EOF >tmp.gs
*
'open $ctlFile'
EOF

#pressures="400 500 600"
pressures="600"

for prs in $pressures ; do

cat <<EOF >>tmp.gs
*
* For Global
* ===========================
'c'
'set lev $prs'
'set clevs 5 15 25 35 45 55 65 75'
'set rbcols 99 41 43 45 22 23 24 26'
'd ICIPmaxprs*100'
'cbar.gs'
'set string 1  tl 10'
'set strsiz .2'
'draw string 0.6 7.9 Icing Potential MAX on ${prs}hPa'
'set string 1  tr 1'
'set strsiz 0.15'
'draw string 10.5 7.7 Forecast at $datetime'
'printim $datetime.$prs.max.$prod.png png'
'c'
'set lev $prs'
'set clevs 5 15 25 35 45 55 65 75'
'set rbcols 99 41 43 45 22 23 24 26'
'd ICIPaveprs*100'
'cbar.gs'
'set string 1  tl 10'
'set strsiz .2'
'draw string 0.46 7.9 Icing Potential MEAN on ${prs}hPa'
'set string 1  tr 1'
'set strsiz 0.15'
'draw string 10.5 7.7 Forecast at $datetime'
'printim $datetime.$prs.mean.$prod.png png'
*
* For CONUS
* ===========================
'set lat 18 58'
'set lon 225 300'
'c'
'set lev $prs'
'set clevs 5 15 25 35 45 55 65 75'
'set rbcols 99 41 43 45 22 23 24 26'
'd ICIPmaxprs*100'
'cbar.gs'
'set string 1  tl 10'
'set strsiz .2'
'draw string 0.6 7.9 Icing Potential MAX on ${prs}hPa'
'set string 1  tr 1'
'set strsiz 0.15'
'draw string 10.5 7.7 Forecast at $datetime'
'printim CONUS.$datetime.$prs.max.$prod.png png'
'c'
'set lev $prs'
'set clevs 5 15 25 35 45 55 65 75'
'set rbcols 99 41 43 45 22 23 24 26'
'd ICIPaveprs*100'
'cbar.gs'
'set string 1  tl 10'
'set strsiz .2'
'draw string 0.6 7.9 Icing Potential MEAN on ${prs}hPa'
'set string 1  tr 1'
'set strsiz 0.15'
'draw string 10.5 7.7 Forecast at $datetime'
'printim CONUS.$datetime.$prs.mean.$prod.png png'
EOF

done

cat icingColors.gs tmp.gs > plotComp.gs
grads -lbxc "plotComp.gs"

done
done
done

done


rm tmp.gs
