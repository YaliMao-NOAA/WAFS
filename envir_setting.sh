
# used by:
# ~/.bashrc
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/grads/plotWafs.sh
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/wafs_run/run_post_gfs_Grib2.archive_nemsio.cron
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/scripts/GCIP_GFIP_GTG_2_rzdm.cron
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/scripts/GCIP.prod.rerun.sh
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/wafs_run/run_JVERF_GRID2GRID_WAFS.sh
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/verf_g2g.v3.0.12/grads/verify_exp_step2.sh
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/wafs_faa/drive_wafs
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/scripts/nemsio2ncar_to_hpss.sh
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/scripts/nemsio2ncar_from_hpss.sh
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/gcip_satellite/match.gcip.SAT.CFG.sh

export VSDBsave=/gpfs/dell2/emc/modeling/noscrub/Yali.Mao/vsdb

export HOMEnoscrub=/gpfs/dell2/emc/modeling/noscrub/Yali.Mao

#=====================================================#
if [[ `hostname` =~ ^tfe ]] ; then
#=====================================================#
  export MACHINE=theia
  alias quotas='cat /scratch4/BMC/public/quotas/stmp3'

  #========== Theia ====================#
  export VSDBsave=/scratch4/NCEPDEV/global/noscrub/Yali.Mao/vsdb
  export HOMEnoscrub=/scratch4/NCEPDEV/global/noscrub/Yali.Mao

  export NOSCRUB=$HOMEnoscrub
  export HOMEnoscrub=$NOSCRUB

  export TMP='/scratch4/NCEPDEV/stmp3/Yali.Mao'

  export G2CTL=$HOMEnoscrub/git/save/grads/g2ctl.theia

  export NWPROD=/scratch4/NCEPDEV/rstprod/nwprod
  export COMROOT=/scratch4/NCEPDEV/rstprod/com

  # run this bash before 'module load'
  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
      . $MODULESHOME/init/profile
  else
      . /apps/lmod/7.7.18/init/bash
      . /apps/lmod/7.7.18/init/profile
  fi

  module use /apps/modules/modulefiles
  module load intel/18.0.1.163
  module load gcc/6.2.0
  module load grads
  module load ncl
  module load hpss
  module load svn
#  module load slurm
  module load rocoto
  module load intelpython

  module use /apps/modules/modulefamilies/intel
  module load impi/5.1.2.150
  module load netcdf
  module load R/3.5.0

  module use /scratch3/NCEPDEV/nwprod/modulefiles/
  module load grib_util
#  module load wgrib2/2.0.8
  alias wgrib2=$WGRIB2

  module use /scratch3/NCEPDEV/nwprod/lib/modulefiles
  module load prod_util
  module load g2tmpl/v1.5.0

  # Install LD_LIBRARY_PATH to solve runtime error:  
  #   error while loading shared libraries: libiomp5.so: cannot open shared object file
  # It works for /scratch4/NCEPDEV/global/noscrub/Yali.Mao/git/verf_g2g.v3.0.12/exec/verf_g2g_grid2grid_grib2
  source /opt/intel/bin/compilervars.sh intel64

# From Fanglin
# module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/python/modulefiles
# module load python/3.6.1-emc

#=====================================================#
elif [[ `hostname` =~ ^h ]] ; then
#=====================================================#
  export MACHINE=theia
  alias quotas='cat /scratch4/BMC/public/quotas/stmp3'

  #========== Theia ====================#
  export VSDBsave=/scratch4/NCEPDEV/global/noscrub/Yali.Mao/vsdb
  export HOMEnoscrub=/scratch4/NCEPDEV/global/noscrub/Yali.Mao

  export NOSCRUB=$HOMEnoscrub
  export HOMEnoscrub=$NOSCRUB

  export TMP='/scratch4/NCEPDEV/stmp3/Yali.Mao'

  export G2CTL=$HOMEnoscrub/git/save/grads/g2ctl.theia

  export NWPROD=/scratch4/NCEPDEV/rstprod/nwprod
  export COMROOT=/scratch4/NCEPDEV/rstprod/com

  # run this bash before 'module load'
  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
      . $MODULESHOME/init/profile
  else
      . /apps/lmod/7.7.18/init/bash
      . /apps/lmod/7.7.18/init/profile
  fi

  module use /apps/modules/modulefiles
  module load intel/18.0.1.163
  module load gcc/6.2.0
  module load grads
  module load ncl
  module load hpss
  module load svn
#  module load slurm
  module load rocoto
  module load intelpython

  module use /apps/modules/modulefamilies/intel
  module load impi/5.1.2.150
  module load netcdf
  module load R/3.5.0

  module use /scratch3/NCEPDEV/nwprod/modulefiles/
  module load grib_util
#  module load wgrib2/2.0.8
  alias wgrib2=$WGRIB2

  module use /scratch3/NCEPDEV/nwprod/lib/modulefiles
  module load prod_util
  module load g2tmpl/v1.5.0

  # Install LD_LIBRARY_PATH to solve runtime error:  
  #   error while loading shared libraries: libiomp5.so: cannot open shared object file
  # It works for /scratch4/NCEPDEV/global/noscrub/Yali.Mao/git/verf_g2g.v3.0.12/exec/verf_g2g_grid2grid_grib2
  source /opt/intel/bin/compilervars.sh intel64

# From Fanglin
# module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/python/modulefiles
# module load python/3.6.1-emc


