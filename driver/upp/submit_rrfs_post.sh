#!/bin/bash

#PBS -j oe
#PBS -N rrfs_post_GTG128
#PBS -l walltime=00:30:00
#PBS -q debug
#PBS -A GFS-DEV
#PBS -l place=vscatter,select=4:ncpus=128
#PBS -V

cd $PBS_O_WORKDIR

set -x
date

# specify computation resource
export TPP_RUN_POST=1
export MP_LABELIO=yes
export OMP_NUM_THREADS=$TPP_RUN_POST
export NNODES_RUN_POST=2
export PPN_RUN_POST=128
#export APRUN="mpiexec -l -n 256 -ppn 64 --cpu-bind core --depth 2"

echo "starting time"
date

############################################
# Loading module
############################################
module reset
module load intel/19.1.3.304
module load PrgEnv-intel/8.1.0
module load craype/2.7.8
module load cray-mpich/8.1.7
module load cray-pals/1.0.12
module load cfp/2.0.4
module load hdf5/1.10.6
module load netcdf/4.7.4
module load crtm/2.4.0
module load prod_util/2.0.10
module load prod_envir/2.0.8
module load libjpeg/9c
module load grib_util/1.2.2
module load wgrib2/2.0.8_wmo
module list

export NET="rrfs"
export MACHINE="WCOSS2"

export cdate=2024022011
export fhr=012
# data input  find  /lfs/f2/t2o/ptmp/emc/stmp/emc.lam/rrfs/v0.8.3 -name dynf*
#             find  /lfs/f2/t2o/ptmp/emc/stmp/emc.lam/rrfs/v0.8.3 -name postprd
#             Wen's: /u/wen.meng/noscrub/ncep_post/RRFS/data_NA
export run_dir=/lfs/f2/t2o/ptmp/emc/stmp/emc.lam/rrfs/v0.8.3/$cdate/fcst_fv3lam

#
export POST_FULL_MODEL_NAME=FV3R
export POST_SUB_MODEL_NAME=FV3R
export USE_CUSTOM_POST_CONFIG_FILE=FALSE
export fhr_dir=any
export FFG_DIR=any
export FIX_UPP=any
export VERBOSE=any

# specify your UPP directory
export UPP_DIR=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/UPP.v17
export FIX_UPP_CRTM=$CRTM_FIX
export PREDEF_GRID_NAME="RRFS_NA_3km"
export EXECdir=$UPP_DIR/exec
export USHdir=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/rrfs-workflow/ush

export postprd_dir=/lfs/h2/emc/ptmp/$USER/post_rrfs_postprd_$cdate
mkdir -p $postprd_dir

# specify your running and output directory
export DATA=$postprd_dir/post_$fhr
rm -rf $DATA; mkdir -p $DATA
cd $DATA

export pgmout=post.printout.log

echo "echo fake printing out">test.sh
chmod 755 test.sh
export GLOBAL_VAR_DEFNS_FP=`pwd`/test.sh

. /lfs/h2/emc/vpppg/noscrub/yali.mao/git/rrfs-workflow/scripts/exrrfs_run_post.sh cdate=$cdate fhr=$fhr

echo "PROGRAM IS COMPLETE!!!!!"
date

