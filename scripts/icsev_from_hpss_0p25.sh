#!/bin/bash
set -x
date


PDY1=20190722
PDY2=20190902

COMOUT=/scratch4/NCEPDEV/stmp3/Yali.Mao/uk_icsev

HPSS=/NCEPDEV/emc-global/5year/Yali.Mao/gfip


option1=' -set_grib_type same -new_grid_winds earth '
option2=' -new_grid_interpolation bilinear '
option3=' -if :ICSEV: -new_grid_interpolation neighbor -fi '
grid0p25="latlon 0:1440:0.25 90:721:-0.25"


PDY=$PDY1
while [[ $PDY <  $PDY2 ]] ; do

    cd $COMOUT
    htar -xvf $HPSS/$PDY.tar

    for hh in 00 06 12 18 ; do
	
	for fh in 006 009 012 015 018 021 024 027 030 033 036 ; do

	masterFile=./gfs.$PDY/$hh/gfs.t${hh}z.master.grb2f$fh
	icingFile=./gfs.$PDY/$hh/gfs.t${hh}z.icing.grbf${fh}
	$WGRIB2 $COMOUT/$masterFile | grep ":ICSEV:" | $WGRIB2 -i $COMOUT/$masterFile -grib $COMOUT/$icingFile
          
	$WGRIB2 $COMOUT/$icingFile \
	    $option1 $option2 $option3 \
	    -new_grid $grid0p25 $COMOUT/gfs.t${hh}z.icing.0p25.grb2f$fh

	done
    done

  PDY=`$NDATE 24 ${PDY}00 | cut -c1-8`
done
