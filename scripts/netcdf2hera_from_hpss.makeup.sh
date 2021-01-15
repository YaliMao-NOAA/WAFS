#!/bin/sh

# (Makeup version)
# Extract retrospetive netcdf data from HPSS to super
# computer(s), then send to RZDM
#

source ~/.bashrc

set -xa

date

# remote server and folder
remoteServer=ymao@emcrzdm.ncep.noaa.gov
remotefolder=/home/ftp/emc/unaff/ymao/gfsv16_4ncar

HTAR=htar

DATAROOT=$TMP/netcdf2hera_from_hpss.makeup
#rm -rf $DATA
mkdir -p $DATAROOT
cd $DATAROOT

cat > missing.dates <<EOF
stream3 2019 06 018 sfc 12/1,12/2,12/3,12/4,12/5,12/6,12/7,12/8,12/9,12/10,12/11,12/12,12/13,12/14,12/15,12/16,12/17,12/18,12/19,12/20,12/21,12/22,12/23,12/24,12/25,12/26,12/27,12/28,12/29,12/30,12/31
stream3 2019 18 030 atm 12/1,12/2,12/3,12/4,12/5,12/6,12/7,12/8,12/9,12/10,12/11,12/12,12/13,12/14,12/15,12/16,12/17,12/18,12/19,12/20,12/21,12/22,12/23,12/24,12/25,12/26,12/27,12/28,12/29,12/30,12/31
stream3 2019 18 030 sfc 12/1,12/2,12/3,12/4,12/5,12/6,12/7,12/8,12/9,12/10,12/11,12/12,12/13,12/14,12/15,12/16,12/17,12/18,12/19,12/20,12/21,12/22,12/23,12/24,12/25,12/26,12/27,12/28,12/29,12/30,12/31
stream3 2019 12 036 sfc 12/1,12/2,12/3,12/4,12/5,12/6,12/7,12/8,12/9,12/10,12/11,12/12,12/13,12/14,12/15,12/16,12/17,12/18,12/19,12/20,12/21,12/22,12/23,12/24,12/25,12/26,12/27,12/28,12/29,12/30,12/31
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

  #================== transfer data to RZDM ==================
  scp -p *${file}* ${remoteServer}:$remotefolder/.
#=============================================
fi
done < missing.dates

date
echo done
