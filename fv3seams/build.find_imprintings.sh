HELL=/bin/sh
set -x

module reset
set -x

module use ./
module load modulefile.wcoss2
module list

cd $HOMEgit/save/fv3seams


export INC="${G2_INC4}"
export FC=ftn

export FFLAGS="-FR -I ${G2_INC4} -I ${IP_INC4} -g -O3"
export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}  ${BUFR_LIB4}"

make -f makefile.find_imprintings
