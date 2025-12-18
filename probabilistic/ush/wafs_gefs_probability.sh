#!/bin/sh
###########################################################################################
# Script: naefs_bc_probability.sh
# Abstract: produces ensemble 10%, 50% and 90% probability forecast
# Author: Bo CUI ---- July 2007
#                     Jan. 2008  use accumulated analysis difference to adjust CMC ensemble 
#                     Apr. 2009 add the option to set NAEFS product ID as 114
#                     July.2010 add FNMOC ensemble 20 members
###########################################################################################

set -x
########################################
#  define ensemble members and lead time
########################################

#hourlist=" 00  06  12  18  24  30  36  42  48  54  60  66  72  78  84  90  96 \
#          102 108 114 120 126 132 138 144 150 156 162 168 174 180 186 192 198 \
#          204 210 216 222 228 234 240 246 252 258 264 270 276 282 288 294 300 \
#          306 312 318 324 330 336 342 348 354 360 366 372 378 384"

#memberlist_ncep="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"
#memberlist_cmc="c00 p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"
#memberlist_fnmoc="p01 p02 p03 p04 p05 p06 p07 p08 p09 p10 p11 p12 p13 p14 p15 p16 p17 p18 p19 p20"

##################################################
# start probability calculation for each lead time
##################################################

hourlist=$FHRLIST

####################################################################
# define if removing initial analyis difference between CMC and NCEP
# 0 = don't remove difference from CMC/FNMOC ensemble forecast
# 1 = remove difference from CMC ensemble forecast
####################################################################

ifdebias=0

####################################
# judeg if generating NAEFS products
# 0 = use the original product ID
# 1 = set NAEFS product ID as 114
####################################

pidswitch=0

#########################################################
# judeg if use CMC raw relative humility 
# YES = use CMC raws ensemble 2m RH
# NO  = once CMC bias corrected 2m RH, choose this option
#########################################################

IFCMCRAWRH=NO

###############################################
# create variable list for ensmeble conbination
###############################################

fieldlist=" 1000HGT 925HGT 850HGT 700HGT 500HGT 250HGT 200HGT 100HGT 50HGT 10HGT \
            1000TMP 925TMP 850TMP 700TMP 500TMP 250TMP 200TMP 100TMP 50TMP 10TMP \
            1000UGRD 925UGRD 850UGRD 700UGRD 500UGRD 250UGRD 200UGRD 100UGRD 50UGRD 10UGRD \
            1000VGRD 925VGRD 850VGRD 700VGRD 500VGRD 250VGRD 200VGRD 100VGRD 50VGRD 10VGRD \
            PRES PRMSL 2MTMP 10MUGRD 10MVGRD TMAX TMIN 850VVEL 2MDPT 2MRH 10MWSPD "
fieldlist="500ICESEV"

nvar=0

if [ -s namin.varlist ]; then
  rm namin.varlist
fi


if [ "$IFGEFS" = "YES" ]; then

  echo " &varlist" >>namin.varlist

  for cfield in $fieldlist; do

    ffd=dummy

    case $cfield in
	
    500ICESEV) ffd=z500;ipdn=1;ipd1=19;ipd2=234;ipd10=100;ipd11=0;ipd12=50000;icnt=1;;

    
     500HGT) ffd=z500;ipdn=1;ipd1=3;ipd2=5;ipd10=100;ipd11=0;ipd12=50000;icnt=1;;

     500TMP) ffd=t500;ipdn=1;ipd1=0;ipd2=0;ipd10=100;ipd11=0;ipd12=50000;icnt=1;;

     500UGRD) ffd=u500;ipdn=1;ipd1=2;ipd2=2;ipd10=100;ipd11=0;ipd12=50000;icnt=1;;

    esac

    if [ "$ffd" == "dummy" ]; then
      echo " #### attention: variable $cfield is not in the list"
    else
      (( nvar = nvar + 1 ))
      echo "ffd($nvar)='$ffd',ipdn($nvar)=$ipdn,mmod($nvar)=$icnt," >>namin.varlist
      echo "ipd1($nvar)=$ipd1,ipd2($nvar)=$ipd2,ipd10($nvar)=$ipd10,ipd11($nvar)=$ipd11,ipd12($nvar)=$ipd12," >>namin.varlist
    fi

  done

  echo "nvar=$nvar," >>namin.varlist
  echo " /" >>namin.varlist

