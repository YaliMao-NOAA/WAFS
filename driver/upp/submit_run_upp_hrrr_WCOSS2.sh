#!/bin/sh 
 
#PBS -j oe
#PBS -N upp_hrrr
#PBS -l walltime=00:30:00
#PBS -q debug
#PBS -A GFS-DEV
#PBS -l place=vscatter,select=2:ncpus=60
#PBS -V

cd $PBS_O_WORKDIR

set -x
ncpus=120
ppn=$(( ncpus / 2 ))

# specify computation resource
export threads=1
export OMP_NUM_THREADS=$threads
export APRUN="mpiexec -l -n $ncpus -ppn $ppn"

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
module load hdf5/1.10.6
module load netcdf/4.7.4
module load libjpeg/9c
module load prod_util/2.0.8
modue load wgrib2/2.0.7
module list

# specify your UPP directory
export gitdir=/lfs/h2/emc/ptmp/yali.mao/UPP.fork
export POSTGPEXEC=${gitdir}/exec/upp.x

export rundir=/lfs/h2/emc/ptmp/$USER/upp_hrrr

#Input Data
export datain=/u/wen.meng/noscrub/ncep_post/hrrr/hrrr_ops #on Dogwood
#export datain=/lfs/h2/emc/ptmp/yali.mao/hrrr_ops

# specify forecast start time and hour for running your post job
export startdate=2024120818
export fhr=006

# specify your running and output directory
export DATA=$rundir/working_${startdate}
rm -rf $DATA; mkdir -p $DATA
cd $DATA

export NEWDATE=`${NDATE} +${fhr} $startdate`

export YY=`echo ${NEWDATE} | cut -c1-4`
export MM=`echo ${NEWDATE} | cut -c5-6`
export DD=`echo ${NEWDATE} | cut -c7-8`
export HH=`echo ${NEWDATE} | cut -c9-10`

cat > itag <<EOF
&model_inputs
fileName='$datain/hrrr_${startdate}f${fhr}'
IOFORM='netcdf'
grib='grib2'
DateStr='${YY}-${MM}-${DD}_${HH}:00:00'
MODELNAME='RAPR'
SUBMODELNAME='RAPR'
/
&NAMPGB
KPO=47,PO=2.,5.,7.,10.,20.,30.,50.,70.,75.,100.,125.,150.,175.,200.,225.,250.,275.,300.,325.,350.,375.,400.,425.,450.,475.,500.,525.,550.,575.,600.,625.,650.,675.,700.,725.,750.,775.,800.,825.,850.,875.,900.,925.,950.,975.,1000.,1013.2,gtg_on=.true.,
/
EOF
#FMIN

#copy fix data
cp /u/wen.meng/noscrub/ncep_post/post_regression_test_new/fix/fix_2.3.0/*bin .
cp ${gitdir}/parm/params_grib2_tbl_new params_grib2_tbl_new
#cp ${gitdir}/parm/postxconfig-NT-hrrr.txt postxconfig-NT.txt
#cp ${gitdir}/fix/rap_micro_lookup.dat eta_micro_lookup.dat

# GTG
cp ${gitdir}/parm/postxconfig-NT-hrrr_dafs.txt postxconfig-NT.txt
cp ${gitdir}/sorc/ncep_post.fd/post_gtg.fd/gtg.config.hrrr ./gtg.config.hrrr
cp ${gitdir}/sorc/ncep_post.fd/post_gtg.fd/gtg.input.hrrr ./.

${APRUN} ${POSTGPEXEC} < itag > wrfpost2.out

date

exit

cp $datain/hrrr_remove_duplicates.new hrrr_remove_duplicates
fhr2=$(printf %02i $fhr)
file=WRFTWO.GrbF${fhr2}
cp $file hrrrsfc.1
wgrib2 hrrrsfc.1 | grep -F -f hrrr_remove_duplicates | wgrib2 -i -grib WRFTWOlite hrrrsfc.1
cat WRFPRS.GrbF${fhr2} WRFTWOlite > wrfprsf${fhr2}.grib2
cat WRFNAT.GrbF${fhr2} WRFTWOlite > wrfnatf${fhr2}.grib2
cp $file wrfsfcf${fhr2}.grib2
