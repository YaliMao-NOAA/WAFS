#!/bin/bash

# plot icing turbulence from Grib 2 master forecast file
usage="Usage: $HOMEsave/grads/plotWafs.sh domain prod  a_WAFS_grib2_file"

#*******************************************************
# It is loaded by .bashrc as well
if [[ `hostname` =~ ^tfe ]] ; then
   . /scratch4/NCEPDEV/global/noscrub/Yali.Mao/git/save/envir_setting.sh
else
   . /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/envir_setting.sh
fi
set -x 

ICSEVconvert=$HOMEgit/verf_g2g.v3.0.12/exec/verf_g2g_icing_convert.$MACHINE

domain=`echo $1 | tr 'A-Z' 'a-z'`	# original | conus | hawaii | alaska
prd=`echo $2 | tr 'A-Z' 'a-z'` 		# potential | severity/iseverity/rseverity | probability | turbulence
#  severity : category severity (new sensible)
# iseverity : category severity (old disorder)
# rseverity : continous severity

dataFile=$3
if [[ -z $dataFile ]] ; then
  echo $usage
  exit
fi

prefix=${domain}.
prefix=`echo $prefix | sed "s/original.//g"` # original has no prefix

if [ $prd = potential ] ; then
   dataFileTmp=${dataFile}.icip
   $WGRIB2 $dataFile | grep ":ICIP:" | $WGRIB2 -i $dataFile -grib ${dataFile}.icip
elif [[ $prd =~ severity ]] ; then
   dataFileTmp=${dataFile}.icsev
   $WGRIB2 $dataFile | grep ":ICSEV:" | $WGRIB2 -i $dataFile -grib ${dataFile}.icsev
   ##########################################
   #### start: For new ICSEV grib2 table ####
   $WGRIB2 $dataFile | grep "parmcat=19 parm=36:" | $WGRIB2 -i $dataFile -grib ${dataFile}.icsev1
   cat ${dataFile}.icsev1 >> ${dataFile}.icsev
   rm ${dataFile}.icsev1
   #### end: For new ICSEV grib2 table  #####
   ##########################################
else
   dataFileTmp=$dataFile
fi

# using 'neighbor' to avoid incorrect interpolation of icing severity category
if [[ $prd = 'severity' ]] || [[ $prd = 'iseverity' ]] ; then
    matchgrid="-new_grid_interpolation neighbor "
else
    matchgrid=""
fi

if [ $domain != 'original' ] ; then
    if [ $domain = conus ] ; then
	matchgrid="$matchgrid -new_grid_winds earth -new_grid lambert:-95:25 -126.138:451:13545 16.281:337:13545"
    elif [ $domain = hawaii ] ; then
	matchgrid="$matchgrid -new_grid_winds earth -new_grid latlon 110:560:0.25 -25:260:0.25"
    elif [ $domain = alaska ] ; then
	matchgrid="$matchgrid -new_grid_winds earth -new_grid nps:-135:60 -173:277:22500 30:213:22500"
    fi
    $WGRIB2 $dataFileTmp $matchgrid $prefix$dataFile
    if [ $dataFile != $dataFileTmp ] ; then
       rm $dataFileTmp
    fi
fi

ctlFile=$prefix$dataFile.ctl
if [ $prd = iseverity ] ; then
   # For category icing severity, swap categories first
   rm $prefix$dataFile.sev
   # https://svnemc.ncep.noaa.gov/projects/gfs_wafs/branches/g2g_verif.v3.0.0
   $ICSEVconvert $prefix$dataFile $prefix$dataFile.sev 19 234 0
   $G2CTL -verf $prefix$dataFile.sev > $ctlFile
else
   $G2CTL -verf $prefix$dataFile > $ctlFile
fi
gribmap -i $ctlFile

#=========================================================
# determine date time
#========================================================= 
avar=`$WGRIB2 $dataFile | grep 1:0`
PDYHH=`echo $avar | awk -F':' '{ print $3; }' | cut -c3-12`
FH=`echo $avar | awk -F':' '{ print $6; }' | awk '{ print $1; }'`
if [ $FH = 'anl' ] ; then
    FH='00'
fi

FH="$(printf "%02d" $(( 10#$FH )) )"
datetime=${PDYHH}z.f${FH}
if [ $FH = "00" ] ; then
  analysis="Analysis"
else
  analysis="Forecast"
fi


#=========================================================
# vertical levels
#=========================================================
# for FL 090   110  130  150
# for FL 060   100  140  180
#    hPa 800   700  600  500
#heights="1828 3048 4267 5486"
#heights="4572 5183 5792 6402 7012 7621 8231"

leveltype=`grep ",102\ \ 0,19," $ctlFile`
if [[ -n $leveltype ]] ; then  # on hybrid level
  if [[ $prd == potential || $prd =~ severity || $prd == probability ]] ; then
      levels="1828 3048 4267 5486"
  elif [[  $prd == turbulence ]] ; then
      levels="7315 9144 10363 11887 13411"
  fi
else # on pressure level
  if [[ $prd == potential || $prd =~ severity || $prd == probability ]] ; then
      levels="400 500 600 700 800"
  elif [[ $prd == turbulence ]] ; then
      levels="100 150 200 250 300 400"
  fi
