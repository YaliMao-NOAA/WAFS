run=${1:-gfs}
bdate=${2:-2023010200}
edate=${2:-2023010200}
export allfhr=${3:-"012"}
export OUTPUT_FILE=${4:-"netcdf"}

#Input Data
#export COMINP=/u/Wen.Meng/noscrub/gfsnetcdf
#export COMINP=/lfs/h1/ops/canned/com/gfs/v16.2
export COMINP=/lfs/h1/ops/prod/com/gfs/v16.3

#Working directory
tmp=/lfs/h2/emc/ptmp/$USER
mkdir -p $tmp/outputs
diroutp=$tmp/outputs
cd $diroutp

#UPP location
export svndir=`pwd`
export svndir=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/UPP.v16
export rundir=/lfs/h2/emc/ptmp/yali.mao/upp

module load prod_util/2.0.5

while [[ $bdate -le $edate ]]; do
   yyyymmdd=`echo $bdate | cut -c1-8`
   sed -e "s|CURRENTDATE|$bdate|" \
       -e "s|STDDIR|$diroutp|" \
       -e "s|RRR|$run|" \
      $svndir/run_JGLOBAL_NCEPPOST_WCOSS2 >$diroutp/run_JGLOBAL_NCEPPOST_${run}.$bdate
   qsub $diroutp/run_JGLOBAL_NCEPPOST_${run}.$bdate
   bdate=`$NDATE +24 $bdate`
done
