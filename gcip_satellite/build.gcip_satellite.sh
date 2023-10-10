SHELL=/bin/sh
set -x

moduledir=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/fork.implement2023/modulefiles

##################################################################
# wafs using module compile standard
# 06/12/2018 yali.ma@noaa.gov:    Create module load version
##################################################################

module reset
set -x
mac=$(hostname | cut -c1-1)
mac2=$(hostname | cut -c1-2)
if [ $mac = f  ] ; then            # For Jet 
 machine=jet
 . /etc/profile
 . /etc/profile.d/modules.sh
elif [ $mac = v -o $mac = m  ] ; then            # For Dell
 machine=dell
 . $MODULESHOME/init/bash                 
elif [ $mac = a -o $mac = c -o $mac = d ] ; then # For WCOSS2
 machine=wcoss2
elif [ $mac = t -o $mac = e -o $mac = g ] ; then # For WCOSS
 machine=wcoss
 . /usrx/local/Modules/default/init/bash
elif [ $mac = l -o $mac = s ] ; then             #    wcoss_c (i.e. luna and surge)
 export machine=cray-intel
elif [ $mac2 = hf ] ; then                        # For Hera
 machine=hera
 . /etc/profile
 . /etc/profile.d/modules.sh
elif [ $mac = O ] ; then           # For Orion
 machine=orion
 . /etc/profile
fi

if [[ $machine =~ ^(wcoss2|dell|hera|orion)$ ]]; then
    module use ${moduledir}/wafs
    module load wafs_v6.0.0-${machine}
fi
module list

# export INC="${G2_INC4}"
 export FC=ftn

# track="-O3 -g -traceback -ftrapuv -check all -fp-stack-check "
# track="-O2 -g -traceback"

# export FFLAGSgcip="-FR -I ${G2_INC4} -I ${IP_INC4} -g -O3"
# export FFLAGSgcip="-FR -I ${G2_INC4} -I ${IP_INC4} ${track}"


# export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}  ${BUFR_LIB4}"
 make clean
 make

