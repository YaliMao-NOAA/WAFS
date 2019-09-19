#!/bin/ksh
#**************************************************************
# Transfer data/plot from WCOSS/Cray to RZDM by scp/rsync
#**************************************************************

user=`whoami`

#=====================================================#
if [[ `hostname` =~ ^[g|t][0-9]{1} ]] ; then
#     `cat /etc/dev` # gyre/tide/luna/surg
#=====================================================#

  #========== Gyre/Tide =====================#
  TMPdir=/ptmpp1/${user}

  if [ ! -z $MODULESHOME ]; then
    . $MODULESHOME/init/bash
  else
    . /usrx/local/Modules/default/init/bash
  fi
  module load lsf ics ibmpe

  module load prod_envir/v1.0.1

#=====================================================#
else
#=====================================================#

  #========== Surge/Luna ====================#
  TMPdir=/gpfs/hps/ptmp/$user

  if [ ! -z $MODULESHOME ]; then
    . $MODULESHOME/init/bash
  else
    . /opt/modules/default/init/bash
  fi

  module use -a /opt/cray/craype/default/modulefiles
  module use -a /opt/cray/ari/modulefiles
  module use -a /opt/cray/alt-modulefiles
  module use -a /gpfs/hps/nco/ops/nwprod/modulefiles
  module use -a /usrx/local/prod/modulefiles

  module load PrgEnv-intel
  module load cray-mpich
  module load xt-lsfhpc/9.1.3

  module load prod_envir/1.0.1

#=====================================================#
fi
#=====================================================#

COMINroot=$COMROOTp2
DCOMroot=$DCOMROOT/us007003

module load grib_util

set -x

function printUsage {
  set +x
  echo 'Usage: ftp_wafs.sh run product {-date YYYYMMDD[HH[FH]] | -dir DATAfolder | -file YYYYMMDD[HH[FH]] DATAfolder}'
  echo "'test plot' will be sent to web server grdplot/; all others will be to ftp server wafs.$run/$product.$PDY/"
  echo '  run: prod|para|test|...'
  echo '  product: uk | us | blend | master | gfip | gcip | ... '
  echo '  -date: only for prod|para (operational|NCO parallel) on a specific YYYYMMDD[HH[FH]]'
  echo '  -dir: to transfer the whole directory of DATAfolder'
  echo '  -file: to transfer files under DATAfolder on a specific YYYYMMDD[HH[FH]]'
  set -x
}
# samples:
# sh ftp_wafs.sh prod uk -date 20170312
# sh ftp_wafs.sh test gtg -dir /gpfs/tp1/ptmp/Yali.Mao/test/gtg.20170312
# sh ftp_wafs.sh test gtg -file 2017031206 /gpfs/hps/ptmp/Yali.Mao/gfs/test/gfs.20170312

