SHELL=/bin/sh

# makefile for convert_maxNcip

#----------------------------------------
module purge

module load ips/18.0.1.163
module load impi/18.0.1

module load prod_util/1.1.0
module load prod_envir/1.0.2

module load jasper/1.900.1
module load libpng/1.2.59
module load zlib/1.2.11

module load w3emc/2.3.0
module load w3nco/2.0.6
module load bacio/2.0.2
module load g2/3.1.0
module load g2tmpl/1.5.0
module load ip/3.0.1
module load sp/2.0.2

set -x

curdir=`pwd`

export INC="${G2_INC4}"
export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}  ${BUFR_LIB4}"

export FC=ifort

mkdir -p ../exec

for dir in verf_g2g_grid2grid.fd verf_g2g_icing_convert.fd ; do
 cd ${curdir}/$dir
 make clean
 make
 make install
 make clean
done
