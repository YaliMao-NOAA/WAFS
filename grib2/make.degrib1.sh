module load g2/3.4.5
module load w3nco/2.4.1
module load w3emc/2.9.1
module load ip/3.3.3
module load bacio/2.4.1
module load sp/2.3.3

export FC=ftn
export INC=${G2_INC4}
export LIBS="$W3NCO_LIB4 $W3EMC_LIB4 $IP_LIB4 $BACIO_LIB4 $SP_LIB4"
export FFLAGS="-O -FR -I ${G2_INC4}"

make -f make.degrib1
