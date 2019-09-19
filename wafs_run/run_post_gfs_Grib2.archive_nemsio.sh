#!/bin/bash
date

############################################################### 
#  Run UPP to generate master(gfip)/gtg from an archivednemsio file
#  (Inside a loop, one single set of data)
#-------------------------------------------------------------
# 2 steps:
#   1) extract flux file, and sigma/nemsio file from HPSS
#   2) modify the driver
#   2) bsub the driver to generate master/gtg file
#
# becaues of frequent interruption caused by computer unaccessable,
# extract files only when files do not exist
#
# Only when $proj exists, do FTP and transfer archivelist.$MACHINE
#
# archivelist.$MACHINE:
#   1) Initialized from and RZDM server
#   2) Status of each $PDY$HH$FH: 'not archived', failed or none(successful)
#   3) Upload  archivelist.$MACHINE to RZDM server
#   Machine difference: just to speedup the process
############################################################### 

#====================================================
# Where to send the data to the aviation community
#====================================================
#FTP=YES   # emc rzdm, raw
#FTP=UCAR  # ftp server
FTP=VERF   # emc rzdm 0.25 degree

#====================================================
# if run alone
#====================================================
if [ -z $proj ] ; then
  . /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/envir_setting.sh
fi

set -xa

#====================================================
function printUsage {
#====================================================
  echo "usage: sh $HOMEsave/wafs_run/run_post_gfs_Grib2.archive_nemsio.sh gfip/gtg/gfs(product) YYYYMMDD cycle fhour htype"
}


