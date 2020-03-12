#!/bin/sh

. $HOMEsave/modules_setting.sh

set -x

echo $FC $FFLAGS

FFLAGS='-O0 -FR -g -traceback'
#  ${NEMSIO_LIB} needs to be ahead of ${BACIO_LIB4}
LIBS="${NEMSIO_LIB} ${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}"
INC="-I. -I ${NEMSIO_INC} -I ${G2_INC4} -I ${JASPER_INC} -I ${PNG_INC} -I ${Z_INC}"

$FC $FFLAGS $INC -o grib2nemsio.x.$MACHINE grib2nemsio_gfsflux.f90 $LIBS
rm -f *.o *.mod

exit 0
