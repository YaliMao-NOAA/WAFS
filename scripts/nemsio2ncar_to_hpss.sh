#!/bin/sh

# Back up real-time & retrospetive nemsio data
# from super computer(s) to NCAR & HPSS.
#
# HPSS backup is optional by setting hpss=yes

# Suggest to run on Cray, not on Dell,
# since Dell can't connect to ftp.rap.ucar.edu

# It turns out it may take 26.5 minutes to finish one set of atm&sfc files
# For real practice, transfer at most 2 days (48 hours) of data for each cronjob

# Basic idea:
# 1. List all data dates available under $COMROOT (user-defined)
# 2. Get the latest date, cycle and forecast hour (PDY2, cyc2, fhr2)
# 3. 1) To HPSS, only archive data one day ahead of PDY2 to guaranteed
#       a completed set of data for all cycles and all forecast hours.
#    2) To NCAR, save and exchange a backup file list to get 'lastbackup'
#       through a third-party space, like rzdm. 
#       If lastbackup is "" (first time run), or lastbackup is too old,
#       PDY1=PDY2-2 and lastbackup=$PDY2$cyc2

. /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/envir_setting.sh
set -xa

date

HOST='ftp.rap.ucar.edu'
USER='anonymous'
PASSWD='yali.mao@noaa.gov'

HTAR=htar

when=$1
hpss=$2

PDY=`$NDATE -24 | cut -c1-8`

DATA=$TMP/nemsio2ncar_to_hpss.$when/$PDY
rm -rf $DATA
mkdir -p $DATA

cycles=${cycles:-"00 06 12 18"}
fhours=${fhours:-"006 012 018 024 030 036"}
HTARout=/NCEPDEV/emc-global/5year/Yali.Mao/nemsio_backup

if [[ $when == "prod" ]] ; then
    COMROOT=/gpfs/dell1/nco/ops/com/gfs/prod
elif [[ $when == "emcpara" ]] ; then
    COMROOT=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/prfv3rt1/vrfyarch
elif [[ $when == "ncopara" ]] ; then
    COMROOT=/gpfs/dell1/nco/ops/com/gfs/para
elif [[ $when == "2018summer" ]] ; then
    COMROOT=/gpfs/hps3/ptmp/emc.glopara/ROTDIRS/prfv3rt1
elif [[ $when == "2017winter" ]] ; then
    COMROOT=/gpfs/dell3/ptmp/Fanglin.Yang/fv3q2fy19retro1
elif [[ $when == "2017summerb" ]] ; then
    COMROOT=/gpfs/dell2/ptmp/Fanglin.Yang/fv3q2fy19retro2
elif [[ $when == "2016winter" ]] ; then
    COMROOT=/gpfs/dell3/ptmp/Fanglin.Yang/fv3q2fy19retro3
elif [[ $when == "2017summera" ]] ; then
    COMROOT=/gpfs/hps3/ptmp/emc.glopara/fv3q2fy19retro2
elif [[ $when == "2016summera" ]] ; then
    COMROOT=/gpfs/hps2/ptmp/emc.glopara/fv3q2fy19retro4
elif [[ $when == "2016summerb" ]] ; then
    COMROOT=/gpfs/dell2/ptmp/emc.glopara/fv3q2fy19retro4
fi


PDY2=`ls $COMROOT | grep "^gfs\." | tail -1 | cut -c5-12`

#*******************************************************************
#*********** To HPSS, only completed data one day before ***********
#*******************************************************************
cd $COMROOT
PDY=`$NDATE -24 ${PDY2}00 | cut -c1-8`

htarfiles=""
if [[ $hpss = 'yes' ]] ; then
  for cyc in $cycles ; do
    for fh in $fhours ; do
      COMIN=$COMROOT/gfs.$PDY/$cyc
      if [[ -s $COMIN/gfs.t${cyc}z.atmf$fh.nemsio ]] && \
	 [[ -s $COMIN/gfs.t${cyc}z.sfcf$fh.nemsio ]] ; then
	htarfiles="$htarfiles ./gfs.$PDY/$cyc/gfs.t${cyc}z.atmf$fh.nemsio ./gfs.$PDY/$cyc/gfs.t${cyc}z.sfcf$fh.nemsio"
      fi
    done
  done
  $HTAR -cPvf $HTARout/$PDY/gfs_nemsiob.tar $htarfiles
fi

