#!/bin/sh

#PBS -j oe
#PBS -o /lfs/h2/emc/ptmp/yali.mao/extract.dcom.log.2021110800
#PBS -N extract_dcom
#PBS -l walltime=02:30:00
#PBS -l select=1:ncpus=1:mem=15GB
#PBS -q dev_transfer
#PBS -A GFS-DEV

set -x
CDATE=2021110800
YY=`echo $CDATE | cut -c1-4`
YYMM=`echo $CDATE | cut -c1-6`
PDY=`echo $CDATE | cut -c1-8`
CYC=`echo $CDATE | cut -c9-10`
CYC2=$(( 3 + $CYC ))
CYC2="$(printf "%02d" $(( 10#$CYC2 )) )"
echo $PDY $CYC $CYC2

com_radar=/lfs/h2/emc/vpppg/noscrub/yali.mao/com_radar
dcomfolder=/lfs/h2/emc/vpppg/noscrub/yali.mao/dcom/$PDY


# extract radar data for GCIP
mkdir -p $com_radar/radarl2/v1.2/radar.$PDY
cd $com_radar/radarl2/v1.2/radar.$PDY
tarball=/NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/com_hourly_prod_radar.$PDY.save.tar
htar -xvf $tarball ./refd3d.t${CYC}z.grb2f00 ./refd3d.t${CYC2}z.grb2f00 


# extract satellite data for GCIP
mkdir -p $dcomfolder
cd $dcomfolder
htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./mcidas/*$PDY$CYC ./mcidas/*$PDY$CYC2

# extract bufr files for GCIP
htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./b000/xx0*
htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./b000/xx1*
htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./b001/*
#htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./b002/*
htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./b003/*
htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./b004/*
#htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./b005/*
#htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./b006/*
htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./b007/*

# extract UK data for 2 blending jobs
htar -xvf /NCEPPROD/hpssprod/runhistory/rh$YY/$YYMM/$PDY/dcom_prod_$PDY.tar ./wgrbbul/ukmet_wafs/*_${CYC}z*
