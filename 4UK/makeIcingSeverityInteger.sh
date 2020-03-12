# On dell/Hera
. $HOMEsave/modules_setting.sh
ifort -O -I ${G2_INC4} -I ${IP_INC4} checkIcingSeverityInteger.f90 -o checkIcingSeverityInteger.exe ${G2_LIB4}  ${W3NCO_LIB4} ${BACIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB} 
 