#====================================================
#arguments
#====================================================
if [ $# -lt 5 ]; then
  printUsage
  exit
fi

prod=$1
PDY=$2
hh=$3
fh=$4
htype=$5 # history type: archive/retro

# input forecast hour can be 2 or 3 digits, output will be in 3 digits
fh="$(printf "%03d" $(( 10#$fh )) )"

#====================================================
# when run this script alone, not called by another script
#====================================================
export HTAR=${HTAR:-htar}
export BSUB=${BSUB:-bsub}

export driver=${driver:-$HOMEsave/wafs_run/run_post_gfs_Grib2.nemsio.driver.$MACHINE}
export HOMEgfs=${HOMEgfs:-$HOMEgit/EMC_gtg_ncar}

# working folder constructions:
# if run alone
if [ -z $proj ] ; then
  DATA=$TMP/fv3.working.$$
  mkdir -p $DATA
  rm -rf $DATA/*
  cd $DATA

  COMIN=$TMP/nemsio.$PDY
  mkdir -p $COMIN
  COMOUT=prod/$prod.$PDY
else
  # this DATA dir is the bjob working folder
  DATA=$DATA/$PDY.$hh.f$fh
  mkdir -p $DATA
  rm -rf $DATA/*
fi


#====================================================
# For a specific $hh$fh, check for data already finished
# will be appended by the new status of $hh$fh
#====================================================
# if not run alone
if [ ! -z $proj ] ; then
    archivelist=archivelist.$MACHINE
    scp ymao@emcrzdm:/home/ftp/emc/unaff/ymao/$proj/$archivelist .
    if [ -e $archivelist ] ; then
	lastbackup=`cat $archivelist | tail -1 | cut -c1-13`
	if [[ $PDY$hh$fh -le $lastbackup ]] ; then
	    # silently exit if data is done
	    exit 0
	fi
    else
	touch $archivelist
    fi
fi

#====================================================
# Define product index file name to check whether it exists
#====================================================
if [ $prod = icing ] ; then
    # for icing, generate master file only, no GTG
    prodFileIndx=gfs.t${hh}z.master.grb2if
    MSTF=YES
    GTGF=NO
elif [ $prod = gtg ] ; then
    # for GTG, generate GTG only, no master file
    prodFileIndx=gfs.t${hh}z.gtg.grb2if
    MSTF=NO
    GTGF=YES
else # for gfs, generate both of master file and GTG
    # GTG is generated later than master file
    prodFileIndx=gfs.t${hh}z.gtg.grb2if
    MSTF=YES
    GTGF=YES
fi

#########################################################
# If the prod file already exists, no need to run archive
if [ -e $COMOUT/$prodFileIndx$fh ] ; then
#########################################################
   status="$PDY$hh$fh"
#########################################################
# needs to prepare job card and extract HPSS data then run
else
#########################################################

   #====================================================
   # Prepare job card. 
   #====================================================

   cp $driver ./driver.$PDY.$hh.$fh

   sed -e "s|#BSUB -oo.*|#BSUB -oo $TMP/err.post.$prod.${PDY}_${hh}_${fh}archive.o%J|" \
       -e "s|#BSUB -eo.*|#BSUB -eo $TMP/err.post.$prod.${PDY}_${hh}_${fh}archive.o%J|" \
       -e "s|#BSUB -J .*|#BSUB -J archive_$prod|" \
       -i driver.$PDY.$hh.$fh

   sed -e "s|export DATA=.*|export DATA=$DATA|" \
       -e "s|export COMIN=.*|export COMIN=$COMIN|" \
       -e "s|export COMOUT=.*|export COMOUT=$COMOUT|" \
       -e "s|export HOMEgfs=.*|export HOMEgfs=$HOMEgfs|" \
       -e "s|export OUTTYP=.*|export OUTTYP=$OUTTYP|" \
       -i driver.$PDY.$hh.$fh

   sed -e "s/PDY=[0-9]*/PDY=${PDY}/" \
       -e "s/cyc=[0-9]*/cyc=${hh}/" \
       -e "s/post_times=.*/post_times=$fh/" \
       -i driver.$PDY.$hh.$fh


   sed -e "s|export MSTF=.*|export MSTF=${MSTF} |" \
       -e "s|export GTGF=.*|export GTGF=${GTGF}|" \
       -i driver.$PDY.$hh.$fh

   #====================================================
   # HPSS basic settings
   #====================================================

   # need to convert archived surface/flux file from grib2 to nemsio
   # if surface/flux file is not archived
   convertSFC=no

   if [[ $htype = "archive" ]] ; then
       # --------- operational archived data  ----------
       HPSS=/NCEPPROD/hpssprod/runhistory

       ### 201605 or ealier
       #hpss=/NCEPPROD/hpssprod/runhistory/2year/save/rh2016/save/com_*
       ### 201606 till 20170719
       ### Since 20160510, GFS file names start with com2_, instead of com_
       #hpss=/NCEPPROD/hpssprod/runhistory/rh2016/201608/20160830/com2_*
       ### 20170720 and later
       ### Since 20170720, GFS file names start with gpfs_hps_nco_ops_com_
       #hpss=/NCEPPROD/hpssprod/runhistory/rh2017/201707/20170720/gpfs_hps_nco_ops_com_*
       ### where radar file exists:
       #hpss=/NCEPPROD/hpssprod/runhistory/rh2014/201406/20140612

       tyear=`echo $PDY | cut -c1-4`
       tmonth=`echo $PDY | cut -c1-6`

       if [[ $PDY < 20160601 ]] ; then
	   hpssDate=${HPSS}/2year/save/rh${tyear}/save
       else
	   hpssDate=${HPSS}/rh${tyear}/${tmonth}/${PDY}
       fi

       if [[ $PDY < 20170720 ]] ; then
	   echo "Warning: Not supported anymore for any date before $PDY"
	   exit 1

#	   OUTTYP=3
	   if [[ $PDY < 20160510 ]] ; then
	       comTAR=com_
	   elif [[ $PDY < 20170720 ]] ; then
	       comTAR=com2_
	   fi

	   nemsioPrefix=.
	   sigmaTemplate=gfs.t${hh}z.sf$fh
	   fluxTemplate=gfs.t${hh}z.sfluxgrbf$fh
	   logTemplate=gfs.t${hh}z.logf$fh

       elif [[ $PDY < 20200420 ]] ; then
#	   OUTTYP=4

	   nemsioPrefix=/gpfs/hps/nco/ops/com/gfs/prod/gfs.$PDY
	   atmfile=gfs.t${hh}z.atmf${fh}.nemsio
	   sfcfile=gfs.t${hh}z.sfcf${fh}.nemsio
	   logfile=gfs.t${hh}z.logf${fh}.nemsio

	   comTAR=gpfs_hps_nco_ops_com_
	   atm_tarFile=${comTAR}gfs_prod_gfs.${PDY}${hh}.sigma.tar
	   sfc_tarFile=${comTAR}gfs_prod_gfs.${PDY}${hh}.sfluxgrb.tar

	   # need to convert archived flux file from grib2 to nemsio
           convertSFC=yes
	   fh2="$(printf "%02d" $(( 10#$fh )) )"
	   flxfile_archived=gfs.t${hh}z.sfluxgrbf${fh2}.grib2
	   # (to use the same code as other archived data)
	   sfcfile_converted=$sfcfile
	   sfcfile=$flxfile_archived

       else # FV3                                                                                                                                                            
	   echo "Not ready yet"
	   exit 1
       fi

   elif [[ $htype =~ "2019_" ]] ; then
       # --------- Q2FY2019 retrospective data ---------
       if [[ $htype =~ '_18summer' ]] ; then
	   # 05/25/2018 ~ 01/25/2019
	   HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_C/Q2FY19/prfv3rt1
       elif [[ $htype =~ '_17winter' ]] ; then
	   # 11/25/2017 ~ 05/31/2018
	   HPSS=/NCEPDEV/emc-global/5year/Fanglin.Yang/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro1
       elif [[ $htype =~ '_17summerb' ]] ; then
	   # 08/02/2017 ~ 11/30/2017
	   HPSS=/NCEPDEV/emc-global/5year/Fanglin.Yang/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro2
       elif [[ $htype =~ '_17summera' ]] ; then
	   # 05/25/2017 ~ 08/31/2017
	   HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_C/Q2FY19/fv3q2fy19retro2
       elif [[ $htype =~ '_16winter' ]] ; then
	   # 11/25/2016 ~ 05/31/2017 
	   HPSS=/NCEPDEV/emc-global/5year/Fanglin.Yang/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro3
       elif [[ $htype =~ '_16summera' ]] ; then
	   # 5/22/2016 ~ 08/25/2016
	   HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_C/Q2FY19/fv3q2fy19retro4
       elif [[ $htype =~ '_16summerb' ]] ; then
	   # 06/05//2016 ~ 11/30/2016
	   HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro4
       elif [[ $htype =~ '_15winter' ]] ; then
	   # 11/25/2015 ~ 05/31/2016  
	   HPSS=/NCEPDEV/emc-global/5year/emc.glopara/JET/Q2FY19/fv3q2fy19retro5
       elif [[ $htype =~ '_15summer' ]] ; then
	   # 5/03/2015 ~ 11/28/2015
	   HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro6
       else
	   echo Not a valid option for 2019 implementation, $htype
	   exit 1
       fi

       ### where nemsio and surface files are from
       hpssDate=${HPSS}/${PDY}${hh}

       ### prepare the file names of nemsio
       nemsioPrefix=./gfs.$PDY/$hh
       atmfile=gfs.t${hh}z.atmf${fh}.nemsio
       sfcfile=gfs.t${hh}z.sfcf${fh}.nemsio
       logfile=gfs.t${hh}z.logf${fh}.nemsio

       atm_tarFile=gfs_nemsiob.tar
       sfc_tarFile=gfs_nemsiob.tar

   else
       echo Not a valid archive option
       exit 1
   fi



   #====================================================
   # extract atm file
   #====================================================
   size=`$HTAR -tf ${hpssDate}/$atm_tarFile $nemsioPrefix/$atmfile`
   size=`echo $size | sed -e "s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.*//" | awk '{print $NF}'`

   sizeCOMIN=0
   if [ -e $COMIN/$atmfile ] ; then
       sizeCOMIN=`wc -c < $COMIN/$atmfile`
   fi
   if [ $sizeCOMIN -lt $size ] ; then
       $HTAR -xvf ${hpssDate}/$atm_tarFile $nemsioPrefix/$atmfile
       # move sigma file to COMIN
       mv ./$nemsioPrefix/$atmfile $COMIN/.
   fi

   #====================================================
   # extract surface file
   #====================================================

   size=`$HTAR -tf ${hpssDate}/$sfc_tarFile $nemsioPrefix/$sfcfile`
   size=`echo $size | sed -e "s/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}.*//" | awk '{print $NF}'`

   sizeCOMIN=0
   if [ -e $COMIN/$sfcfile ] ; then
       sizeCOMIN=`wc -c < $COMIN/$sfcfile`
   fi
   if [ $sizeCOMIN -lt $size ] ; then
       $HTAR -xvf ${hpssDate}/$sfc_tarFile $nemsioPrefix/$sfcfile
       # move surface file to COMIN
       mv ./$nemsioPrefix/$sfcfile $COMIN/.
   fi

   if [[ $convertSFC = yes ]] ; then
       echo "need to convert archived flux file from grib2 to nemsio"
       $HOMEsave/nemsio/grib2nemsio.x.$MACHINE $COMIN/$sfcfile $COMIN/$sfcfile_converted
       rm $COMIN/$sfcfile
       sfcfile=$sfcfile_converted
   fi

   if [ $nemsioPrefix != . ] ; then
       rm -r ./$nemsioPrefix
   fi

   #====================================================
   # bsub a job to generate model master/gtg ($prod) file
   #====================================================

   # check whether input files exist or not, in case failed extracting data from HPSS
   if [[ ! -f $COMIN/$sfcfile ]] || [[ ! -f $COMIN/$atmfile ]] ; then
       echo "Input files are not extracted from HPSS successfully, $atmfile or $sfcfile"
       status="$PDY$hh$fh not archived"
       rm ./driver.$PDY.$hh.$fh
   else
       echo $PDY$hh$fh > $COMIN/$logfile
       status="$PDY$hh$fh"
       $BSUB < driver.$PDY.$hh.$fh
   fi

fi


#====================================================
# follow up and/or transfer to ftp server only when $proj exist
#====================================================

# If run alone, no follow up
if [ -z $proj ] ; then
  exit 0
fi


if [[ $FTP = "NO" ]] ; then
  exit 0
fi

SLEEP_MAX=$(( 60*60 ))
SLEEP_INT=5
slptime=0

success=Yes
if [[ $status  =~ "not archived" ]] ; then
    success=No
else
    while [[ $slptime -le $SLEEP_MAX ]] ; do
	if  [ -e  $COMOUT/$prodFileIndx$fh ] ; then
	    break
	else
	    slptime=`expr $slptime + $SLEEP_INT`
	    sleep $SLEEP_INT
	fi
	if [[ $slptime -eq $SLEEP_MAX ]] ; then
	    success=No
	    status="$status failed"
	fi
    done
fi

if [ $success = Yes ] ; then
    rm $COMIN/*t${hh}z*${fh}*nemsio

    remoteDir=/home/ftp/emc/unaff/ymao/$proj/gfs.$PDY
    if [[ $FTP = YES ]] || [[ $FTP = VERF ]] ; then
	ssh ymao@emcrzdm "mkdir -p $remoteDir"
    fi

    option1=' -set_grib_type same -new_grid_winds earth '
    option2=' -new_grid_interpolation bilinear '
    option3=' -if :ICSEV: -new_grid_interpolation neighbor -fi '
    option4=' -set_grib_max_bits 16'
    grid0p25="latlon 0:1440:0.25 90:721:-0.25"

    # For icing and gfs, keep potential and severity only
    if [[ $prod = 'icing' ]] || [[ $prod = 'gfs' ]] ; then
	masterFile=gfs.t${hh}z.master.grb2f$fh
	icingFile=gfs.t${hh}z.icing.grbf${fh}
	$WGRIB2 $COMOUT/$masterFile | grep ":\(ICIP\|ICSEV\):" | $WGRIB2 -i $COMOUT/$masterFile -grib $COMOUT/$icingFile
          
	if [ $FTP == YES ] ; then
	    scp $COMOUT/$icingFile ymao@emcrzdm:$remoteDir/.
        elif [[ $FTP == VERF ]] ; then
	    $WGRIB2 $COMOUT/$icingFile \
		     $option1 $option2 $option3 $option4 \
		     -new_grid $grid0p25 $COMOUT/gfs.t${hh}z.icing.0p25.grb2f$fh

            scp $COMOUT/gfs.t${hh}z.icing.0p25.grb2f$fh ymao@emcrzdm:$remoteDir/.
	fi
    fi

    # For gtg and gfs, may be converted to 0p25 for GTG verification
    if [[ $prod = 'gtg' ]] || [[ $prod = 'gfs' ]] ; then
	gtgFile=gfs.t${hh}z.gtg.grb2f$fh

	if [ $FTP == YES ] ; then
	    scp $COMOUT/$gtgFile ymao@emcrzdm:/home/ftp/emc/unaff/ymao/$proj/gtg.$PDY/.
	elif [[ $FTP == VERF ]] ; then
	    $WGRIB2 $COMOUT/$gtgFile \
		    $option1 $option2 $option4 \
		    -new_grid $grid0p25 $COMOUT/gfs.t${hh}z.gtg.0p25.grb2f$fh

            scp $COMOUT/gfs.t${hh}z.gtg.0p25.grb2f$fh ymao@emcrzdm:$remoteDir/.
	elif [[ $FTP == UCAR ]] ; then
	    HOST='ftp.rap.ucar.edu'
	    USER='anonymous'
	    PASSWD='yali.mao@noaa.gov'
	    ftp -pn $HOST <<EOF
user $USER $PASSWD
lcd $COMOUT/
cd incoming/irap/gtg_gfs
bin
put $gtgFile gfs.t${hh}z.gtg.grb2f${fh}.$PDY
quit
EOF
	fi
    fi
fi  # success


#====================================================
# Uploaded $archivelist to rzdm server
#====================================================
echo $status >> $archivelist
scp $archivelist ymao@emcrzdm:/home/ftp/emc/unaff/ymao/$proj/.

exit 0

#set -A joblist
#ijob=0
#joblist[$ijob]="$jobID ${PDY}$hh"
#ajob=`echo ${joblist[$ijob]} | awk -F" " '{print $1}'`
#jobtime=`echo ${joblist[$ijob]} | awk -F" " '{print $2}'`
