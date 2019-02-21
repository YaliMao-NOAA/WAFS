#!/bin/sh

SHELL=/bin/sh

. /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/modules_setting.sh

set -x

module list

curdir=`pwd`

mkdir -p ../exec

# Unfortunately Dell doesn't support ip.v2 which includes gdswiz etc.
# verf_g2g_grid2grid_grib2.fd is not modifed for WAFS yet, so use verf_g2g_grid2grid.fd

#for dir in verf_g2g_grid2grid_grib2.fd verf_g2g_icing_convert.fd verf_g2g_ceiling_adjust.fd verf_g2g_convert.fd ; do
for dir in verf_g2g_grid2grid_grib2.fd verf_g2g_icing_convert.fd ; do
#================================================
######## Part 1: setup individual FFLAGS ########
#================================================

  if   [[ $dir == verf_g2g_grid2grid.fd ]] ; then
      export FFLAGS="$myFFLAGS $OPENMP -auto"
  elif [[ $dir == verf_g2g_convert.fd ]] ; then
      export FFLAGS="$myFFLAGS"
  elif [[ $dir == verf_g2g_icing_convert.fd ]] ; then
      export FFLAGS="$FREE $myFFLAGS"
  elif [[ $dir == verf_g2g_ceiling_adjust.fd ]] ; then
      export FFLAGS="$myFFLAGS"
  elif [[ $dir == verf_g2g_grid2grid_grib2.fd ]] ; then
      export FFLAGS="$myFFLAGS $OPENMP -auto"
  fi

#================================================
######## Part 2: make compiling          ########
#================================================

  cd ${curdir}/$dir
  make clean
  make
  make install
  make clean

done
