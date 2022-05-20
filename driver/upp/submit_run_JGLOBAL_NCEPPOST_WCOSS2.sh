run=${1:-gfs}
bdate=${2:-2022050306}
edate=${2:-2022050306}
export allfhr=${3:-"027 039"}
export OUTPUT_FILE=${4:-"netcdf"}

#Input Data
#export COMINP=/u/Wen.Meng/noscrub/gfsnetcdf
#export COMINP=/lfs/h1/ops/canned/com/gfs/v16.2
export COMINP=/lfs/h1/ops/prod/com/gfs/v16.2

#Working directory
tmp=/lfs/h2/emc/ptmp/Yali.Mao
mkdir -p $tmp/outputs
diroutp=$tmp/outputs

#UPP location
export svndir=`pwd`
export rundir=/lfs/h2/emc/ptmp/Yali.Mao/upp

module load prod_util/2.0.5

while [[ $bdate -le $edate ]]; do
   yyyymmdd=`echo $bdate | cut -c1-8`
   sed -e "s|CURRENTDATE|$bdate|" \
       -e "s|STDDIR|$diroutp|" \
       -e "s|RRR|$run|" \
      run_JGLOBAL_NCEPPOST_WCOSS2 >$tmp/outputs/run_JGLOBAL_NCEPPOST_${run}.$bdate
   qsub $tmp/outputs/run_JGLOBAL_NCEPPOST_${run}.$bdate
   bdate=`$NDATE +24 $bdate`
done
