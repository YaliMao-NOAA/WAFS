# On dell/Hera
. $HOMEsave/modules_setting.sh
ifort -O3 -g -traceback -ftrapuv -check all -fp-stack-check -I ${G2_INC4} -I ${IP_INC4} checkMask.f90 -o checkMask.exe ${G2_LIB4}  ${W3NCO_LIB4} ${BACIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB} 
 