#=====================================================#
elif [[ `hostname` =~ ^[g|t][0-9]{1} ]] ; then
#     `cat /etc/dev` # gyre/tide/luna/surg
#=====================================================#
  export MACHINE=wcoss

  #========== Gyre/Tide =====================#
  export NOSCRUB=/global/noscrub/Yali.Mao
  if [ ! -e $HOMEnoscrub ] ; then
      export HOMEnoscrub=$NOSCRUB
  fi

  export TMP='/ptmpp1/Yali.Mao'
  #export SSAVE='/sss/emc/global/shared/Yali.Mao/save'
  #alias ssave='cd $SSAVE'

  export G2CTL=$HOMEnoscrub/git/save/grads/g2ctl

  export NWPROD=/nwprod2
  export GADDIR=/usrx/local/GrADS/2.0.2/lib

  # run this bash before 'module load'
  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
  else
      . /usrx/local/Modules/default/init/bash
  fi
  # load basic modules, which are required for 'bsub' as well
  module load ibmpe ics lsf
  # load other modules
  module load prod_envir
  module load prod_util
  module load grib_util/v1.0.0  # v1.0.4 or later will load ics
  module load GrADS
  module load hpss

  module load NetCDF/4.2/serial

  #module load EnvVars/1.0.0
  #module load imagemagick/6.8.3-3 # add 2-21-13

  PATH=$PATH:/gpfs/*1/u/Jeff.Whiting/bin
  PATH=$PATH:$UTILROOT/exec
  PATH=$PATH:`dirname $WGRIB2`
#  PATH=$PATH:/gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/anaconda3
  export PATH

#=====================================================#
elif [[ `hostname` =~ ^[l|s]login ]] ; then
#=====================================================#
  export MACHINE=cray

  #========== Surge/Luna ====================#
  export NOSCRUB=/gpfs/hps3/emc/global/noscrub/Yali.Mao
  if [ ! -e $HOMEnoscrub ] ; then
      export HOMEnoscrub=$NOSCRUB
  fi

  export TMP='/gpfs/hps/ptmp/Yali.Mao'

  export G2CTL=$HOMEnoscrub/git/save/grads/g2ctl.new

  export NWPROD=/gpfs/hps/nco/ops/nwprod
  export GADDIR=/usrx/local/dev/GrADS/data

  # run this bash before 'module load'
  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
  else
      . /opt/modules/default/init/bash
  fi

  module use -a /opt/cray/craype/default/modulefiles
  module use -a /opt/cray/ari/modulefiles
#  module use -a /opt/cray/alt-modulefiles
  module use -a /gpfs/hps/nco/ops/nwprod/modulefiles
  module use -a /usrx/local/prod/modulefiles

  module load PrgEnv-intel
  module load cray-mpich
#  module load NetCDF-intel-haswell/4.2
  module load xt-lsfhpc/9.1.3
#  module load subversion/1.8.16
  module load hpss/4.1.0.3

  module load gcc/6.3.0
  module load grib_util/1.1.0
  module load prod_util
  module load prod_envir


  module use /gpfs/hps3/emc/hwrf/noscrub/soft/modulefiles
  module load git/2.14.2

  module use -a /usrx/local/dev/modulefiles
  module load GrADS/2.0.2

  module load python/3.6.3

  PATH=$PATH:/gpfs/*1/u/Jeff.Whiting/bin
  PATH=$PATH:$UTILROOT/exec
  PATH=$PATH:`dirname $WGRIB2`
  export PATH

#=====================================================#
else
#=====================================================#
  export MACHINE=dell

  #========== Venus/Mars ====================#
  export NOSCRUB=$HOMEnoscrub
  export HOMEnoscrub=$NOSCRUB

  export TMP='/gpfs/dell3/ptmp/Yali.Mao'

  export G2CTL=$HOMEnoscrub/git/save/grads/g2ctl.new

  export NWPROD=/gpfs/dell1/nco/ops/nwprod
  export GADDIR=/usrx/local/dev/GrADS/2.0.2/lib

  # run this bash before 'module load'
  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
      . $MODULESHOME/init/profile
  else
      . /usrx/local/prod/lmod/lmod/init/bash
      . /usrx/local/prod/lmod/lmod/init/profile
  fi

  module use /usrx/local/dev/modulefiles

  module load ips/18.0.1.163
  module load impi/18.0.1
  module load NetCDF/4.5.0
  module load lsf/10.1

  module load EnvVars/1.0.2
  module load pm5/1.0
  module load subversion/1.7.16
  module load HPSS/5.0.2.5
  module load mktgs/1.0
  module load rsync/3.1.2
  module load prod_envir/1.0.2
  module load grib_util/1.0.6
  module load prod_util/1.1.0

  module use /gpfs/dell3/usrx/local/dev/emc_rocoto/modulefiles/
  module load ruby/2.5.1 rocoto/1.2.4

  module load git/2.14.3
  module load cmake/3.10.0
  module load GrADS/2.2.0

  module load python/3.6.3

  PATH=$PATH:/gpfs/*1/u/Jeff.Whiting/bin
  PATH=$PATH:$UTILROOT/exec
  PATH=$PATH:`dirname $WGRIB2`
  export PATH

  export GIT_EXEC_PATH=/usrx/local/dev/packages/git/2.14.3/libexec/git-core

#=====================================================#
fi
#=====================================================#
export HOMEgit=$HOMEnoscrub/git
export HOMEsave=$HOMEgit/save
export GRADS=$HOMEsave/grads

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/$NWPROD/lib

# Will not be used by 'alias'
export GIT=$NOSCRUB/git
export SAVE=$GIT/save
