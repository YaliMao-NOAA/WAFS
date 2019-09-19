#!/bin/sh

SHELL=/bin/sh

. /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/modules_setting.sh

cd /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/seam


export INC="${G2_INC4}"
export FC=ifort

export FFLAGS="-FR -I ${G2_INC4} -I ${IP_INC4} -g -O3"
export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}  ${BUFR_LIB4}"

make -f makefile.smooth_imprintings
