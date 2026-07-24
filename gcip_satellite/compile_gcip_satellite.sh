#!/bin/bash
#Set up for cmake build.
############################################################

set -eu

moduledir=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/wafs.fork

readonly MYDIR=$(cd "$(dirname "$(readlink -f -n "${BASH_SOURCE[0]}" )" )" && pwd -P)
DIR_ROOT=${DIR_ROOT:-$( cd ${MYDIR} && pwd )}

module reset
source "$moduledir/versions/build.ver"
module use "$moduledir/modulefiles"
module load wafs_wcoss2.intel
module list

BUILD_TYPE=${BUILD_TYPE:-"Release"}
INSTALL_PREFIX=${INSTALL_PREFIX:-"../install"}

CMAKE_OPTS=${CMAKE_OPTS:-}
CMAKE_OPTS+=" -DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
CMAKE_OPTS+=" -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}"

# Create a new BUILD_DIR
set -x

BUILD_DIR=${BUILD_DIR:-"./build/fileCopies"}

# Re-use or create a new BUILD_DIR (Default: create new BUILD_DIR)
[[ ${BUILD_CLEAN:-"YES"} =~ [yYtT] ]] && rm -rf ./build
mkdir -p "${BUILD_DIR}" && cd "${BUILD_DIR}"

cmake $CMAKE_OPTS ${DIR_ROOT}
make -j${BUILD_JOBS:-6} VERBOSE="${BUILD_VERBOSE:-}"
make install

cp $INSTALL_PREFIX/bin/gcip_satellite.x ../../.
