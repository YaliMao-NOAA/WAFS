
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

LS_COLORS="rs=0:di=38;5;27:ln=35:mh=44;38;5;15:pi=40;38;5;11:so=38;5;13:do=38;5;5:bd=48;5;232;38;5;11:cd=48;5;232;38;5;3:or=48;5;232;38;5;9:mi=05;48;5;232;38;5;15:su=48;5;196;38;5;15:sg=48;5;11;38;5;16:ca=48;5;196;38;5;226:tw=48;5;10;38;5;16:ow=48;5;10;38;5;21:st=48;5;21;38;5;15:ex=38;5;34:*.tar=38;5;9:*.tgz=38;5;9:*.arc=38;5;9:*.arj=38;5;9:*.taz=38;5;9:*.lha=38;5;9:*.lz4=38;5;9:*.lzh=38;5;9:*.lzma=38;5;9:*.tlz=38;5;9:*.txz=38;5;9:*.tzo=38;5;9:*.t7z=38;5;9:*.zip=38;5;9:*.z=38;5;9:*.Z=38;5;9:*.dz=38;5;9:*.gz=38;5;9:*.lrz=38;5;9:*.lz=38;5;9:*.lzo=38;5;9:*.xz=38;5;9:*.bz2=38;5;9:*.bz=38;5;9:*.tbz=38;5;9:*.tbz2=38;5;9:*.tz=38;5;9:*.deb=38;5;9:*.rpm=38;5;9:*.jar=38;5;9:*.war=38;5;9:*.ear=38;5;9:*.sar=38;5;9:*.rar=38;5;9:*.alz=38;5;9:*.ace=38;5;9:*.zoo=38;5;9:*.cpio=38;5;9:*.7z=38;5;9:*.rz=38;5;9:*.cab=38;5;9:*.jpg=38;5;13:*.jpeg=38;5;13:*.gif=38;5;13:*.bmp=38;5;13:*.pbm=38;5;13:*.pgm=38;5;13:*.ppm=38;5;13:*.tga=38;5;13:*.xbm=38;5;13:*.xpm=38;5;13:*.tif=38;5;13:*.tiff=38;5;13:*.png=38;5;13:*.svg=38;5;13:*.svgz=38;5;13:*.mng=38;5;13:*.pcx=38;5;13:*.mov=38;5;13:*.mpg=38;5;13:*.mpeg=38;5;13:*.m2v=38;5;13:*.mkv=38;5;13:*.webm=38;5;13:*.ogm=38;5;13:*.mp4=38;5;13:*.m4v=38;5;13:*.mp4v=38;5;13:*.vob=38;5;13:*.qt=38;5;13:*.nuv=38;5;13:*.wmv=38;5;13:*.asf=38;5;13:*.rm=38;5;13:*.rmvb=38;5;13:*.flc=38;5;13:*.avi=38;5;13:*.fli=38;5;13:*.flv=38;5;13:*.gl=38;5;13:*.dl=38;5;13:*.xcf=38;5;13:*.xwd=38;5;13:*.yuv=38;5;13:*.cgm=38;5;13:*.emf=38;5;13:*.axv=38;5;13:*.anx=38;5;13:*.ogv=38;5;13:*.ogx=38;5;13:*.aac=38;5;45:*.au=38;5;45:*.flac=38;5;45:*.mid=38;5;45:*.midi=38;5;45:*.mka=38;5;45:*.mp3=38;5;45:*.mpc=38;5;45:*.ogg=38;5;45:*.ra=38;5;45:*.wav=38;5;45:*.axa=38;5;45:*.oga=38;5;45:*.spx=38;5;45:*.xspf=38;5;45:"

export VSDBsave=/gpfs/dell2/emc/modeling/noscrub/Yali.Mao/vsdb

export HOMEnoscrub=/gpfs/dell2/emc/modeling/noscrub/Yali.Mao

#=====================================================#
if [[ `hostname` =~ ^h ]] ; then
#=====================================================#
  export MACHINE=hera
  alias quotas='cat /scratch2/BMC/public/quotas/stmp'

  alias sjobs='squeue -u Yali.Mao'

  #========== Hera ====================#
  export VSDBsave=/scratch1/NCEPDEV/global/Yali.Mao/vsdb
  export HOMEnoscrub=/scratch1/NCEPDEV/global/Yali.Mao

  export NOSCRUB=$HOMEnoscrub
  export HOMEnoscrub=$NOSCRUB

  export HOMEgit=/scratch2/NCEPDEV/ovp/Yali.Mao/git
  export G2CTL=$HOMEgit/save/grads/g2ctl.hera

  export TMP='/scratch2/NCEPDEV/stmp3/Yali.Mao'

  export NWPROD=/scratch4/NCEPDEV/rstprod/nwprod
  export COMROOT=/scratch1/NCEPDEV/rstprod/com

  # run this bash before 'module load'
  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
      . $MODULESHOME/init/profile
  else
      . /apps/lmod/7.7.18/init/bash
      . /apps/lmod/7.7.18/init/profile
  fi

  module use /apps/modules/modulefiles
  module load intel/18.0.5.274
