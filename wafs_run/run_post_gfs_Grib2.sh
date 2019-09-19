#!/bin/bash

#BSUB -L /bin/sh
#BSUB -oo /ptmpp1/Yali.Mao/out.post.gfs.Grib2
#BSUB -eo /ptmpp1/Yali.Mao/err.post.gfs.Grib2
#BSUB -n 16
#BSUB -J post_gfip
#BSUB -W 00:50
#BSUB -q "dev"
#BSUB -R span[ptile=8]
#BSUB -R affinity[core(2):distribute=balance]
#BSUB -P GFS-T2O
#BSUB -x
#BSUB -a poe

set -x
export OMP_NUM_THREADS=1
export MP_TASK_AFFINITY=core:$OMP_NUM_THREADS
export MP_EUILIB=us
export MP_MPILIB=mpich2
export OMP_STACKSIZE=1G
export MP_STDOUTMODE=unordered
export MP_LABELIO=yes
export MP_TASK_AFFINITY=core
export FOR_DISABLE_STACK_TRACE=true
export decfort_dump_flag=y

set -x

module load ibmpe ics lsf
export MP_COMPILER=intel
export MP_LABELIO=yes

export PDY=20150407
export cyc=00
export cycle=t${cyc}z

# specify your running and output directory
export user=`whoami`
export DATA=/ptmpp1/${user}/gfip.working.$PDY

# this script mimics operational GFS post processing production
export MP_LABELIO=yes

rm -rf $DATA; mkdir -p $DATA
cd $DATA
export COMOUT=/ptmpp1/${user}/gfip.$PDY
mkdir -p $COMOUT

export HOMEPOST=/global/save/Yali.Mao/project/post_branch
#export post_ver=${post_ver:-v5.0.0}
export crtm_ver=${crtm_ver:-v2.0.6}
export gsm_ver=${gsm_ver:-v12.0.0}
export util_ver=v1.0.0

export post_times="06 09 12 15 18 21 24 27 30 33 36"

ksh $HOMEPOST/jobs/JGFS_NCEPPOST