#!/bin/sh

#PBS -j oe
##PBS -o out.upp.wafs
#PBS -N upp_wafs_gfs
#PBS -l walltime=00:30:00
#PBS -q debug
#PBS -A GFS-DEV
#PBS -l place=vscatter:exclhost,select=6:ompthreads=1:ncpus=24:mem=480GB
#PBS -V

cd $PBS_O_WORKDIR

export run=gfs
export RUN=GFS

set -x
nnodes=6
ncpus=24
ntasks=$(( ncpus * nnodes ))

# specify computation resource
export threads=1
export MP_LABELIO=yes
export OMP_NUM_THREADS=$threads
export APRUN="mpiexec -ppn $ncpus -n $ntasks"

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
module load prod_envir/2.0.6
module load libjpeg/9c
module load grib_util/1.2.2
module load wgrib2/2.0.8
module list

# specify your UPP directory
export gitdir=/lfs/h2/emc/vpppg/noscrub/yali.mao/git/UPP.fork
export POSTGPEXEC=${gitdir}/exec/upp.x

export rundir=/lfs/h2/emc/ptmp/$USER/upp_wafs

#Input Data
# specify forecast start time and hour for running your post job
if [ $run = 'gfs' ] ; then
    export startdate=2023042600
    export COMIN=/lfs/h2/emc/vpppg/noscrub/yali.mao/gtg4/gfs.20230426
    export fhr=018
else #gefs
    export startdate=2022012112
    export COMIN=/lfs/h2/emc/vpppg/noscrub/yali.mao/gefs13_c384_sample/gefs.20220121
    export fhr=036
fi
export cyc=`echo $startdate |cut -c9-10`

#specify your running and output directory
export DATA=$rundir/working_${run}_${startdate}.test
rm -rf $DATA; mkdir -p $DATA
cd $DATA

export NEWDATE=`${NDATE} +${fhr} $startdate`
export YY=`echo $NEWDATE | cut -c1-4`
export MM=`echo $NEWDATE | cut -c5-6`
export DD=`echo $NEWDATE | cut -c7-8`
export HH=`echo $NEWDATE | cut -c9-10`

cat > itag <<EOF
&model_inputs
fileName='$COMIN/gfs.t${cyc}z.atmf${fhr}.nc'
IOFORM='netcdf'
grib='grib2'
DateStr='${YY}-${MM}-${DD}_${HH}:00:00'
MODELNAME='GFS'
SUBMODELNAME="$RUN"
fileNameFlux='$COMIN/gfs.t${cyc}z.sfcf${fhr}.nc'
/
&NAMPGB
KPO=56,PO=84310.,81200.,78190.,75260.,72430.,69680.,67020.,64440.,61940.,59520.,57180.,54920.,52720.,50600.,48550.,46560.,44650.,42790.,41000.,39270.,37600.,3\
5990.,34430.,32930.,31490.,30090.,28740.,27450.,26200.,25000.,23840.,22730.,21660.,20650.,19680.,18750.,17870.,17040.,16240.,15470.,14750.,14060.,13400.,12770.,12170.,11600.,11050.,10530.,1\
0040.,9570.,9120.,8700.,8280.,7900.,7520.,7170.,gtg_on=.true.,popascal=.true., numx=1
/
EOF

rm -f fort.*

###------------------------------------------------------
#cp ${gitdir}/fix/nam_micro_lookup.dat ./eta_micro_lookup.dat
cp ${gitdir}/parm/params_grib2_tbl_new ./params_grib2_tbl_new

###------------------------------------------------------
# control flat files
if [  $fhr -le 48  ] ; then
    cp ${gitdir}/parm/$run/postxconfig-NT-${run}-wafs.txt ./postxconfig-NT.txt
else
    cp ${gitdir}/parm/gfs/postxconfig-NT-gfs-wafs-ext.txt ./postxconfig-NT.txt
fi

###----- copy GTG config file ----------------------
cp ${gitdir}/sorc/ncep_post.fd/post_gtg.fd/gtg.config.${run} ./gtg.config.${run}
cp ${gitdir}/sorc/ncep_post.fd/post_gtg.fd/gtg.input.${run} ./.
cp ${gitdir}/sorc/ncep_post.fd/post_gtg.fd/imprintings.gtg_${run}.txt .

${APRUN} ${POSTGPEXEC} < itag > outpost_wafs_${NEWDATE}

fhr2="$(printf "%02d" $(( 10#$fhr )) )"
mv GFSPRS.GrbF$fhr2 wafs.t${cyc}z.master.f$fhr.grib2

echo "PROGRAM IS COMPLETE!!!!!"
date

