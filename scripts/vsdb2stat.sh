#!/bin/bash

function convertFormat(){
    allfile=$1
    if [[ $allfile =~ "tmp" ]] ; then
	var="TMP      K          "
	linetype="SL1L2"
    elif [[ $allfile =~ "wind" ]] ; then
	var="WIND     m/s        "
	linetype="VL1L2"
    elif [[ $allfile =~ "w80" ]] ; then
	var="WIND80     m/s        "
	linetype="VL1L2"
    elif [[ $allfile =~ "wdir" ]] ; then
	var="WDIR     deg        "
	linetype="SL1L2"
    fi
    regions=(G45 AR2 ASIA AUNZ EAST NAMR NHM NPCF SHM TRP)
    newregions=(G045 NATL_AR2 ASIA AUNZ EAST NAMER NHEM NPO SHEM TROPICS)

    length=${#regions[@]}
    for (( j=0; j<${length}; j++ )); do
	region=${regions[$j]}
	if [ $region = 'G45' ] ; then
	    grep " G45 " $1 > $region.vsdb
	else
	    grep "G45/$region" $1 > $region.vsdb
	fi
    done

    for (( j=0; j<${length}; j++ )); do
	region=${regions[$j]}
	newregion=${newregions[$j]}
	echo $region $newregion internal test
	if [ -f $region.vsdb ] ; then
	    while IFS= read -r line ; do
		ff=`echo $line | cut -d " " -f 3`
		vv=`echo $line | cut -d " " -f 4`
		vday=`echo $vv | cut -c 1-8`
		vhour=`echo $vv | cut -c 9-10`
		pp=`echo $line | cut -d " " -f 9`
		nn=`echo $line | cut -d " " -f 11`
		nn=$(printf "%.0f" "$nn") # convert to integer
		statics=""
		if [ $linetype = "SL1L2" ] ; then
		    scientific_notation=`echo $line | cut -d " " -f 12-16`
		    for sn in $scientific_notation ; do
			decimal=$(printf "%.5f" $sn)
			statics="$statics $decimal"
		    done
		    statics="$statics NA"
		elif [ $linetype = "VL1L2" ] ; then
		    scientific_notation=`echo $line | cut -d " " -f 16-18`
		    for sn in $scientific_notation ; do
                        decimal=$(printf "%.5f" $sn)
                        statics="$statics $decimal"
                    done
		    statics="NA NA $statics NA"
		fi
		echo "V00 gfs   G045 ${ff}0000    ${vday}_${vhour}0000 ${vday}_${vhour}0000 000000   ${vday}_${vhour}0000 ${vday}_${vhour}0000 $var          $pp     $var         $pp    ANALYS $newregion  NEAREST     1          NA          NA         NA         NA    SL1L2      $nn $statics" >> $outputfilename
	    done < $region.vsdb
	fi
    done    
}

DATA=/lfs/h2/emc/ptmp/$USER/vsdb2stat
mkdir -p $DATA
cd $DATA ; rm *

VSDBin=/lfs/h2/emc/vpppg/noscrub/yali.mao/vsdb/wafs/prod.prod
VSDBout=/lfs/h2/emc/vpppg/noscrub/yali.mao/stats_from_vsdb



pdy=`echo $twind |  sed s/.*twind_gfs_//g | sed s/.vsdb//g`
YYYY=`cat $PDY | cut -c 1-4`
VSDBout=$VSDBout/$YYYY
mkdir -p $VSDBout

twind="../twind_gfs_20230719.vsdb"


outputfilename=evs.stats.wafs.atmos.grid2grid_uvt1p25.v${pdy}.stat
echo "VERSION MODEL DESC FCST_LEAD FCST_VALID_BEG  FCST_VALID_END  OBS_LEAD OBS_VALID_BEG   OBS_VALID_END   FCST_VAR FCST_UNITS FCST_LEV OBS_VAR OBS_UNITS OBS_LEV OBTYPE VX_MASK  INTERP_MTHD INTERP_PNTS FCST_THRESH OBS_THRESH COV_THRESH ALPHA LINE_TYPE" > $outputfilename

temp=tmp.vsdb
wind=wind.vsdb
wind80=w80.vsdb
wdir=wdir.vsdb
grep "SL1L2 T " $twind > $temp
grep "SL1L2 DIRECTION " $twind > $wdir 
grep "VL1L2 WIND " $twind > $wind
grep "VL1L2 WIND80 " $twind > $wind80


convertFormat $temp SL1L2
convertFormat $wind VL1L2
convertFormat $wind80 VL1L2
convertFormat $wdir SL1L2
