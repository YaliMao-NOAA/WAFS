run=${1:-gfs}
bdate=${2:-2023020106}
edate=${2:-2023020106}
export allfhr=${3:-"012"}
#bdate=${2:-2022012112}
#edate=${2:-2022012112}
#export allfhr=${3:-"036"}
export OUTPUT_FILE=${4:-"netcdf"}

#Input Data
#export COMINP=/u/Wen.Meng/noscrub/gfsnetcdf
#export COMINP=/lfs/h1/ops/canned/com/gfs/v16.2
export COMINP=/lfs/h1/ops/prod/com/gfs/v16.3
#export COMIN=/u/wen.meng/noscrub/ncep_post/post_regression_test_new/data_in/gfs
export COMIN=/lfs/h2/emc/vpppg/noscrub/yali.mao/gtg4data/gefs_fv3_v12/20230201
#export COMIN=/lfs/h2/emc/vpppg/noscrub/yali.mao/gefs13_c384_sample/gefs.20220121

#Working directory
tmp=/lfs/h2/emc/ptmp/$USER
mkdir -p $tmp/outputs
diroutp=$tmp/outputs
cd $diroutp

#UPP location
export svndir=`pwd`
export svndir=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/UPP
export rundir=/lfs/h2/emc/ptmp/yali.mao/upp
#Spedify numx
export numx=1
#exec file
export exec=ncep_post
export exec=upp.x

cp $svndir/sorc/ncep_post.fd/post_gtg.fd/gtg.config.gefs $svndir/parm/gtg.config.gfs

cp $svndir/parm/gtg_imprintings.txt.gefs $svndir/parm/gtg_imprintings.txt
#gtg
cp $svndir/parm/postxconfig-NT-GEFS.txt.gtg $svndir/parm/postxconfig-NT-GFS.txt
cp $svndir/parm/postxconfig-NT-GFS-WAFS.txt.gtg $svndir/parm/postxconfig-NT-GFS-WAFS.txt
#no gtg
#cp $svndir/parm/postxconfig-NT-GEFS.txt.nogtg $svndir/parm/postxconfig-NT-GFS.txt
#cp $svndir/parm/postxconfig-NT-GFS-WAFS.txt.nogtg $svndir/parm/postxconfig-NT-GFS-WAFS.txt

module load prod_util/2.0.5

while [[ $bdate -le $edate ]]; do
   yyyymmdd=`echo $bdate | cut -c1-8`
   sed -e "s|CURRENTDATE|$bdate|" \
       -e "s|STDDIR|$diroutp|" \
       -e "s|RRR|$run|" \
      $svndir/gefs.run_JGLOBAL_NCEPPOST_WCOSS2 >$diroutp/run_JGLOBAL_NCEPPOST_${run}.$bdate
   qsub $diroutp/run_JGLOBAL_NCEPPOST_${run}.$bdate
   bdate=`$NDATE +24 $bdate`
done