#  module load gcc/6.2.0
  module load grads/2.2.1
  module load ncl
  module load hpss
#  module load svn
#  module load slurm
  module load rocoto

  module use /apps/modules/modulefamilies/intel
  module load impi/2018.0.4
  module load netcdf
  module load R/3.5.0

  module use /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles
  module load grib_util/1.1.1
  alias wgrib2=$WGRIB2
  module load prod_util/1.1.0
  module load g2tmpl/1.5.0
# load python which needs contrib and anaconda/latest
  module load contrib
  module load anaconda/latest

  # Install LD_LIBRARY_PATH to solve runtime error:  
  #   error while loading shared libraries: libiomp5.so: cannot open shared object file
  # It works for /scratch2/NCEPDEV/ovp/Yali.Mao/git/verf_g2g.v3.0.12/exec/verf_g2g_grid2grid_grib2
  source /opt/intel/bin/compilervars.sh intel64

#=====================================================#
elif [[ `hostname` =~ ^O ]] ; then
#=====================================================#
  export MACHINE=orion
  alias quotas='cat /scratch2/BMC/public/quotas/stmp'

  alias sjobs='squeue -u ymao'

  #========== Orion ====================#
#  export VSDBsave=/scratch1/NCEPDEV/global/Yali.Mao/vsdb
  export HOMEnoscrub=/work/noaa/stmp/ymao

  export NOSCRUB=$HOMEnoscrub
  export HOMEnoscrub=$NOSCRUB

  export HOMEgit=/work/noaa/stmp/ymao/git
  export G2CTL=$HOMEgit/save/grads/g2ctl.orion

  export TMP='/work/noaa/stmp/ymao/stmp'

#  export NWPROD=/scratch4/NCEPDEV/rstprod/nwprod
#  export COMROOT=/scratch1/NCEPDEV/rstprod/com

  # run this bash before 'module load'
  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
      . $MODULESHOME/init/profile
  else
      . /apps/lmod-8.1/lmod-8.1/init/bash
      . /apps/lmod-8.1/lmod-8.1/Init/profile
  fi

  module load contrib noaatools

  module load intel/2018.4
  module load impi/2018.4

  module load grads/2.2.1
  module load ncl
#  module load hpss
##  module load slurm
  module load rocoto/1.3.1
  module load netcdf/4.7.2-parallel
  module load r/3.5.2

  module use -a /apps/contrib/NCEPLIBS/orion/modulefiles
  module load grib_util/1.2.0
  alias wgrib2=$WGRIB2
  module load prod_util/1.2.0
  module load g2tmpl/1.7.0

# load python which needs contrib and anaconda/latest
#  module load anaconda/latest

  # Install LD_LIBRARY_PATH to solve runtime error:  
  #   error while loading shared libraries: libiomp5.so: cannot open shared object file
  # It works for /scratch2/NCEPDEV/ovp/Yali.Mao/git/verf_g2g.v3.0.12/exec/verf_g2g_grid2grid_grib2
#  source /opt/intel/bin/compilervars.sh intel64

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

  export HOMEgit=$HOMEnoscrub/git
  export G2CTL=$HOMEgit/save/grads/g2ctl

  export TMP='/ptmpp1/Yali.Mao'
  #export SSAVE='/sss/emc/global/shared/Yali.Mao/save'
  #alias ssave='cd $SSAVE'

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

  export HOMEgit=$HOMEnoscrub/git
  export G2CTL=$HOMEgit/save/grads/g2ctl.new

  export TMP='/gpfs/hps/ptmp/Yali.Mao'

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

  export HOMEgit=$HOMEnoscrub/git
  export G2CTL=$HOMEgit/save/grads/g2ctl.new

  export TMP='/gpfs/dell3/ptmp/Yali.Mao'

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
export HOMEsave=$HOMEgit/save
export GRADS=$HOMEsave/grads

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/$NWPROD/lib

# Will not be used by 'alias'
export GIT=$HOMEgit
export SAVE=$GIT/save
