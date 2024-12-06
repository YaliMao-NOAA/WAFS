SHELL=/bin/sh
set -x

moduledir=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/WAFS
DIR_ROOT=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/save/gcip_satellite

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
    module reset
    source "$moduledir/versions/build.ver"
    module use "$moduledir/modulefiles"
    module load wafs_wcoss2.intel
fi
module list

BUILD_TYPE=${BUILD_TYPE:-"Release"}
CMAKE_OPTS=${CMAKE_OPTS:-}
BUILD_DIR=${BUILD_DIR:-"${DIR_ROOT}/build"}
INSTALL_PREFIX=${INSTALL_PREFIX:-"${DIR_ROOT}/install"}

CMAKE_OPTS+=" -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
CMAKE_OPTS+=" -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}"

# Re-use or create a new BUILD_DIR (Default: create new BUILD_DIR)
[[ ${BUILD_CLEAN:-"YES"} =~ [yYtT] ]] && rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" && cd "${BUILD_DIR}"

set -x
cmake ${CMAKE_OPTS} "${DIR_ROOT}"
make -j "${BUILD_JOBS:-8}" VERBOSE="${BUILD_VERBOSE:-}"
#make install

mv gcip_satellite.x ../

set +x

exit

# export INC="${G2_INC4}"
 export FC=ftn

# track="-O3 -g -traceback -ftrapuv -check all -fp-stack-check "
# track="-O2 -g -traceback"

# export FFLAGSgcip="-FR -I ${G2_INC4} -I ${IP_INC4} -g -O3"
# export FFLAGSgcip="-FR -I ${G2_INC4} -I ${IP_INC4} ${track}"


# export LIBS="${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}  ${BUFR_LIB4}"
 make clean
 make

