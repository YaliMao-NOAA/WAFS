#!/bin/sh

#----------------------------------------------------------------------
#----------------------------------------------------------------------
#     NCEP EMC GLOBAL MODEL VERIFICATION SYSTEM
#            Fanglin Yang, April 2007
#
#  The script computes stats using VSDB database from multiple
#  runs and make maps using GrADS.
#----------------------------------------------------------------------
#----------------------------------------------------------------------
. /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/envir_setting.sh
set -xa

LOGNAME=`whoami`
WEBSERVER="ymao@emcrzdm"
WEBDIR="/home/www/emc/htdocs/gmb/icao"
export doftp="YES"
export doftp="NO"

############# Set up environments ##################

# From save/envir_setting.sh
echo $VSDBsave     #where vsdb database is saved
echo $NWPROD
echo $TMP
echo $GrADS_ROOT

export vsdbhome=$GIT/verf_g2g.v3.0.12	#script home
export PTMP=`dirname $TMP`		#temporary directory without user name
export GRADSBIN=$GrADS_ROOT/bin		#GrADS executables

#image magic converter
if [ $MACHINE = dell ] ; then
  imagemagick=imagemagick/6.9.9-25
  module load python/2.7.14
  export PYTHON=python
elif [ $MACHINE = cray ] ; then
  imagemagick=imagemagick-intel-haswell/6.8.3
  module load python/2.7.14
  export PYTHON=python
elif [ $MACHINE = wcoss ] ; then
  imagemagick=imagemagick/6.8.3-3
  export PYTHON=/usr/bin/python
fi
export IMGCONVERT=`modd $imagemagick  2>&1 | grep bin | sed s/[\(\",\)]/\ /g | awk '{print $3}'`

export FC=ifort							# intel compiler
export FFLAG="-O2 -convert big_endian -FR"			# intel compiler options


## -- data and output directories
#gather vsdb stats and put in a central location
envirp=$1
envirv=$2
rundir0=${rundir:-$PTMP/${LOGNAME}/vsdb_plot_$envirp.$envirv}    ;#temporary workplace
vsdball=$rundir0/vsdb_data
mkdir -p $vsdball; cd $vsdball || exit 8
if [ -s  $vsdball/wafs ] ; then rm $vsdball/wafs ; fi
ln -fs $VSDBsave/wafs/$envirp.$envirv  $vsdball/wafs
export vsdb_data=$vsdball/wafs                            ;#where all vsdb data are
export makemap=${makemap:-"YES"}                          ;#whether or not to make maps
export mapdir=${mapdir:-${rundir0}/web}                   ;#place where maps are saved locally
export scorecard=${scorecard:-YES}                        ;#create scorecard text files
export scoredir=${scoredir:-$rundir0/score}               ;#place to save scorecard output
mkdir -p $rundir0 $mapdir $scoredir

## -- verification dates
export sdate=${sdate:-20181201}				;#forecast starting date
export edate=${edate:-20181231}				;#forecast ending date
export vlength=${vlength:-36}				;#forecast length in hour
#  observation choices: gfs gcip gcipconus cip
export observation=${observation:-"gfs"}
if [ $observation = gfs ] ; then
  fcycle="00 06 12 18" ;#forecast cycles for wind t
else
  fcycle="00 03 06 09 12 15 18 21" ;#forecast cycles for icip
fi
export fcycle=${3:-$fcycle}                                ;#forecast cycles

## -- verification parameters (dynamic ones)

errdir=$PTMP/$LOGNAME
#=====================================================
##--split observation data to speed up computation
for obsv in $observation ; do

  export obsvfolder=$obsv # keep gcipall for folder

  if [[ $obsv == gcip || $obsv == gfs || $obsv == gcipall ]] ; then
    regions="G45 G45/NHM G45/TRP G45/SHM G45/AR2 G45/ASIA G45/NPCF G45/AUNZ G45/NAMR"
  else
    regions="G130"
  fi

  if [[ $obsv == gfs ]] ; then
    models="twind"
  elif [[ $obsv == gcip ]] ; then
#    models="blndmax blndmean ukmax ukmean usmax usmean usfip"
    models="blndmax blndmean"
#    models="usmax usmean"
  elif [[ $obsv == gcipall ]] ; then
    obsv=gcip
    models="ukmax ukmean usmax usmean blndmax blndmean"
  else
    models="ukmax ukmean usmax usmean blndmax blndmean"
  fi

  export obsvlist=$obsv # gcipall => gcip
  export mdlist=$models

for region in  $regions ; do
#=====================================================
    reg1=`echo $region | sed "s?/??g"`
    export reglist="$region"

    export rundir=${rundir0}/$obsv.$reg1
    mkdir -p $rundir

# ------------------------------------------------------------------------------
    if [ $obsv = gfs ] ; then
#A) rms and bias of WIND and T ( for gfs only)
# ------------------------------------------------------------------------------
      export vhrlist="00 06 12 18"
      export vtype=pres
      export vnamlist="T WIND"
      export levlist="P850 P700 P600 P500 P400 P300 P250 P200 P150 P100"
      bsubstring=vsdbplot.$obsv.$reg1.twind
    else
# ------------------------------------------------------------------------------
#B) ROC of icing potential
      export vhrlist="00 03 06 09 12 15 18 21"
      export vtype=pres
      export vnamlist="ICIP"
      export levlist="P800 P700 P600 P500 P400"
      bsubstring=vsdbplot.$obsv.$reg1.icip
    fi

    cd $rundir0
    plotscript=allcenters_rmsmap.sh
    cp $vsdbhome/grads/$plotscript ./$plotscript.$obsv

    # change all related variables in allcenters_rmsmap.sh
    genericlist="WEBSERVER WEBDIR doftp"
    genericlist="$genericlist vsdbhome NWPROD PTMP GRADSBIN IMGCONVERT FC FFLAG PYTHON"
    genericlist="$genericlist vsdb_data makemap mapdir scorecard scoredir"
    genericlist="$genericlist sdate edate vlength fcycle"
    specificlist="obsvlist mdlist reglist rundir vhrlist vtype vnamlist levlist"
    for var in $genericlist $specificlist ; do
      value=`eval echo '$'$var`
      sed -e "s|export $var=|export $var=\"$value\"|g" \
	  -i $plotscript.$obsv
    done

    # change err and out file name and job name for a bsub
    sed -e "s|#BSUB -eo |#BSUB -eo $errdir/$bsubstring.err|g" \
	-e "s|#BSUB -oo |#BSUB -oo $errdir/$bsubstring.out|g" \
	-e "s|#BSUB -J |#BSUB -J $bsubstring|g" \
	-i $plotscript.$obsv

    ./$plotscript.$obsv


#    . ~/.bashrc
#    bsub < $plotscript.$obsv

#=====================================================
done  #end of region
done  #end of obsv
#====================================================

exit
