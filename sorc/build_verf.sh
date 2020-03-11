#!/bin/sh

SHELL=/bin/sh

#. ~/.bashrc
module purge
 . /etc/profile
 . /etc/profile.d/modules.sh
moduledir=`dirname $(readlink -f ../modulefiles/verf)`
module use ${moduledir}
module load verf/v3.0.12


set -x

module list

echo IP_LIB4= $IP_INC4 $IP_LIB4

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
