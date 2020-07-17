#!/bin/sh

# Back up real-time & retrospetive netcdf data
# from super computer(s) to NCAR & HPSS.
#
# Suggest to run on Cray, not on Dell,
# since Dell can't connect to ftp.rap.ucar.edu

# It turns out it may take 15 minutes to finish one set of atm&sfc files
# For real practice, transfer at most 4 days (96 hours) of data for each cronjob

# Basic idea:
# 1. List all data dates available under $COMROOT (user-defined)
# 2. Get the latest date, cycle and forecast hour (PDY2, cyc2, fhr2)
# 3. 1) To HPSS, only archive data one day ahead of PDY2 to guaranteed
#       a completed set of data for all cycles and all forecast hours.
#    2) To NCAR, save and exchange a backup file list to get 'lastbackup'
#       through a third-party space, like rzdm. 
#       If lastbackup is "" (first time run), or lastbackup is too old,
#       PDY1=PDY2-2 and lastbackup=$PDY2$cyc2

if [[ `hostname` =~ ^h ]] ; then
#=====================================================#

  export MACHINE=hera
  export TMP='/scratch2/NCEPDEV/stmp3/Yali.Mao'

  # run this bash before 'module load'

  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
      . $MODULESHOME/init/profile
  else
      . /apps/lmod/7.7.18/init/bash
      . /apps/lmod/7.7.18/init/profile
  fi

  module use /apps/modules/modulefiles
  module load intel/18.0.5.274

  module load hpss

  module use /apps/modules/modulefamilies/intel
  module load impi/2018.0.4

  module use /scratch2/NCEPDEV/nwprod/NCEPLIBS/modulefiles
  module load grib_util/1.1.1
  module load prod_util/1.1.0

elif [[ `hostname` =~ ^[l|s]login ]] ; then
#=====================================================#                                                                                                                                     
  export MACHINE=cray
  export TMP='/gpfs/hps/ptmp/Hui-Ya.Chuang'

  # run this bash before 'module load'                                                                                                                                                      
  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
  else
      . /opt/modules/default/init/bash
  fi

  module use -a /opt/cray/craype/default/modulefiles
  module use -a /opt/cray/ari/modulefiles
  module use -a /gpfs/hps/nco/ops/nwprod/modulefiles
  module use -a /usrx/local/prod/modulefiles

  module load PrgEnv-intel
  module load cray-mpich
  module load xt-lsfhpc/9.1.3
  module load hpss/4.1.0.3

  module load grib_util/1.1.0
  module load prod_util
  module load prod_envir
else
#=====================================================#                                                                                                                                     
  export MACHINE=dell
  export TMP='/gpfs/dell3/ptmp/Hui-Ya.Chuang'

  # run this bash before 'module load'                                                                                                                                                      
  if [ ! -z $MODULESHOME ]; then
      . $MODULESHOME/init/bash
      . $MODULESHOME/init/profile
  else
      . /usrx/local/prod/lmod/lmod/init/bash
      . /usrx/local/prod/lmod/lmod/init/profile
  fi

  module use /usrx/local/dev/modulefiles

  module load ips/18.0.1.163
  module load impi/18.0.1
  module load NetCDF/4.5.0
  module load lsf/10.1

  module load EnvVars/1.0.2
  module load pm5/1.0
  module load HPSS/5.0.2.5
  module load mktgs/1.0
  module load rsync/3.1.2
  module load prod_envir/1.0.2
  module load grib_util/1.0.6
  module load prod_util/1.1.0
fi

set -xa

date

HOST='ftp.rap.ucar.edu'
USER='anonymous'
PASSWD='yali.mao@noaa.gov'

HTAR=htar

when=$1

PDY=`$NDATE -24 | cut -c1-8`

DATA=$TMP/netcdf2ncar.$when
#rm -rf $DATA
mkdir -p $DATA

cycles=${cycles:-"00 12"}
fhours=${fhours:-"012 024"}

if [[ $when == "realtime" ]] ; then # 05/19/2020 ~ implementation
    COMROOT=/gpfs/dell3/ptmp/emc.glopara/ROTDIRS/v16rt2
