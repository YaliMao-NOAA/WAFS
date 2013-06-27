#!/bin/ksh
set -ax
export filehd=MYDdust.aod_conc
export version=v6.3.4
export nesdis=dust
#ftpdir=/pub/smcd/spb/shobha/DUST/GRIB
ftpdir=/DUST/output
export  datadir=/meso/noscrub/$LOGNAME/aod-dust/conc

cd $datadir

export nest=$1
export vday=$2

export TODAY=$vday

###while [ $TODAY -le $jedate ] ; do

if [[ -d $nesdis.${TODAY} ]]; then
  echo $nesdis.$TODAY" existed"
else
  mkdir $nesdis.$TODAY
fi

export  data=$datadir/$nesdis.$TODAY

ftp -n << EOF
verbose
open satepsanone.nesdis.noaa.gov
user anonymous perry.shafran@noaa.gov
bi
prompt

cd $ftpdir

lcd $data

mget ${filehd}.${version}.${TODAY}*.grib

close
EOF

TODAY0=`/nwprod/util/exec/ndate +24 ${TODAY}06`
TODAY=`echo $TODAY0 | cut -c1-8`

##done
#mget ${filehd}.${version}.P${TODAY}*.grib
