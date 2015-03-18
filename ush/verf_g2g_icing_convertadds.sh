#!/bin/ksh

## re-organize ADDS FIP CIP in way of tHHz and fFH


set -xa

# usage of convert_adds.sh
usage="Usage: ksh convert_adds.sh CIP|FIP PRB|SEV YYYYMMDDHH [levels]"

if [ $# -lt 3 ] ; then
  echo $usage
  exit
fi

prod=$1
prod_uc=`echo $prod | tr '[a-z]' '[A-Z]'`
prod_lc=`echo $prod | tr '[A-Z]' '[a-z]'`
if [[ $prod_uc != "CIP" ]] && [[ $prod_uc != "FIP" ]] ; then
  echo "Input CIP or FIP"
  echo $usage
  exit
fi

field=$2
field=`echo $field | tr '[a-z]' '[A-Z]'`
if [[ $field != "PRB" ]]  && [[ $field != "SEV" ]] ; then
  echo "Input PRB or SEV"
  echo $usage
  exit
fi

day=$3
if [[ -z $day ]] ; then
#  day=`date +%Y%m%d%H`
  echo "Input YYYYMMDDHH"
  echo $usage
  exit
fi
cycles=`echo $day | cut -c9-10`
day=`echo $day | cut -c1-8`
if [[ -z $cycles ]] ; then
  cycles="00 03 06 09 12 15 18 21"
fi

levels=$4
if [[ -z $levels ]] ; then
  levels="9144 8839 8534 8229 7924 7620 7315 7010 6705 6400 6096 5791 5486 5181 4876 4572 4267 3962 3657 3352 3048 2743 2438 2133 1828 1524 1219 914 609 304"
fi

UTIL=${EXECutil:-/nwprod/util/exec}

ADDSDIR=${ADDSDIR:-/dcomdev/us007003}

rm $prod_lc.*

#for hh in 00 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 ; do
for hh in $cycles ; do
  file=$ADDSDIR/$day/wgrbbul/adds_$prod_lc/ADDS_${prod_uc}_$hh
  if [ -e $file ] ; then
     for lvl in $levels ; do
       if [ $prod_uc = "FIP" ] ; then
         for fh in 3 6 9 12; do
           fh2=`printf "%02i" $fh`
           search1=":d=$day$hh:IC${field}:$lvl"
 	   search2=":$fh hour fcst:"
           $UTIL/wgrib2 $file -match "$search1" -match "$search2" -grib x.$lvl
           cat x.$lvl >> adds.${prod_lc}.t${hh}z.f${fh2}
         done #fh
       else # CIP
 	   search1=":d=$day$hh:IC${field}:$lvl"
           $UTIL/wgrib2 $file -match "$search1" -grib x.$lvl
           cat x.$lvl >> adds.${prod_lc}.t${hh}z.f00
       fi
     done # lvl
  else
     echo $file does not exist
  fi
done #hh

rm -f x.* 
