#!/bin/bash

# This script is to prepare canned data for regression test. 
# The canned data is the operational products still available on supercomputer
#
# Intended to run under the regression test basedir
#
# Two parts of data:
# Part 1: data_in   # As input for regression test run
# Part 2: data_out  # As standard to compare with regression test data
#
#### After the data are prepared, save the data to HPSS
# htar -cvf /NCEPDEV/emc-global/2year/Yali.Mao/regression_data data_in data_out
#### Extract data from HPSS
# htar -xvf /NCEPDEV/emc-global/2year/Yali.Mao/regression_data
#### When data needs to be changed, delete old data from HPSS and archive new one
# hsi (login in HPSS)
# rm /NCEPDEV/emc-global/2year/Yali.Mao/regression_data*

set -x

basedir=`pwd`

# new input data
COMROOTgfs_in=/lfs/h1/ops/prod/com/gfs/v16.3
# old/operational output data to be compared
COMROOTgfs_out=/lfs/h1/ops/prod/com/gfs/v16.2

COMROOTradar=/lfs/h1/ops/prod/com/radarl2/v1.2

PDY=20221014
cyc=12
cyc1=03 # cyc1=cyc+03
fh=36

if [ $fh -le 100 ] ; then
  fh3=0$fh
else
  fh3=$fh
fi

if [[ `hostname` =~ ^[v|m] ]] ; then
    machine="dell"
    DCOMROOT=$DCOMROOT/prod
    DCOM="dcom/prod"  # dumpjb will look into $DCOMROOT/prod
elif [[ `hostname` =~ ^[d|c]login ]] ; then
    machine="wcoss2"  # dumpjb will look into $DCOMROOT
    DCOM="dcom"
fi
# ====== COMROOT
# WCOSS2: $COMROOT/gfs/v16.2/gfs.$PDY /lfs/h1/ops/prod/com/gfs/v16.2
# WCOSS1: $COMROOT/gfs/prod/gfs.$PDY  /gpfs/dell1/nco/ops/com/gfs/prod
# ====== DCOMROOT
# WCOSS2: $DCOMROOT/$PDY      /lfs/h1/ops/prod/dcom
# WCOSS1: $DCOMROOT/prod/$PDY /gpfs/dell1/nco/ops/dcom/prod
# ====== COMINradar
# WCOSS2: $COMROOT/radarl2/v1.2/radar.$PDY /lfs/h1/ops/prod/com/radarl2/v1.2
# WCOSS1: $COMROOT/hourly/prod/radar.$PDY  /gpfs/dell1/nco/ops/com/hourly/prod

#==================================
# Part 1: data_in
#==================================
mkdir -p $basedir/data_in
cd $basedir/data_in
echo "Prepare input data under $basedir"

# GFS model data for all
mkdir -p gfs.$PDY/$cyc/atmos

# for GRIB2
cp $COMROOTgfs_in/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.master.grb2f$fh3  gfs.$PDY/$cyc/atmos/.
cp $COMROOTgfs_in/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.master.grb2if$fh3 gfs.$PDY/$cyc/atmos/.
# For GRIB2 and GRIB2_0P25
cp $COMROOTgfs_in/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs.grb2f$fh3  gfs.$PDY/$cyc/atmos/.
cp $COMROOTgfs_in/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs.grb2f$fh3.idx gfs.$PDY/$cyc/atmos/.
cp $COMROOTgfs_in/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs_icao.grb2f$fh3 gfs.$PDY/$cyc/atmos/.
cp $COMROOTgfs_in/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs_icao.grb2f$fh3.idx gfs.$PDY/$cyc/atmos/.
# blending uses GRIB2 output as the input, so no data preparation
# For GCIP
cp $COMROOTgfs_in/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.master.grb2f000 gfs.$PDY/$cyc/atmos/.
cp $COMROOTgfs_in/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.master.grb2f003 gfs.$PDY/$cyc/atmos/.

# UK data for blending
mkdir -p $DCOM/$PDY/wgrbbul/ukmet_wafs
cp $DCOMROOT/$PDY/wgrbbul/ukmet_wafs/*${cyc}z_t${fh}* $DCOM/$PDY/wgrbbul/ukmet_wafs/.

# Satellite data for GCIP
mkdir -p $DCOM/$PDY/mcidas
cp $DCOMROOT/$PDY/mcidas/*${PDY}$cyc  $DCOM/$PDY/mcidas/.
cp $DCOMROOT/$PDY/mcidas/*${PDY}$cyc1 $DCOM/$PDY/mcidas/.

# BUFR data for GCIP
cp -r $DCOMROOT/$PDY/b000 $DCOM/$PDY/.
cp -r $DCOMROOT/$PDY/b001 $DCOM/$PDY/.
cp -r $DCOMROOT/$PDY/b004 $DCOM/$PDY/.
cp -r $DCOMROOT/$PDY/b007 $DCOM/$PDY/.

# Radar data for GCIP
mkdir -p radar.$PDY
cp $COMROOTradar/radar.$PDY/refd3d.t${cyc}z.grb2f00  radar.$PDY/.
cp $COMROOTradar/radar.$PDY/refd3d.t${cyc1}z.grb2f00 radar.$PDY/.

#==================================
# Part 2: data_out
#==================================
mkdir -p $basedir/data_out/$PDY
cd $basedir/data_out/$PDY
mkdir -p $basedir/data_out/$PDY/wmo
echo "Prepare output data under $basedir"

# GRIB2 1p25
#cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.awf_grb45f${fh}.grib2  gfs.t${cyc}z.awf_grb45f${fh}.grib2
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs_grb45f${fh}.grib2 gfs.t${cyc}z.wafs_grb45f${fh}.grib2
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs_grb45f${fh}.nouswafs.grib2 gfs.t${cyc}z.wafs_grb45f${fh}.nouswafs.grib2

#cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/wmo/grib2.t${cyc}z.awf_grbf${fh}.45 wmo/grib2.t${cyc}z.awf_grbf${fh}.45
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/wmo/grib2.t${cyc}z.wafs_grbf${fh}.45 wmo/grib2.t${cyc}z.wafs_grbf${fh}.45
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/wmo/grib2.t${cyc}z.wafs_grb_wifsf${fh}.45 wmo/grib2.t${cyc}z.wafs_grb_wifsf${fh}.45

# blend 1p25
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/WAFS_blended_${PDY}${cyc}f${fh}.grib2 WAFS_blended_${PDY}${cyc}f${fh}.grib2
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/wmo/grib2.t${cyc}z.WAFS_blended_f${fh} wmo/grib2.t${cyc}z.WAFS_blended_f${fh}

# GRIB2 0p25
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs_0p25_unblended.f${fh}.grib2 gfs.t${cyc}z.wafs_0p25_unblended.f${fh}.grib2

# blend 0p25
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/WAFS_0p25_blended_${PDY}${cyc}f${fh}.grib2 WAFS_0p25_blended_${PDY}${cyc}f${fh}.grib2

# GCIP
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.gcip.f00.grib2  gfs.t${cyc}z.gcip.f00.grib2
cp $COMROOTgfs_out/gfs.$PDY/$cyc/atmos/gfs.t${cyc1}z.gcip.f00.grib2 gfs.t${cyc1}z.gcip.f00.grib2
