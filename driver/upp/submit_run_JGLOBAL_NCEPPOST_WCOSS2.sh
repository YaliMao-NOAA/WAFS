run=${1:-gfs}
bdate=${2:-2023042600}
edate=${2:-2023042600}
export allfhr=${3:-"018"}
export OUTPUT_FILE=${4:-"netcdf"}

export RUN=gfs

#Input Data
#export COMINP=/u/Wen.Meng/noscrub/gfsnetcdf
#export COMINP=/lfs/h1/ops/canned/com/gfs/v16.2
export COMINP=/lfs/h1/ops/prod/com/gfs/v16.3
#export COMIN=/u/wen.meng/noscrub/ncep_post/post_regression_test_new/data_in/gfs
export COMIN=/lfs/h2/emc/vpppg/noscrub/yali.mao/gtg4/gfs.20230426

#Working directory
tmp=/lfs/h2/emc/ptmp/$USER
mkdir -p $tmp/outputs
diroutp=$tmp/outputs
cd $diroutp

#UPP location
export svndir=`pwd`
export svndir=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/UPP.v17
export rundir=/lfs/h2/emc/ptmp/yali.mao/upp
#Spedify numx
export numx=1
#exec file
export exec=ncep_post
export exec=upp.x

cp $svndir/sorc/ncep_post.fd/post_gtg.fd/gtg.config.$RUN $svndir/parm/.
cp $svndir/sorc/ncep_post.fd/post_gtg.fd/gtg.input.$RUN $svndir/parm/.

#cp $svndir/parm/imprintings.gtg_${RUN}.txt $svndir/parm/.
#gtg
cp $svndir/parm/postxconfig-NT-${RUN^^}-WAFS.txt.gtg $svndir/parm/postxconfig-NT-${RUN^^}-WAFS.txt
#no gtg
#cp $svndir/parm/postxconfig-NT-${RUN^^}-WAFS.txt.nogtg $svndir/parm/postxconfig-NT-${RUN^^}-WAFS.txt

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
