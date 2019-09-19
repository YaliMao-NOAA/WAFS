#!/bin/ksh

years=$1

save=/global/save/Yali.Mao/vsdb/grid2grid/wafs
cd $save

months="01 02 03 04 05 06 07 08 09 10 11 12"

validations="cip gcip gcipconus"
products="blndmax blndmean ukmax ukmean usmax usmean usfip"
tempwind=twind_gfs

prodetails=" fip_cip twind_gfs"
for validation in $validations ; do
    for product in $products ; do
	prodetails="${product}_${validation} $prodetails"
    done
done

days28="01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28"
days30="$days28 29 30"
days31="$days28 29 30 31"



for product in $prodetails ; do
#----------------------
for year in $years ; do
#----------------------
  for month in $months ; do

    days=$days30
    if [[ $month == 01 ||  $month == 03 ||  $month == 05 ||  $month == 07 ||  $month == 08 ||  $month == 10 ||  $month == 12 ]] ; then
	days=$days31
    elif [[  $month == 02 ]] ; then
	days=$days28
	if [[ $(( year % 4 )) == 0 ]] ; then
	    days="$days28 29"
	fi
    fi

    if [[ $year == 2015 ]] ; then
	if [[ $month == 01 || $month == 02 || $month == 03 || $month == 04 ]] ; then
	    continue
	elif [[ $month == 05 ]] ; then
	    days="22 23 24 25 26 27 28 29 30 31"
	fi
    fi

    if [[ $year == 2016 ]] ; then
	if [[ $month -gt 04 ]] ; then
	    break
	fi
    fi


    for day in $days ; do
	if [[ ! -f ${product}_$year$month$day.vsdb ]] ; then
	    echo ${product}_$year$month$day.vsdb doesnt exist
	elif [[ ! -s ${product}_$year$month$day.vsdb ]] ; then
	    echo ${product}_$year$month$day.vsdb size=0
	fi
    done

  done
#----------------------
done
#----------------------
done

