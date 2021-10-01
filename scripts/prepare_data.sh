#!/bin/bash

# This script is to prepare canned data for regression test.
# Intended to run under the regression test basedir
#
# Two parts of data:
# Part 1: data_in
# Part 2: data_out
#
#### After the data are prepared, save the data to HPSS
# htar -cvf /NCEPDEV/emc-global/2year/Yali.Mao/regression_data data_in data_out
#### Extract data from HPSS
# htar -xvf /NCEPDEV/emc-global/2year/Yali.Mao/regression_data
#### When data needs to be changed, delete old data from HPSS and archive new one
# hsi (login in HPSS)
# rm /NCEPDEV/emc-global/2year/Yali.Mao/regression_data*

basedir=`pwd`

machine="dell"

PDY=20210917
cyc=00
cyc1=03 # cyc1=cyc+03
fh=36

if [ $fh -le 100 ] ; then
  fh3=0$fh
else
  fh3=$fh
fi

#==================================
# Part 1: data_in
#==================================
mkdir -p $basedir/data_in
cd $basedir/data_in
echo "Prepare input data under $basedir"

# GFS model data for all
mkdir -p gfs.$PDY/$cyc/atmos

# for GRIB2
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.master.grb2f$fh3  gfs.$PDY/$cyc/atmos/.
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.master.grb2if$fh3 gfs.$PDY/$cyc/atmos/.
# For GRIB2 and GRIB2_0P25
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs.grb2f$fh3  gfs.$PDY/$cyc/atmos/.
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs.grb2if$fh3 gfs.$PDY/$cyc/atmos/.
# blending uses GRIB2 output as the input, so no data preparation
# For GCIP
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.master.grb2f000 gfs.$PDY/$cyc/atmos/.
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.master.grb2f003 gfs.$PDY/$cyc/atmos/.

# UK data for blending
mkdir -p dcom/prod/$PDY/wgrbbul/ukmet_wafs
cp $DCOMROOT/prod/$PDY/wgrbbul/ukmet_wafs/*${cyc}z_t${fh}* dcom/prod/$PDY/wgrbbul/ukmet_wafs/.

# Satellite data for GCIP
mkdir -p dcom/prod/$PDY/mcidas
cp $DCOMROOT/prod/$PDY/mcidas/*${PDY}$cyc  dcom/prod/$PDY/mcidas/.
cp $DCOMROOT/prod/$PDY/mcidas/*${PDY}$cyc1 dcom/prod/$PDY/mcidas/.

# BUFR data for GCIP
cp -r $DCOMROOT/prod/$PDY/b000 dcom/prod/$PDY/.
cp -r $DCOMROOT/prod/$PDY/b001 dcom/prod/$PDY/.
cp -r $DCOMROOT/prod/$PDY/b004 dcom/prod/$PDY/.
cp -r $DCOMROOT/prod/$PDY/b007 dcom/prod/$PDY/.

# Radar data for GCIP
mkdir -p hourly/prod/radar.$PDY
cp $COMROOT/hourly/prod/radar.$PDY/refd3d.t${cyc}z.grb2f00  hourly/prod/radar.$PDY/.
cp $COMROOT/hourly/prod/radar.$PDY/refd3d.t${cyc1}z.grb2f00 hourly/prod/radar.$PDY/.

#==================================
# Part 2: data_out
#==================================
mkdir -p $basedir/data_out
cd $basedir/data_out
mkdir -p $basedir/data_out/wmo
echo "Prepare output data under $basedir"

# GRIB2 1p25
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.awf_grb45f${fh}.grib2  gfs.t${cyc}z.awf_grb45f${fh}.grib2.$machine
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs_grb45f${fh}.grib2 gfs.t${cyc}z.wafs_grb45f${fh}.grib2.$machine
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs_grb45f${fh}.nouswafs.grib2 gfs.t${cyc}z.wafs_grb45f${fh}.nouswafs.grib2.$machine

cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/wmo/grib2.t${cyc}z.awf_grbf${fh}.45 wmo/grib2.t${cyc}z.awf_grbf${fh}.45.$machine
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/wmo/grib2.t${cyc}z.wafs_grbf${fh}.45 wmo/grib2.t${cyc}z.wafs_grbf${fh}.45.$machine
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/wmo/grib2.t${cyc}z.wafs_grb_wifsf${fh}.45 wmo/grib2.t${cyc}z.wafs_grb_wifsf${fh}.45.$machine

# blend 1p25
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/WAFS_blended_${PDY}${cyc}f${fh}.grib2 WAFS_blended_${PDY}${cyc}f${fh}.grib2.$machine
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/wmo/grib2.t${cyc}z.WAFS_blended_f${fh} wmo/grib2.t${cyc}z.WAFS_blended_f${fh}.$machine

# GRIB2 0p25
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.wafs_0p25_unblended.f${fh}.grib2 gfs.t${cyc}z.wafs_0p25_unblended.f${fh}.grib2.$machine

# blend 0p25
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/WAFS_0p25_blended_${PDY}${cyc}f${fh}.grib2 WAFS_0p25_blended_${PDY}${cyc}f${fh}.grib2.$machine

# GCIP
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc}z.gcip.f00.grib2  gfs.t${cyc}z.gcip.f00.grib2.$machine
cp $COMROOT/gfs/prod/gfs.$PDY/$cyc/atmos/gfs.t${cyc1}z.gcip.f00.grib2 gfs.t${cyc1}z.gcip.f00.grib2.$machine

