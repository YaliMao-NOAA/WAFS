#!/bin/sh

# (Makeup version)
# Extract retrospetive netcdf data from HPSS to super
# computer(s), then send to NCAR
#
# Suggest to run on Cray, not on Dell,
# since Dell can't connect to ftp.rap.ucar.edu
#

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

TMP=/work/noaa/stmp/ymao/stmp

DATAROOT=$TMP/netcdf2ncar_from_hpss.makeup
#rm -rf $DATA
mkdir -p $DATAROOT
cd $DATAROOT

cat > missing.dates <<EOF
stream1 2019 00 012 atm 6/7,6/8,6/14,6/21,6/22,6/26,6/27,7/16,7/20,7/25,7/26,7/29,8/4,8/10,8/12,8/18,8/23
stream1 2019 00 012 sfc 6/7,6/8,6/14,6/20,6/21,6/22,6/23,6/26,6/27,7/16,7/18,7/19,7/20,7/24,7/25,7/26,7/29,8/4,8/5,8/6,8/9,8/10,8/12,8/16,8/18,8/23
stream1 2019 00 024 atm 6/3,6/9,6/10,6/11,6/18,6/21,6/25,6/26,6/27,6/28,7/25,8/1,8/13
stream1 2019 00 024 sfc 6/3,6/9,6/10,6/11,6/18,6/21,6/23,6/25,6/26,6/27,6/28,7/2,7/3,7/19,7/22,7/25,8/1,8/2,8/12,8/13,8/16
stream1 2019 12 012 atm 6/13,6/14,6/15,6/16,6/20,6/29,7/1,7/4,7/12,7/15,7/22,7/28,8/8,8/13,8/23
stream1 2019 12 012 sfc 6/3,6/13,6/14,6/15,6/16,6/20,6/22,6/29,7/1,7/4,7/7,7/12,7/13,7/15,7/21,7/22,7/23,7/28,8/3,8/5,8/8,8/9,8/13,8/20,8/23
stream1 2019 12 024 atm 6/15,6/16,6/22,7/21,7/23,7/24,8/17,8/19,8/22,8/23
stream1 2019 12 024 sfc 6/9,6/14,6/15,6/16,6/17,6/22,6/26,7/2,7/13,7/17,7/19,7/21,7/23,7/24,7/28,8/2,8/3,8/14,8/17,8/19,8/22,8/23

stream3 2019 00 012 atm 12/7,12/19
stream3 2019 00 012 sfc 12/7,12/8,12/12,12/19,12/22,12/26
stream3 2019 00 024 atm 12/13,12/20,12/25
stream3 2019 00 024 sfc 12/9,12/13,12/19,12/20,12/23,12/25
stream3 2019 12 012 atm 12/7,12/16,12/23,12/25,12/28
stream3 2019 12 012 sfc 12/7,12/9,12/11,12/16,12/23,12/25,12/28
stream3 2019 12 024 atm 12/10,12/15,12/19,12/20,12/23,12/30
stream3 2019 12 024 sfc 12/10,12/15,12/16,12/19,12/20,12/21,12/23,12/25,12/28,12/30,12/31

stream3 2020 00 012 atm 1/1,1/4,1/6,1/7,1/10,1/16,1/21,1/22,1/23,1/24,1/26,1/30,1/31,2/6,2/9,2/14,2/16,2/18,2/22,2/25
stream3 2020 00 012 sfc 1/1,1/4,1/5,1/6,1/7,1/10,1/16,1/17,1/21,1/22,1/23,1/24,1/26,1/30,1/31,2/4,2/5,2/6,2/9,2/10,2/14,2/15,2/16,2/18,2/22,2/25
stream3 2020 00 024 atm 1/2,1/18,1/22,1/26,1/30,2/6,2/7,2/9,2/10,2/11,2/14,2/20,2/24,2/25
stream3 2020 00 024 sfc 1/2,1/15,1/18,1/20,1/22,1/26,1/29,1/30,1/31,2/6,2/7,2/8,2/9,2/10,2/11,2/14,2/20,2/21,2/24,2/25
stream3 2020 12 012 atm 1/4,1/10,1/11,1/18,1/28,1/29,2/9,2/10,2/14,2/16,2/18,2/24
stream3 2020 12 012 sfc 1/4,1/5,1/7,1/10,1/11,1/14,1/18,1/25,1/28,1/29,2/4,2/9,2/10,2/14,2/16,2/18,2/21,2/24,2/26
stream3 2020 12 024 atm 1/8,1/10,1/14,1/15,1/22,2/4,2/9,2/10,2/13,2/16,2/22,2/25
stream3 2020 12 024 sfc 1/2,1/8,1/10,1/14,1/15,1/22,1/24,1/28,1/29,2/4,2/5,2/8,2/9,2/10,2/13,2/14,2/15,2/16,2/22,2/24,2/25

