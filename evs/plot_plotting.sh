set -x
date

export OMP_NUM_THREADS=1

export HOMEevs=${HOMEevs:-/lfs/h2/emc/vpppg/noscrub/$USER/EVS}

############################################################
# Basic environment variables
############################################################
export NET=evs
export STEP=stats
export COMPONENT=wafs
export RUN=atmos
export VERIF_CASE=grid2grid

############################################################
# Load modules
############################################################
source $HOMEevs/versions/run.ver
module reset
module load prod_envir/${prod_envir_ver}
source $HOMEevs/dev/modulefiles/$COMPONENT/${COMPONENT}_$STEP.sh

evs_ver_2d=$(echo $evs_ver | cut -d'.' -f1-2)

############################################################
# environment variables set
############################################################
export envir=prod

export NET=evs
export STEP=plots
export COMPONENT=wafs
export RUN=atmos
export VERIF_CASE=grid2grid

export COMIN=$COMIN
export COMOUT=$COMOUT

export USH_DIR=$HOMEevs/ush/$COMPONENT
export DAYS_LIST=${DAYS_LIST:-"90 31"}


############################################################
# CALL executable job script here
############################################################
export pid=${PBS_JOBID:-$$}
export job=${PBS_JOBNAME:-jevs_wafs_plots}
export jobid=$job.$pid

export DATA=$DATA

export KEEPDATA=YES

$HOMEevs/jobs/JEVS_WAFS_ATMOS_PLOTS

############################################################
## Purpose: This job generates the grid2grid statistics stat
##          files for GFS WAFS
############################################################
#
date
