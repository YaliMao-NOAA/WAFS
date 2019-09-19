#!/bin/sh

# Extract retrospetive nemsio data from HPSS to super
# computer(s), then send to NCAR
#
# PDYs, cycles, fhours can be exported, useful if 
# previous run has missing some PDY, cycle, fhour
# 
# Suggest to run on Cray, not on Dell,
# since Dell can't connect to ftp.rap.ucar.edu
#
# It turns out it may take 30 minutes to finish one set of atm&sfc files
# (including htar and ftp)
# For real practice, transfer at most 2 days (48 hours) of data for each cronjob

# Tip: To transfer data to UCAR FTP server, it seems more efficient 
#      to 'put' one file by one file than to 'mput'


. /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/envir_setting.sh
set -xa

date
user=`whoami`

HOST='ftp.rap.ucar.edu'
USER='anonymous'
PASSWD='yali.mao@noaa.gov'

HTAR=htar

when=$1

DATA=$TMP/nemsio2ncar_from_hpss.$when/$PDY
rm -rf $DATA
mkdir -p $DATA

cycles=${cycles:-"00 06 12 18"}
fhours=${fhours:-"006 012 018 024 030 036"}

if [[ $when == "2018summer" ]] ; then
 # 05/25/2018 ~ 01/25/2019
  HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_C/Q2FY19/prfv3rt1
  startdate="YYYYMMDDHH"
elif [[ $when == '2017winter' ]] ; then
  # 11/25/2017 ~ 05/31/2018
  HPSS=/NCEPDEV/emc-global/5year/Fanglin.Yang/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro1
  startdate=""
elif [[ $when == '2017summera' ]] ; then
  # 05/25/2017 ~ 08/31/2017
  HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_C/Q2FY19/fv3q2fy19retro2
  startdate="YYYYMMDDHH"
elif [[ $when == '2017summerb' ]] ; then
  # 08/02//2017 ~ 11/09/2017
  HPSS=/NCEPDEV/emc-global/5year/Fanglin.Yang/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro2
  startdate="YYYYMMDDHH"
elif [[ $when == '2016winter' ]] ; then
  # 11/25/2016 ~ 05/31/2017 
  HPSS=/NCEPDEV/emc-global/5year/Fanglin.Yang/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro3
  startdate="YYYYMMDDHH"
elif [[ $when == '2016summera' ]] ; then
  # 5/22/2016 ~ 08/25/2016
  HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_C/Q2FY19/fv3q2fy19retro4
  startdate="YYYYMMDDHH"
elif [[ $when == '2016summerb' ]] ; then
  # 08/17//2016 ~ 11/26/2016
  HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro4
  startdate="YYYYMMDDHH"
elif [[ $when == '15winter' ]] ; then
  # 11/25/2015 ~ 05/31/2016  
  HPSS=/NCEPDEV/emc-global/5year/emc.glopara/JET/Q2FY19/fv3q2fy19retro5
  startdate="YYYYMMDDHH"
elif [[ $when == '15summer' ]] ; then
  # 5/03/2015 ~ 11/28/2015
  HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_DELL_P3/Q2FY19/fv3q2fy19retro6
  startdate="YYYYMMDDHH"
fi

cd $DATA

dates=$DATA/archive_dates.$when
scp ymao@emcrzdm:/home/ftp/emc/unaff/ymao/fv3_nemsio_list/archive_dates.$when $dates
lastbackup=`cat $dates | tail -1 | cut -c1-10`

if [[ $lastbackup = "" ]] ; then
    # pretend lastbackup is 6 hours before startdate
    lastbackup=`$NDATE  -6 $startdate` # YYYYMMDDHH
fi

PDY1=`$NDATE  6 $lastbackup | cut -c1-8`
# Able to transfer 2 days of data in one day, 48=54-6
PDY2=`$NDATE 54 $lastbackup | cut -c1-8`


PDY=$PDY1
while [[ $PDY < $PDY2 ]] ; do
    PDYall="$PDYall $PDY"
    PDY=`$NDATE 24 ${PDY}00 | cut -c1-8`
done
PDYs=${PDYs:-"$PDYall"}

for PDY in $PDYs ; do
  for cyc in $cycles ; do
    for fh in $fhours ; do
      if [[ $PDY$cyc > $lastbackup ]] ; then

#================== prepare data ==================
	COMIN=$DATA/gfs.$PDY/$cyc
	$HTAR -xvf $HPSS/$PDY$cyc/gfs_nemsiob.tar ./gfs.$PDY/$cyc/gfs.t${cyc}z.atmf$fh.nemsio
	$HTAR -xvf $HPSS/$PDY$cyc/gfs_nemsiob.tar ./gfs.$PDY/$cyc/gfs.t${cyc}z.sfcf$fh.nemsio

	if [[ ! -s ./gfs.$PDY/$cyc/gfs.t${cyc}z.atmf$fh.nemsio ]] || [[ ! -s ./gfs.$PDY/$cyc/gfs.t${cyc}z.sfcf$fh.nemsio ]]  ; then
	    echo "$PDY$cyc no data archived">> $dates
	    continue
	fi

#================== transfer data ==================
	ftp -pn $HOST <<EOF
user $USER $PASSWD
passive
cd incoming/irap/gtg_fv3
bin
put $COMIN/gfs.t${cyc}z.atmf$fh.nemsio gfs.t${cyc}z.atmf$fh.nemsio.$PDY
put $COMIN/gfs.t${cyc}z.sfcf$fh.nemsio gfs.t${cyc}z.sfcf$fh.nemsio.$PDY
bye
EOF

#================== update $dates to rzdm server ==================
        echo "$PDY$cyc ">> $dates
	scp $dates ymao@emcrzdm:/home/ftp/emc/unaff/ymao/fv3_nemsio_list/.
	echo incoming/irap/gtg_fv3
	echo $COMIN/gfs.$PDY/$cyc/gfs.t${cyc}z.atmf$fh.nemsio gfs.t${cyc}z.atmf$fh.nemsio.$PDY
	echo $COMIN/gfs.$PDY/$cyc/gfs.t${cyc}z.sfcf$fh.nemsio gfs.t${cyc}z.sfcf$fh.nemsio.$PDY

	rm -r $DATA/gfs.$PDY
      fi
    done
  done
done
date
echo done