fi

###################################
# start loop for forecast lead time
###################################

for nfhrs in $hourlist; do

  if [ -s namin.prob.$nfhrs ]; then
    rm namin.prob.$nfhrs
  fi

  echo " &namens" >>namin.prob.$nfhrs

  ifile=0
  ifile_cmconly=0

  if [ "$IFNAEFS" = "YES" ]; then
   pidswitch=1
   ifdebias=1
  fi

  if [ "$IFCMCE" = "YES" ]; then
   ifdebias=1
  fi

##############################
# input NCEP Ensemble forecast
##############################

  if [ "$IFNAEFS" = "YES" -o  "$IFGEFS" = "YES" ]; then
    for mem in ${memberlist_ncep}; do
      ifile_ncep=$COMINNCEP/ge${mem}.t${cyc}z.pgrb2b.0p50.f${nfhrs}
      if [ -s $ifile_ncep ]; then
        (( ifile = ifile + 1 ))
        iskip=1
        if [ "$mem" = "c00" ]; then
          iskip=0
        fi
        echo " cfipg($ifile)='$ifile_ncep'," >>namin.prob.$nfhrs
        echo " iskip($ifile)=${iskip}," >>namin.prob.$nfhrs
      fi
    done
  fi

  iall_cmc=0

  if [ "$ifile" = "0" ]; then
     iall_cmc=1
  fi

##############################
#  input CMC Ensemble forecast
##############################

  if [ "$IFNAEFS" = "YES" -o  "$IFCMCE" = "YES" ]; then
    iall_fnmoc=0

    if [ "$ifile" = "0" ]; then
      iall_fnmoc=1
    fi
  fi

####################
# set up input files 
####################

  echo " pidswitch=${pidswitch}," >>namin.prob.$nfhrs
  echo " nfiles=${ifile}," >>namin.prob.$nfhrs
  echo " ifdebias=${ifdebias}," >>namin.prob.$nfhrs
  echo " iall_cmc=${iall_cmc}," >>namin.prob.$nfhrs
  echo " iall_fnmoc=${iall_fnmoc}," >>namin.prob.$nfhrs

  echo " ifhr=$nfhrs," >>namin.prob.$nfhrs

#####################
# set up output files 
#####################

  echo " cfopg1='cat3.t${cyc}z.pgrb2.0p50.f${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg3='cat4.t${cyc}z.pgrb2.0p50.f${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg2='ge90pt.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg4='geavg.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg5='gespr.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs
  echo " cfopg6='gemode.t${cyc}z.pgrb2a.0p50_bcf${nfhrs}'," >>namin.prob.$nfhrs

  echo " /" >>namin.prob.$nfhrs

  cat namin.varlist >>namin.prob.$nfhrs

  if [ $cyc -eq 00 -o $cyc -eq 12 ]; then
    if [ "$IFNAEFS" = "YES" -a $ifile_cmconly -eq 0 -a $ifile -ne 0 ]; then
      echo "Warning!!! NAEFS has only GEFS input for fcst " $nfhrs
    fi
  fi

  if [ $ifile -eq 0 ]; then
    echo "FATAL ERROR: Input ensemble files not available for fcst hr " $nfhrs
    export err=1; err_chk
  fi

  startmsg
  $EXECwafs/wafs_icesev_probability <namin.prob.$nfhrs > $pgmout.${nfhrs}_prob  2> errfile
  export err=$?;err_chk

done

set +x
echo " "
echo "Leaving sub script wafs_gefs_probability.sh"
echo " "
set -x

