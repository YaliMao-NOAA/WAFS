#!/bin/ksh
################################################
# convert DATA to 0p25 latlon, for WAFS data
# execute on command line
################################################
  input=$1
  output=$2

  option1=' -set_grib_type same -new_grid_winds earth '
  option21=' -new_grid_interpolation bilinear  -if '
  option22="(parm=36|:ICSEV):"
  option23=' -new_grid_interpolation neighbor -fi '
  option4=' -set_bitmap 1 -set_grib_max_bits 16'
  grid0p25="latlon 0:1440:0.25 90:721:-0.25"
  $WGRIB2 $input \
          $option1 $option21 $option22 $option23 $option4 \
          -new_grid $grid0p25 $output