#=======================================================
# Input arguments
#=======================================================
if [ $# -lt 3 ]; then
    printUsage
    exit
fi

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# run           ||  product
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# prod / para	||  uk | us | blend | master | gfip | gcip
# test      	||  gfip | gcip | gtg | plot
# verf          ||  vsdb | plot
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
run=$1
product=$2
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

cycles="00 06 12 18"
fhours="06 09 12 15 18 21 24 27 30 33 36"

option=$3

if [ $option = '-date' -o $option = '-file' ] ; then
    PDY=`echo $4 | cut -c1-8`
    hh=`echo $4 | cut -c9-10`
    fh=`echo $4 | cut -c11-12`
    if [[ -n $hh ]] ; then
	cycles="$hh"
	if [[ -n $fh ]] ; then
	    fhours="$fh"
	fi
    fi
    if [  $option = '-file' ] ; then
	 DATAfolder=$5
    fi
elif  [ $option = '-dir' ] ; then
    DATAfolder=$4
else
    printUsage
    exit
fi

# For GCIP analysis, fhours and cycles need to be re-defined.
if [ $product = gcip ] ; then
    fhours="00"
    for hh in $cycles ; do
	hhGCIP=$(( ${hh#0} + 3 ))
	hhGCIP=`printf "%02g" $hhGCIP`
	cyclesGCIP="$cyclesGCIP $hh $hhGCIP"
    done
    cycles=$cyclesGCIP
fi

#=======================================================
# prepare local folder, data folder,  fileTemplate 
#=======================================================

#-----------------------------------------------
if [ $option = '-dir' ] ; then 
#-----------------------------------------------
# To transfer the whole folder
    dataDir=$DATAfolder
    # remove all other path info except the last data folder info
    # plot will modify $remoteDir in the following session
    remoteDir=`echo $dataDir | sed "s/.*\///"`
    fileTemplate=
#-----------------------------------------------
elif [ $option = '-file' ] ; then 
#-----------------------------------------------
# To transfer individual files: *tHHz*fFH*
    dataDir=$DATAfolder
    # remove all other path info except the last data folder info
    # plot will modify $remoteDir in the following session
    remoteDir=$product.$PDY
    fileTemplate="*HHz*fFH*"
#-----------------------------------------------
elif [[ $run = prod || $run = para ]] ; then
#-----------------------------------------------
# Only for operational|NCO parallel !!!!
# If run=prod/para, fileTemplate is specified and individual files
#     will be transferred looping on $cycles $fhours
#     However for gfip, will extract info from master file into a 
#     temprary folder and transfer the whole temp folder
    dataDir=$COMINroot/gfs/$run/gfs.$PDY # default
    remoteDir=$product.$PDY              # default
    if [ $product = uk ] ; then
	dataDir=$DCOMroot/${PDY}/wgrbbul/ukmet_wafs
	remoteDir=ukmet.$PDY
	fileTemplate=EGRR_WAFS_unblended_PDY_HHz_tFH.grib2
    elif [ $product = us ] ; then
	remoteDir=gfs.$PDY
	fileTemplate=gfs.tHHz.wafs_grb45fFH.grib2
    elif [ $product = blend ] ; then
	fileTemplate=WAFS_blended_${PDY}HHfFH.grib2
    elif [ $product = master ] ; then
	fileTemplate=gfs.tHHz.master.grb2fFH
    elif [[ $product = icing || $product = gfip || $product = gfis ]] ; then
	if [ $product = icing ] ; then
	    cat1=":ICIP:\|:ICSEV:"
	elif [ $product = gfip ] ; then
	    cat1=":ICIP:"
	elif [ $product = gfis ] ; then
	    cat1=":ICSEV:"
	fi
	# will extract gfip and gfis info from master file
	fileTemplate=gfs.tHHz.master.grb2fFH
	dataDir_tmp=$TMPdir/icing.ftp.tmp$PDY
	mkdir -p $dataDir_tmp
	cd $dataDir_tmp
	for hh in $cycles ; do
	for fh in $fhours ; do
	    file2ftp=`echo $fileTemplate | sed -e "s|PDY|$PDY|g" -e "s|HH|$hh|g" -e "s|FH|$fh|g"`
	    $WGRIB2 $dataDir/$file2ftp | grep $cat1 | $WGRIB2 -i $dataDir/$file2ftp -grib $file2ftp
	done
	done
	# set fileTemplate to NULL and will transfer the whole folder
	dataDir=$dataDir_tmp
	fileTemplate=
    elif [ $product = gcip ] ; then
	fileTemplate=gfs.tHHz.gcip.fFH.grib2
    fi
#-----------------------------------------------
else
#-----------------------------------------------
# If no data folder is specified and not prod/para run, error and exit
    printUsage
    exit
fi

#=======================================================
# remote server and folder:
# 'test plot' will be sent to web server; 
# all others will be to ftp server"
#=======================================================
remoteServer=ymao@emcrzdm

if [[ $run = 'test' && $product = 'plot' ]] ; then
    remoteDir=/home/www/emc/htdocs/gmb/icao/grdplot
else
    remoteDir=/home/ftp/emc/unaff/ymao/wafs.$run/$remoteDir
fi

# create a corresponding data file/directory on RZDM
ssh $remoteServer "mkdir -p $remoteDir"

#=======================================================
# transfer data
#=======================================================
if  [[ -n $fileTemplate ]] ; then
   for hh in $cycles ; do
   for fh in $fhours ; do
      file2ftp=`echo $fileTemplate | sed -e "s|PDY|$PDY|g" -e "s|HH|$hh|g" -e "s|FH|$fh|g"`
      scp -p `ls $dataDir/$file2ftp | grep $PDY` ${remoteServer}:$remoteDir/.
   done
   done
else
   rsync -avP $dataDir/. ${remoteServer}:$remoteDir/.
   # For operational gfip, remove the temprary working folder.
   if [[ $run = prod || $run = para ]] ; then
       if [[ $product = icing || $product = gfip || $product = gfis ]] ; then
	   rm -r $dataDir
       fi
   fi
fi
