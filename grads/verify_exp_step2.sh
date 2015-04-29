#!/bin/ksh
set -x

#----------------------------------------------------------------------
#----------------------------------------------------------------------
#     NCEP EMC GLOBAL MODEL VERIFICATION SYSTEM
#            Fanglin Yang, April 2007
#
#  The script computes stats using VSDB database from multiple
#  runs and make maps using GrADS.
#----------------------------------------------------------------------
#----------------------------------------------------------------------

LOGNAME=`whoami`

## -- script directories
export vsdbhome=${vsdbhome:-/global/save/$LOGNAME/project/verif_g2g.v3.0.0} ;#script home
export sorcdir=$vsdbhome/grads

## -- verification dates
export sdate=${sdate:-${1:-20150412}}                ;#forecast starting date
export edate=${edate:-${2:-20150425}}                ;#forecast ending date
export vlength=${vlength:-${3:-36}}                  ;#forecast length in hour
export fcycle=${fcycle:-${cyclist:-${4:-"all"}}}     ;#forecast cycles
export observations=${observations:-${5:-"gfs gcip gcipconus cip"}}

export rundir0=${rundir:-/ptmpp1/${LOGNAME}/vsdb_plot}    ;#temporary workplace
# data source
export vsdbsave=${vsdbsave:-/global/save/$LOGNAME/vsdb/grid2grid}    ;#vsdb stats archive directory

## -- data and output directories
# tempory data target
export vsdb_data=${vsdb_data:-$rundir0/vsdb_data}
export makemap=${makemap:-"YES"}                          ;#whether or not to make maps
export mapdir=${mapdir:-${rundir0}/web}                   ;#place where maps are saved locally
export scorecard=${scorecard:-YES}                        ;#create scorecard text files
export scoredir=${scoredir:-$rundir0/score}               ;#place to save scorecard output
mkdir -p $rundir0 $mapdir $scoredir

#--------------------------------------
##---gather vsdb stats and put in a central location
vsdball=$vsdb_data
mkdir -p $vsdball; cd $vsdball ||exit 8
if [ -s  ${vsdball}/wafs ] ; then rm ${vsdball}/wafs ; fi
ln -fs $vsdbsave/wafs  ${vsdball}/.
export vsdb_data=$vsdball/wafs

## -- verification parameters (dynamic ones)

errdir=/ptmpp1/$LOGNAME
#=====================================================
##--split observation data to speed up computation
for obsv in $observations ; do
  export obsvlist=$obsv

  if [[ $obsv == gcip || $obsv == gfs ]] ; then
    regions="G45 G45/NHM G45/TRP G45/SHM G45/AR2 G45/ASIA G45/NPCF G45/AUNZ G45/NAMR"
  else
    regions=CONUS
  fi
  if [[ $obsv == gfs ]] ; then
    models="twind"
  else
    models="blndmax blndmean ukmax ukmean usfip usmax usmean"
  fi

##--split models and regions to speed up computation
#=====================================================
for model in $models ; do
  export mdlist=$model

for region in  $regions ; do
#=====================================================
    reg1=`echo $region | sed "s?/??g"`
    export reglist="$region"

    export rundir=${rundir0}/$obsv.$model.$reg1
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
    cp $vsdbhome/grads/$plotscript .

    # change all related variables
    genericlist="vsdbhome sorcdir sdate edate vlength fcycle vsdb_data makemap mapdir scorecard scoredir mdlist"
    specificlist="obsvlist reglist rundir vhrlist vtype vnamlist levlist"
    for var in $genericlist $specificlist ; do
      value=`eval echo '$'$var`
      sed -e "s|export $var=|export $var=\"$value\"|g" \
	  -i $plotscript
    done

    # change err and out file name and job name for a bsub
    sed -e "s|#BSUB -eo |#BSUB -eo $errdir/$bsubstring.err|g" \
	-e "s|#BSUB -oo |#BSUB -oo $errdir/$bsubstring.out|g" \
	-e "s|#BSUB -J |#BSUB -J $bsubstring|g" \
	-i $plotscript

    ./$plotscript

 #   bsub < $plotscript

#=====================================================
done  #end of region
done  #end of model 
done  #end of obsv
#====================================================

exit