EOF

while read -r when yy cyc fh file dates ; do 
if [[ ! -z $when ]] ; then
#=============================================
  echo $when $yy $cyc $fh $file
  dates=`echo $dates | sed 's/,/ /g'`
  echo $dates

  if [[ $when == "realtime" ]] ; then # 05/19/2020 ~ implementation
      HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_D/gfsv16/v16rt2
  elif [[ $when == "stream1" ]] ; then # 06/01/2019 ~ 08/31/2019
      HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_D/gfsv16/v16retro1e
  elif [[ $when == "stream2" ]] ; then # 09/01/2019 ~ 11/30/2019
      HPSS=/NCEPDEV/emc-global/5year/emc.glopara/WCOSS_D/gfsv16/v16retro2e
  elif [[ $when == "stream3" ]] ; then # 12/01/2019 ~ 05/19/2020 (from Hera)
      HPSS=/NCEPDEV/emc-global/5year/glopara/HERA/gfsv16/v16retro3e
  fi

  DATA=$DATAROOT/$when.$yy$cyc$fh$file
  mkdir -p $DATA 
  cd $DATA

  logfile=$DATAROOT/$when.$yy$cyc$fh${file}.log

  for date in $dates ; do
     mm=`echo $date | cut -d '/' -f1`
     dd=`echo $date | cut -d '/' -f2`
     [ $mm -lt 10 ] && mm="0$mm"
     [ $dd -lt 10 ] && dd="0$dd"
     PDY=$yy$mm$dd

     DATA0=$TMP/netcdf2ncar_from_hpss.$when

     if [ -s $DATA0/gfs.$PDY/$cyc/gfs.t${cyc}z.${file}f$fh.nc ] ; then
        ln -s $DATA0/gfs.$PDY/$cyc/gfs.t${cyc}z.${file}f$fh.nc gfs.t${cyc}z.${file}f$fh.nc.$PDY
	echo "$PDY$cyc $fh $file">> $logfile
     else
	$HTAR -xvf $HPSS/$PDY$cyc/gfs_netcdfb.tar ./gfs.$PDY/$cyc/gfs.t${cyc}z.${file}f$fh.nc
	if [[ -s ./gfs.$PDY/$cyc/gfs.t${cyc}z.${file}f$fh.nc ]] ; then
           ln -s ./gfs.$PDY/$cyc/gfs.t${cyc}z.${file}f$fh.nc gfs.t${cyc}z.${file}f$fh.nc.$PDY
	   echo "$PDY$cyc $fh $file">> $logfile
	else
	   echo "$PDY$cyc $fh $file not archived">> $logfile
	fi
     fi
  done

  #================== transfer data ==================
  ftp -pn $HOST <<EOF
user $USER $PASSWD
passive
cd incoming/irap/gtg_fv3
bin
prompt off
mput *${file}*
bye
EOF

#=============================================
fi
done < missing.dates

#================= if timeout ==================
set +x
timeout=`grep "Connection timed out" $TMP/netcdf2ncar_from_hpss.makeup.log`
set -x
if [[ ! $timeout == "" ]] ; then
    echo "netcdf2ncar_from_hpss.makeup not uploaded completed, there are some connections timed out"
    echo "netcdf2ncar_from_hpss.makeup" | mailx -s "Connection time out for netcdfncar_from_hpss.makeup.sh" yali.mao@noaa.gov
fi

date
echo done
