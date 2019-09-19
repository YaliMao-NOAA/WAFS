#!/bin/ksh

set -x

source ~/.bashrc

#######################################################
developMachine=`cat /etc/dev` # stratus / cirrus
thisMachine=`hostname` # c1n6.ncep.noaa.gov / s1n6.ncep.noaa.gov
# The first letters of $developMachine and $thisMachine must match; otherwise exit
if [ `echo $developMachine | cut -c 1-1` != `echo $thisMachine | cut -c 1-1` ] ; then
  exit
fi

#**************************************************************
# download CIP images at adds to local
#-------------------------------------------------------------
data2saveDir=/ptmpp1/Yali.Mao/gcip_adds
mkdir -p $data2saveDir
cd $data2saveDir

whichday=`ndate`

for hgt in 090 130 150 ; do
  wget -q -O $whichday.$hgt.png "http://www.aviationweather.gov/adds/icing/displayIcg.php?fcst_hr=00&icg_type=CIP&height=$hgt"
done