fi
if [[ -n $4 ]] ; then
  levels="$4"
fi

# get rid of heights in () for all variables, control file
sed "s/\*\* (.*)/\*\* /g" -i $ctlFile

#=========================================================
# fields to plot and related grads parameters
#=========================================================
multiple="1"
if [ $prd = potential ] ; then
   clevs="5 15 25 35 45 55 65 75"
   field=ICIP
   multiple="100"
   ccols="99 105 115 125 135 145 155 165 175"
   prdname="Icing Potential"
elif [ $prd = probability ] ; then
   clevs="5 15 25 35 45 55 65 75"
   field=ICPRB
   if [ $FH = "00" ] ; then
     multiple="100/0.85"
   else
     multiple="100/(0.84-$FH/30)"
   fi
   ccols="99 105 115 125 135 145 155 165 175"
   prdname="Icing Probability=>Potential"
elif [ $prd = severity ] ; then
   clevs="0 1 2 3"
   field=var01936prs
   ccols="99 110 120 130 140 "
   prdname="Icing Severity"
elif [ $prd = iseverity ] ; then
   clevs="0 1 2 3"
   field=ICSEV
   ccols="99 110 120 130 140 "
   prdname="Icing Severity"
elif [ $prd = rseverity ] ; then
   clevs="0.08 .21 .37 .67"
   field=ICSEV
   ccols="99 110 120 130 140 "
   prdname="Icing Severity"
elif [ $prd = turbulence ] ; then
   clevs="0 .02 .05 .07 .1 .12 .14 .16 .18 .2 .22 .24 .26 .28 .3 .32 .34 .36 .38 .4 .42 .44 .46 .48 .5 .52 .54 .56 .58 .6 .62 .64 .66 .68 .7 .72 .74 .76 .78 .8 .82 .84 .86 .88 .9 .92 .94 .96 .98"
   field="EDPARM"
   ccols="21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70"
   prdname="Graphical Turbulence Guidance"
else
   echo "Warning!!!!!!! No plot for $prd"
   exit
fi
fields=`grep $field $ctlFile  | awk '{ print $1; }'`
if [[ -z $fields ]] ; then
   echo "Warning!!!! The grib file doesn't have field $fields."
   exit
fi

#=========================================================
# which colors.gs and cbar.gs to copy
#=========================================================
if [ $prd = turbulence ] ; then
    cp $HOMEsave/grads/gtgColors.gs colors.gs
else
    cp $HOMEsave/grads/icingColors.gs colors.gs
fi
if [[ $prd =~ severity ]] ; then
   cp $HOMEsave/grads/cbarCategory.gs cbar.gs
elif [ $prd = turbulence ] ; then
   cp $HOMEsave/grads/cbarGTG.gs cbar.gs
else
   cp $HOMEsave/grads/cbar.gs .
fi

cat <<EOF >tmp.gs
*
'open $ctlFile'
EOF

##########################################################
# Loop 1: WAFS may have mean/max per field
for field in $fields ; do
##########################################################

echo $field
fieldshort=`echo $field | rev | cut -c 4- | rev | tr 'A-Z' 'a-z'`
if [[ $field =~ var01930 ]] ; then
    fieldshort='gtg'
elif [[ $field =~ var01928 ]] ; then
    fieldshort='mwt'
elif [[ $field =~ var01929 ]] ; then
    fieldshort='cat'
fi
if [[ $field =~ EDPARM ]] ; then
    fieldshort='gtg'
elif [[ $field =~ MWTURB ]] ; then
    fieldshort='mwt'
elif [[ $field =~ CATEDR ]] ; then
    fieldshort='cat'
fi

# average/maximum or none for high resolution
#--------------------------------------------
if [[ $field =~ ave ]] ; then
    prdkind=" MEAN"
elif [[ $field =~ max ]] ; then
    prdkind=" MAX"
else
    prdkind=""
fi

##########################################################
# Loop 2: vertical levles.
##########################################################
for lvl in $levels ; do

if [[ -n $leveltype ]] ; then # hybrid level
  clvl=$( echo "$lvl*3.28 + 20" | bc )
  clvl=$( echo " $clvl  * 100 / 100 / 100" | bc )
  clvl=`echo $clvl | cut -c1-3`
  clvl"$(printf "%03d\n" $(( 10#$clvl )) )"
  clvl="FL$clvl"
else                          # pressure level
  clvl="${lvl}hPa"
fi

cat <<EOF >>tmp.gs
'c'
'set lev $lvl'
'set clevs $clevs'
'set ccols $ccols'
'd $field*$multiple'
'cbar.gs'
'set string 1  tl 10'
'set strsiz .2'
'draw string 0.6 7.9 $prdname$prdkind on ${clvl}'
'set string 1  tr 1'
'set strsiz 0.15'
'draw string 10.5 7.7 $analysis at $datetime'
'printim $prefix$datetime.${clvl}.$fieldshort.png png'
EOF

done # loop lvl
done # loop field

cat colors.gs tmp.gs > plotComp.gs
grads -lbxc "plotComp.gs"

rm tmp.gs
