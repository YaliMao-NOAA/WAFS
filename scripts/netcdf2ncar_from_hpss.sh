#!/bin/sh

# Extract retrospetive netcdf data from HPSS to super
# computer(s), then send to NCAR
#
# PDYs, cycles, fhours can be exported, useful if 
# previous run has missing some PDY, cycle, fhour
# 
# Suggest to run on Cray, not on Dell,
# since Dell can't connect to ftp.rap.ucar.edu
#
# It turns out it may take ?? minutes to finish one set of atm&sfc files
# (including htar and ftp)
# For real practice, transfer at most 8 days (192 hours) of data for each cronjob

# Tip: To transfer data to UCAR FTP server, it seems more efficient 
#      to 'put' one file by one file than to 'mput'

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
  export TMP='/gpfs/hps3/ptmp/Hui-Ya.Chuang'

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
user=`whoami`

HOST='ftp.rap.ucar.edu'
USER='anonymous'
PASSWD='yali.mao@noaa.gov'

HTAR=htar

when=$1

DATA=$TMP/netcdf2ncar_from_hpss.$when/$PDY
#rm -rf $DATA
mkdir -p $DATA

cycles=${cycles:-"00 12"} # cycles can be exported for individual missing data
fhours=${fhours:-"012 024"} # fhours can be exported for individual missing data

if [[ $when == "realtime" ]] ; then # 05/19/2020 ~ implementation
  HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_D/gfsv16/v16rt2
  startdate="YYYYMMDDHH"
elif [[ $when == "stream1" ]] ; then # 06/01/2019 ~ 08/31/2019
  HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_D/gfsv16/v16retro1e
  startdate="2019060100"
elif [[ $when == "stream2" ]] ; then # 09/01/2019 ~ 11/30/2019
  HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_D/gfsv16/v16retro2e
  startdate="YYYYMMDDHH"
elif [[ $when == "stream3" ]] ; then # 12/01/2019 ~ 03/31/2020 (from Hera)
  HPSS=/NCEPDEV/emc-global/5year/glopara/HERA/gfsv16/v16retro3e
  startdate="2019120100"
fi

cd $DATA

dates=$DATA/archive_dates.$when
lastbackup=`cat $dates | tail -1 | cut -c1-10`

if [[ $lastbackup = "" ]] ; then
    # pretend lastbackup is 6 hours before startdate
    lastbackup=`$NDATE  -6 $startdate` # YYYYMMDDHH
fi

# usually move ahead 6 hours ahead, but for current project, we need data every 12 hours
PDY1=`$NDATE 12 $lastbackup | cut -c1-8`
# Able to transfer 8 days of data in one day, 192=204-12 # updated on July 14th 2020
PDY2=`$NDATE 204 $lastbackup | cut -c1-8`


PDY=$PDY1
while [[ $PDY < $PDY2 ]] ; do
    PDYall="$PDYall $PDY"
    PDY=`$NDATE 24 ${PDY}00 | cut -c1-8`
done
PDYs=${PDYs:-"$PDYall"}  # PDYs can be exported for individual missing data

for PDY in $PDYs ; do
  for cyc in $cycles ; do
    for fh in $fhours ; do
      if [[ $PDY$cyc > $lastbackup ]] ; then

#================== prepare data ==================
	COMIN=$DATA/gfs.$PDY/$cyc
	$HTAR -xvf $HPSS/$PDY$cyc/gfs_netcdfb.tar ./gfs.$PDY/$cyc/gfs.t${cyc}z.atmf$fh.nc
	$HTAR -xvf $HPSS/$PDY$cyc/gfs_netcdfb.tar ./gfs.$PDY/$cyc/gfs.t${cyc}z.sfcf$fh.nc

	if [[ ! -s ./gfs.$PDY/$cyc/gfs.t${cyc}z.atmf$fh.nc ]] || [[ ! -s ./gfs.$PDY/$cyc/gfs.t${cyc}z.sfcf$fh.nc ]]  ; then
	    echo "$PDY$cyc $fh no data archived">> $dates
	    continue
	fi

#================== transfer data ==================
	ftp -pn $HOST <<EOF
user $USER $PASSWD
passive
cd incoming/irap/gtg_fv3
bin
put $COMIN/gfs.t${cyc}z.atmf$fh.nc gfs.t${cyc}z.atmf$fh.nc.$PDY
put $COMIN/gfs.t${cyc}z.sfcf$fh.nc gfs.t${cyc}z.sfcf$fh.nc.$PDY
bye
EOF

#================= if timeout ==================
	set +x
	timeout=`grep "Connection timed out" $TMP/netcdf2ncar_from_hpss.$when.log`
	set -x
	if [[ $timeout == "" ]] ; then
	    echo incoming/irap/gtg_fv3
            echo "$PDY$cyc $fh">> $dates
	else
	    echo "$PDY$cyc $fh not uploaded, connection timed out"
	    echo "$PDY$cyc $fh" | mailx -s "Connection time out for netcdfncar_from_hpss.sh" yali.mao@noaa.gov
	fi
#	rm -r $DATA/gfs.$PDY
      fi
    done
  done
done

date
echo done
