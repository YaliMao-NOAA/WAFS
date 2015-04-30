#!/bin/ksh
set -xa

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

############# Set up environments ##################
chost=`echo $(hostname) |cut -c 1-1`
echo $chost
if [[ $chost == 't' || $chost == 'g' ]] ; then
  machine=WCOSS
elif [[ $chost == 'f' ]] ; then
  machine=ZEUS
fi
if [ $machine = WCOSS ] ; then
 vsdbsave=/global/save/$LOGNAME/vsdb/grid2grid                  ;#where vsdb database is saved
 export vsdbhome=/global/save/Yali.Mao/project/verif_g2g.v3.0.0 ;#script home
 export NWPROD=/nwprod
 export PTMP=/ptmpp1                                            ;#temporary directory                          
 export GRADSBIN=/usrx/local/GrADS/2.0.2/bin                    ;#GrADS executables       
 export IMGCONVERT=/usrx/local/ImageMagick/6.8.3-3/bin/convert                ;#image magic converter
 export FC=/usrx/local/intel/composer_xe_2011_sp1.11.339/bin/intel64/ifort    ;#intel compiler
 export FFLAG="-O2 -convert big_endian -FR"                     ;#intel compiler options
elif [ $machine = ZEUS ] ; then
 vsdbsave=/scratch2/portfolios/NCEPDEV/global/save/$LOGNAME/vsdb/grid2grid       ;#where vsdb database is saved
 export vsdbhome=/scratch2/portfolios/NCEPDEV/global/save/Yali.Mao/project/verif_g2g.v3.0.0 ;#script home
 export NWPROD=/scratch2/portfolios/NCEPDEV/global/save/Fanglin.Yang/VRFY/vsdb/nwprod
 export PTMP=/scratch2/portfolios/NCEPDEV/ptmp              ;#temporary directory                          
#export GRADSBIN=/apps/grads/2.0.1/bin                      ;#GrADS executables       
 export GRADSBIN=/apps/grads/2.0.a9/bin                     ;#GrADS executables       
 export IMGCONVERT=/apps/ImageMagick/ImageMagick-6.7.6-8/bin/convert  ;#image magic converter
 export FC=/apps/intel/composerxe-2011.4.191/composerxe-2011.4.191/bin/intel64/ifort ;#intel compiler
 export FFLAG="-O2 -convert big_endian -FR"                 ;#intel compiler options
fi

## -- data and output directories
#gather vsdb stats and put in a central location
rundir0=${rundir:-$PTMP/${LOGNAME}/vsdb_plot}    ;#temporary workplace
vsdball=$rundir0/vsdb_data
mkdir -p $vsdball; cd $vsdball || exit 8
if [ -s  ${vsdball}/wafs ] ; then rm ${vsdball}/wafs ; fi
ln -fs $vsdbsave/wafs  ${vsdball}/.
export vsdb_data=$vsdball/wafs                            ;#where all vsdb data are
export makemap=${makemap:-"YES"}                          ;#whether or not to make maps
export mapdir=${mapdir:-${rundir0}/web}                   ;#place where maps are saved locally
export scorecard=${scorecard:-YES}                        ;#create scorecard text files
export scoredir=${scoredir:-$rundir0/score}               ;#place to save scorecard output
mkdir -p $rundir0 $mapdir $scoredir

## -- verification dates
export sdate=${sdate:-${1:-20150412}}        	          ;#forecast starting date
export edate=${edate:-${2:-20150425}}                 	  ;#forecast ending date
export vlength=${vlength:-${3:-36}}                 	  ;#forecast length in hour
export fcycle=${fcycle:-${cyclist:-${4:-"00 06 12 18"}}}  ;#forecast cycles
export observations=${observations:-${5:-"gfs gcip gcipconus cip"}}

## -- verification parameters (dynamic ones)

errdir=$PTMP/$LOGNAME
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
    genericlist="vsdbhome NWPROD PTMP GRADSBIN IMGCONVERT FC FFLAG"
    genericlist="$genericlist vsdb_data makemap mapdir scorecard scoredir"
    genericlist="$genericlist sdate edate vlength fcycle"
    specificlist="obsvlist mdlist reglist rundir vhrlist vtype vnamlist levlist"
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
