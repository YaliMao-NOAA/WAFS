#!/bin/ksh

set -x

#**************************************************************
#  generate master file (for gfip/g2g/gfs) from archived sigma files
#-------------------------------------------------------------
# 2 steps:
#   1) extract sf$fh and sfluxgrbf$fh from HPSS
#   2) bsub a job to generate master file
#
# becaues of frequent interruption caused by computer unaccessable,
# extract sigma files only when files do not exist
#
# working folder constructions:
#   /ptmpp1/Yali.Mao/$prod.YYYYMMDD
#
# tips:
#   $postscript: _working for pressure level
#               _specific.grid for hybrid level
#**************************************************************

function printUsage {
  echo "usage: ksh /global/save/Yali.Mao/scripts/gfs_master_archive.sh  gfip/g2g/gfs(product) YYYYMMDD(start date) YYYYMMDD(end date) cycle(s) fhour(s)"
  echo '  Tips: use quotations for a list of cycles/fhours'
}

#====================================================
#arguments
#====================================================
if [ $# -lt 5 ]; then
  printUsage
  exit
fi

# when using logical operator, can't use '[[ ]]', must use '[ ]'
if [ $1 != "gfip" -a $1 != "g2g" -a $1 != "gfs" ] ; then
  echo "Prodcution type is not supported" 
  printUsage
  exit
fi
prod=$1

start_date=$2"00" # add "00" to convert to YYYYMMDDHH
end_date=$3"00"

# check dates are in good shape
if [[ `/nwprod/util/exec/ndate 0 $start_date 2>/dev/null` != $start_date ]]; then
  echo "Start date is not in good format YYYYMMDD."
  printUsage
  exit
fi
if [[ `/nwprod/util/exec/ndate 0 $end_date 2>/dev/null` != $end_date ]]; then
  echo "End date is not in good format YYYYMMDD."
  printUsage
  exit
fi

cycles=$4
fhours=$5

#====================================================
# Basic settings
#====================================================
user=`whoami`
wdir=/ptmpp1/$user

# --------- where sigma and flux files are from -----
hpss=/NCEPPROD/2year/hpssprod/runhistory
#hpssdir=/NCEPPROD/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyy}${mm}${dd} 
        #2.5-deg, bufr etc
#hpssdir1=/NCEPPROD/1year/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyy}${mm}${dd}
        #1-deg grib up to 192hr, 0.5-deg grib2 up to 192hr
#hpssdir2=/NCEPPROD/2year/hpssprod/runhistory/rh${yyyy}/${yyyy}${mm}/${yyyy}${mm}${dd}
        #sigma, sfc flux etc
#hpsstmp=/NCEPPROD/1year/hpssprod/runhistory/rh2010/save

# where radar file exists:
#hpss=/NCEPPROD/hpssprod/runhistory/rh2014/201406/20140612


# --------- which post script to bsub -----------
if [ $prod = "gfip" ] ; then
  postscript=/global/save/Yali.Mao/post/run_exgfs_nceppost.sh.sms_working
  postexe=/global/save/Yali.Mao/wafs/gfis/src/ncep_post
  controlfile=/global/save/Yali.Mao/wafs/gfis/post/gfs_cntrl.parm_GFIP
elif [ $prod = "g2g" ] ; then
  postscript=/global/save/Yali.Mao/post/run_exgfs_nceppost.sh.sms_specific.grid
  postexe=/nwprod/exec/ncep_post
  controlfile=/global/save/Yali.Mao/post/gfs_cntrl.parm_gtg
elif [ $prod = "gfs" ] ; then
  postscript=/global/save/Yali.Mao/post/run_exgfs_nceppost.sh.sms_working
  postexe=/global/save/Yali.Mao/wafs/gfis/src/ncep_post
  controlfile=/global/save/Yali.Mao/post/gfs_cntrl.parm_working
fi

#====================================================
# Begin to process...
#====================================================

#increase end_date by one day for convenience of comparison
end_date=`ndate 24 $end_date`

while [[ $start_date < $end_date ]]; do

  tyear=`echo $start_date | cut -c1-4`
  tmonth=`echo $start_date | cut -c1-6`
  tdate=${start_date%??}

  # check sigma file still exists in /com or has been archived
  sigma_existing=`ls -l /com/gfs/prod | grep gfs.$tdate`
  if [[ -n $sigma_existing ]] ; then
    extract="no"
    indir=/com/gfs/prod/gfs
  else
    extract="yes"
    indir=$wdir/${prod}.flux
  fi

  # where sigma and flux files are from
  hpssDate=${hpss}/rh${tyear}/${tmonth}/${tdate}
  # where sigma and flux files are extracted to
  indirDate=$indir.$tdate
  if [ $extract = "yes" ] ; then
     mkdir -p  $indirDate
  fi

  # where master file will be saved
  dataDir=$wdir/$prod.$tdate
  mkdir -p $dataDir


  cd $dataDir
  cp $postscript runpostscript
  sed -e "s|data0=.*|data0=$dataDir|" -e "s|COMIN=.*|COMIN=$indirDate|" \
      -e  "s|CTLFILE=.*|CTLFILE=$controlfile|" -e "s|POSTGPEXEC=.*|POSTGPEXEC=$postexe|" runpostscript > runpostscript.tmp

  for hh in $cycles ; do

    if [ $extract = "yes" ] ; then

      cd $indirDate

      #====================================================
      # extract sf$fh and sfluxgrbf$fh files
      #====================================================
      for fh in $fhours ; do

        # do not extract files if they already exist
        sigmafile=./gfs.t${hh}z.sf${fh}
        fluxfile=./gfs.t${hh}z.sfluxgrbf${fh}
        # sfacefile=./gfs.t${hh}z.bf${fh} # surface file. For instantaneous precipitation, it is required; otherwise it will use accumulated precipitation

        #if [ -e $sigmafile -a -e $fluxfile -a -e $sfacefile ]; then
        #  if [ `ls -l $sigmafile | awk '{ print $5}'` -gt 500000000 -a `ls -l $fluxfile | awk '{ print $5}'` -gt 180000000  -a `ls -l $sfacefile | awk '{ print $5}'` -gt 200000000 ]; then
        if [ -e $sigmafile -a -e $fluxfile ] ; then
          if [ `ls -l $sigmafile | awk '{ print $5}'` -gt 500000000 -a `ls -l $fluxfile | awk '{ print $5}'` -gt 180000000  ]; then
	    continue
          fi
        fi

        htar -xvf ${hpssDate}/com_gfs_prod_gfs.${tdate}${hh}.sigma.tar    $sigmafile &
        htar -xvf ${hpssDate}/com_gfs_prod_gfs.${tdate}${hh}.sfluxgrb.tar $fluxfile &
        #htar -xvf ${hpssDate}/com_gfs_prod_gfs.${tdate}${hh}.surface.tar  $sfacefile &
        wait
      done #fh
    fi # $extract 'yes'

    cd $dataDir    

    # this file wll be created by bsub post script
    modelFile=$dataDir/gfs.t${hh}z.master.grbf

    for fh in $fhours ; do

      #====================================================
      # bsub a job to generate model master file if it doesn't exist
      #====================================================

      existing=false
      if [ -e $modelFile$fh ]; then
	if [ `ls -l $modelFile$fh | awk '{ print $5}'` -gt 300000000 ]; then
	  existing=true
	fi
      fi

      if [ $existing != "true" ] ; then

        sed -e "s/PDY=[0-9]*/PDY=${tdate}/"  -e "s/cyc=[0-9]*/cyc=${hh}/" -e "s/allFhours=.*/allFhours=$fh/" runpostscript.tmp > runpostscript

	jobSubmit=`bsub < runpostscript`
	jobID=`echo $jobSubmit | sed -e 's/.*Job <//g' | sed -e 's/> is.*//'`

	if [[ -n $jobID ]]; then
          # wait reasonable long time till a job is possibly done
	  sleep 180

          # Wait till this job is done
	  result=`bjobs | grep $jobID`
	  while [[ -n $result ]]; do
	    sleep 60
	    result=`bjobs | grep $jobID`
	  done
	fi # -n $jobID

      fi # file exists or not

      #====================================================
      # follow up
      #====================================================
      if [ $prod = 'gfip' ] ; then
	# keep only icing potential and severity
        wgrib $modelFile$fh  | grep "kpds5=\(168\|175\):kpds6=100" | wgrib -i $modelFile$fh  -grib -o icingonly

        # copygb to grid 252
        copygb -xg252 -i2 icingonly $dataDir/gfs.t${hh}z.gfip.grbf${fh}

      fi
    done # fh in $fhours

  done # hh in $cycles

  start_date=`ndate 24 $start_date`
done

#set -A joblist
#ijob=0
#joblist[$ijob]="$jobID ${tdate}$hh"
#ajob=`echo ${joblist[$ijob]} | awk -F" " '{print $1}'`
#jobtime=`echo ${joblist[$ijob]} | awk -F" " '{print $2}'`