elif [[ $when == "stream1" ]] ; then # 06/01/2019 ~ 08/31/2019
    COMROOT=/gpfs/dell6/ptmp/emc.glopara/ROTDIRS/v16retro1e
elif [[ $when == "stream2" ]] ; then # 09/01/2019 ~ 11/30/2019
    COMROOT= /gpfs/dell6/ptmp/emc.glopara/ROTDIRS/v16retro2e
elif [[ $when == "stream3" ]] ; then # 12/01/2019 ~ 03/31/2020 (On Hera)
    COMROOT=/scratch1/NCEPDEV/global/glopara/ptmp/v16retro3e
fi


PDY2=`ls $COMROOT | grep "^gfs\." | tail -1 | cut -c5-12`

#*******************************************************************
#**************** To NCAR, at most 4 days of data  *****************
#*******************************************************************
cd $DATA

latestdata=`ls $COMROOT/gfs.$PDY2/??/*atmf*nc | tail -1`
cyc2=`echo $latestdata | sed -e "s/.*\/\([0-9]\{2\}\)\/.*/\1/"`
fhr2=`echo $latestdata | sed -e "s/.*f\([0-9]\{3\}\).nc/\1/"`

dates=$DATA/ncar_dates.$when
lastbackup=`cat $dates | tail -1 | cut -c1-14`  # YYYYMMDDHH FFF

# Able to transfer at most 4 days of data, if first time or lastbackup is too old
if [[ $lastbackup = "" ]] ; then  # first time run
    PDY1=`$NDATE -96 ${PDY2}00 | cut -c1-8`
    lastbackup="$PDY1$cyc2"
else
    PDY1=`echo $lastbackup | cut -c1-10`
    PDY=`$NDATE -96 $PDY2$cyc2`
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
      if [ ! -s $COMIN/gfs.t${cyc}z.sfcf$fh.nc ] ; then
	echo "SKIP, file does not exist: $COMIN/gfs.t${cyc}z.sfcf$fh.nc"
	echo "$COMIN/gfs.t${cyc}z.sfcf$fh.nc is missing." | mailx -s "Data missing for netcdf2ncar.sh" yali.mao@noaa.gov
	echo "$PDY$cyc $fh sfc not available">> $dates
      elif [ ! -s $COMIN/gfs.t${cyc}z.atmf$fh.nc ] ; then
	echo "SKIP, file does not exist: $COMIN/gfs.t${cyc}z.atmf$fh.nc"
	echo "$COMIN/gfs.t${cyc}z.atmf$fh.nc is missing." | mailx -s "Data missing for netcdf2ncar.sh" yali.mao@noaa.gov
	echo "$PDY$cyc $fh atm not available">> $dates
      else
	echo "$PDY$cyc $fh">> $dates
	ln -s $COMIN/gfs.t${cyc}z.atmf$fh.nc gfs.t${cyc}z.atmf$fh.nc.$PDY
	ln -s $COMIN/gfs.t${cyc}z.sfcf$fh.nc gfs.t${cyc}z.sfcf$fh.nc.$PDY

#================= transfer data ==================
	ftp -pn $HOST <<EOF
user $USER $PASSWD
passive
cd incoming/irap/gtg_fv3
bin
prompt
put gfs.t${cyc}z.atmf$fh.nc.$PDY
put gfs.t${cyc}z.sfcf$fh.nc.$PDY
bye
EOF

#================= if timeout ==================
	set +x
	timeout=`grep "Connection timed out" $TMP/netcdf2ncar.$when.log`
	set -x
	if [[ $timeout == "" ]] ; then
	    echo incoming/irap/gtg_fv3
	else
	    echo "$PDY$cyc $fh not uploaded, connection timed out"
	    echo "$PDY$cyc $fh" | mailx -s "Connection time out for netcdfncar.sh" yali.mao@noaa.gov
	fi

      fi
    done

  done
  PDY=`$NDATE 24 ${PDY}00 | cut -c1-8`
done


date
echo done