#*******************************************************************
#**************** To NCAR, at most 2 days of data  *****************
#*******************************************************************
cd $DATA

latestdata=`ls $COMROOT/gfs.$PDY2/??/*atmf*nemsio | tail -1`
cyc2=`echo $latestdata | sed -e "s/.*\/\([0-9]\{2\}\)\/.*/\1/"`
fhr2=`echo $latestdata | sed -e "s/.*f\([0-9]\{3\}\).nemsio/\1/"`

dates=$DATA/ncar_dates.$when
scp ymao@emcrzdm:/home/ftp/emc/unaff/ymao/fv3_nemsio_list/ncar_dates.$when $dates
lastbackup=`cat $dates | tail -1 | cut -c1-14`  # YYYYMMDDHH FFF

# Able to transfer at most 2 days of data, if first time or lastbackup is too old
if [[ $lastbackup = "" ]] ; then  # first time run
    PDY1=`$NDATE -48 ${PDY2}00 | cut -c1-8`
    lastbackup="$PDY1$cyc2"
else
    PDY1=`echo $lastbackup | cut -c1-10`
    PDY=`$NDATE -48 $PDY2$cyc2`
    if [[ $PDY1 < $PDY ]] ; then    # lastbackup is too old
	echo "Data between $PDY1 and $PDY are skipped" >> $dates
	PDY1=$PDY
	lastbackup="$PDY1"
    fi
    PDY1=`echo $PDY1 | cut -c1-8`
fi

PDY=$PDY1

while [[ ! $PDY > $PDY2 ]] ; do
  
  for cyc in $cycles ; do

    for fh in $fhours ; do

      [[ "$PDY$cyc $fh" < $lastbackup ]] && continue
      [[ "$PDY$cyc $fh" = $lastbackup ]] && continue
      [[ "$PDY$cyc $fh" > "$PDY2$cyc2 $fhr2" ]] && break

#================= prepare data =================
      COMIN=$COMROOT/gfs.$PDY/$cyc
      if [ ! -s $COMIN/gfs.t${cyc}z.sfcf$fh.nemsio ] ; then
	echo "SKIP, file does not exist: $COMIN/gfs.t${cyc}z.sfcf$fh.nemsio"
	echo "$COMIN/gfs.t${cyc}z.sfcf$fh.nemsio is missing." | mailx -s "Data missing for nemsio2ncar_to_hpss.sh" yali.mao@noaa.gov
	echo "$PDY$cyc $fh sfc not available">> $dates
      elif [ ! -s $COMIN/gfs.t${cyc}z.atmf$fh.nemsio ] ; then
	echo "SKIP, file does not exist: $COMIN/gfs.t${cyc}z.atmf$fh.nemsio"
	echo "$COMIN/gfs.t${cyc}z.atmf$fh.nemsio is missing." | mailx -s "Data missing for nemsio2ncar_to_hpss.sh" yali.mao@noaa.gov
	echo "$PDY$cyc $fh atm not available">> $dates
      else
	echo "$PDY$cyc $fh">> $dates
	ln -s $COMIN/gfs.t${cyc}z.atmf$fh.nemsio gfs.t${cyc}z.atmf$fh.nemsio.$PDY
	ln -s $COMIN/gfs.t${cyc}z.sfcf$fh.nemsio gfs.t${cyc}z.sfcf$fh.nemsio.$PDY

#================= transfer data ==================
	ftp -pn $HOST <<EOF
user $USER $PASSWD
passive
cd incoming/irap/gtg_fv3
bin
prompt
put gfs.t${cyc}z.atmf$fh.nemsio.$PDY
put gfs.t${cyc}z.sfcf$fh.nemsio.$PDY
bye
EOF

#================= if timeout ==================
	set +x
	timeout=`grep "Connection timed out" /gpfs/hps/ptmp/Yali.Mao/nemsio2ncar_to_hpss.$when.log`
	set -x
	if [[ $timeout == "" ]] ; then
	    echo incoming/irap/gtg_fv3
	    scp $dates ymao@emcrzdm:/home/ftp/emc/unaff/ymao/fv3_nemsio_list/.
	else
	    echo "$PDY$cyc $fh not uploaded, connection timed out"
	    echo "$PDY$cyc $fh" | mailx -s "Connection time out for nemsio2ncar_to_hpss.sh" yali.mao@noaa.gov
	fi

      fi
    done

  done
  PDY=`$NDATE 24 ${PDY}00 | cut -c1-8`
done


date
echo done
