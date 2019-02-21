#!/bin/ksh
#####################################################################
# Name of Script: verf_g2g_get_wafs.sh
# This script obtains the Icing, Temperature, UV data
# and interpolate them onto the corresponding 130 45 193 grid
# History:   Binbin Zhou  -- May 2010, original version
#            Julia Zhu  -- June 30th, second version
#            B. Zhou    -- Nov. 15, 2014 upgraded to grib2
#            Y. Mao     -- March 15, 2015 added for WAFS verification
#####################################################################
set -x

model_name=$1
vday=$2
valid=$3

if [[ $valid = 'cip'  || $valid = 'gcipconus' ]] ; then
   matchgrid="-new_grid_winds earth -new_grid lambert:-95:25 -126.138:451:13545 16.281:337:13545"
elif [[ $valid = 'gcip' || $valid = 'gfs' ]] ; then 
   # Global project: G45
   # Bonus: make sure all data on the same orientation from North to South
   # orietation=`$WGRIB2 $imfile -scan | grep :scan=4`
   # matchgrid="-new_grid_winds earth -grib"
   matchgrid="-new_grid_winds earth -new_grid latlon 0:288:1.25 90:145:-1.25"
fi

# forecast cycle for cip
# HHFCSTcip="00 03 06 09 12 15 18 21"
# forecast hour for cip
FHOURScip="03 06 09 12"

# forecast cycle for gcip
HHFCSTgcip="00 06 12 18"
# forecast hour for gcip
FHOURSgcip=$VHoursIcing

# forecast cycle for GFS t u v
HHFCSTgfs="00 06 12 18"
# forecast hour for gcip
FHOURSgfs=$VHoursTwind

# Thinned vertical levels
#---------------------
# for icing
# 900  800  700  600  500  400 HPA
# 030  060  100  140  180  240 FL
# 914 1828 3048 4267 5486 7315 M
PLEVELSicing=$VLevelIcing
#HLEVELSicingicing="914 1828 3048 4267 5486 7315"
# for T U V
PLEVELStwind=$VLevelTwind


#------------------------------------
#   WAFS icing verification
if [[ $valid =~ cip ]] ; then
#------------------------------------

  if [ $model_name = cip ] ; then    # Observation CIP data, every 3 hours
    # re-organize CIP data for each HH, outputs are adds.cip.t${hh}z.f00
    export ADDSDIR=${CIPDIR:-$DCOMROOT/us007003/}
    # will convert to adds.cip.t${hh}z.f00 or adds.fip.t${hh}z.f00
    ksh $USHverf_g2g/verf_g2g_icing_convertadds.sh CIP PRB $vday "$HLEVELSicing"
    #CIP is on hybrid levels, needs to be converted on pressure levels:
    for hh in $HHOBS3 ; do
      imfile=adds.cip.t${hh}z.f00
      $HOMEverf_g2g/exec/verf_g2g_icing_convert $imfile $COMOUT/${model_name}.t${hh}z.grd$vgrid.f00.grib2 19 233
      echo "{model_name}.t${hh}z.grd$vgrid.f00.grib2 done"
      rm -f $imfile
    done

  elif [[ $model_name =~ gcip ]] ; then  # Observation GCIP data, every 3 hours
    for hh in $HHOBS3 ; do
      imfile=$GCIPDIR.$vday/gfs.t${hh}z.gcip.f00.grib2
      for lvl in $PLEVELSicing ; do
        $WGRIB2 $imfile -match ":ICIP:$lvl mb:" $matchgrid x.$lvl
	cat x.$lvl >>  $COMOUT/${model_name}.t${hh}z.grd$vgrid.f00.grib2
	echo "{model_name}.t${hh}z.grd$vgrid.f00.grib2 done"
      done #lvl
    done #hh
    rm -f x.*

  elif [[ $model_name =~ 'blnd' || $model_name =~ 'us' || $model_name =~ 'uk' || $model_name =~ 'gfip' ]] ; then

    for hh in $HHFCSTgcip ; do
    for fh in $FHOURSgcip  ; do
      outfile=$COMOUT/${model_name}.t${hh}z.grd$vgrid.f$fh.grib2
      if [[ -s $outfile ]] ; then
	  continue
      fi

      if [[ $model_name =~ 'blnd' ]] ; then
	 imfile=$COMINBLND.$vday/WAFS_blended_$vday${hh}f$fh.grib2
      fi
      if [[ $model_name =~ 'us' ]] ; then # us mean/max
	 imfile=$COMINUS.$vday/gfs.t${hh}z.wafs_grb45f${fh}.grib2
      fi
      if [[ $model_name =~ 'uk' ]] ; then
	 imfile=$COMINUK/$vday/wgrbbul/ukmet_wafs/EGRR_WAFS_unblended_${vday}_${hh}z_t$fh.grib2
      fi
      if [[ $model_name =~ 'gfip' ]] ; then # high resolution
	 imfile=$COMINGFIP.$vday/gfs.t${hh}z.master.grb2f$fh
      fi

      for lvl in $PLEVELSicing ; do
	if [[ $model_name =~ 'mean' ]] ; then
          $WGRIB2 $imfile -match ":ICIP:$lvl mb:" -match ":spatial ave" $matchgrid x.$lvl
	elif  [[ $model_name =~ 'max' ]] ; then
          $WGRIB2 $imfile -match ":ICIP:$lvl mb:" -match ":spatial max" $matchgrid x.$lvl
	else # high resolution
          $WGRIB2 $imfile -match ":ICIP:$lvl mb:" $matchgrid x.$lvl
	fi
        cat x.$lvl >> $outfile
      done
      rm -f x.*
    done
    done

    echo "copying of $model_name done"

  elif [ $model_name = fip ] ; then
    # re-organize FIP data for each HH and FH, outputs are adds.fip.t${hh}z.f$fh
    export ADDSDIR=${COMINFIP:-$DCOMROOT/us007003}
    ksh $USHverf_g2g/verf_g2g_icing_convertadds.sh FIP PRB $vday "$HLEVELSicing"
    #FIP is on hybrid levels, needs to be converted on pressure levels:
    for hh in $HHOBS3 ; do
    for fh in $FHOURScip ; do
      outfile=$COMOUT/${model_name}.t${hh}z.grd$vgrid.f$fh.grib2
      if [[ -s $outfile ]] ; then
	  continue
      fi

      imfile=adds.fip.t${hh}z.f$fh
      $HOMEverf_g2g/exec/verf_g2g_icing_convert $imfile $outfile 19 233
      rm $imfile
    done
    done

    echo "copying of $model_name done"
  fi

#------------------------------------
#   WAFS T U V verification
elif [ $valid = gfs ] ; then
#------------------------------------

  if [ $model_name = gfs ] ; then	# analysis GFS data, every 6 hours
    for hh in $HHOBS6 ; do
      imfile=$COMINGFSV.$vday/gfs.t${hh}z.master.grb2anl
      for lvl in $PLEVELStwind ; do
        $WGRIB2 $imfile -match ":TMP:$lvl mb:" $matchgrid  t.$lvl
        $WGRIB2 $imfile -match  "GRD:$lvl mb:" $matchgrid uv.$lvl
	cat t.$lvl uv.$lvl >>  $COMOUT/${model_name}.t${hh}z.grd$vgrid.f00.grib2
	echo "${model_name}.t${hh}z.grd$vgrid.f00.grib2 done"
      done #lvl
    done #hh
    rm -f t.$lvl uv.$lvl

  else					# forecast GFS data T U V
    for hh in $HHFCSTgfs ; do
    for fh in $FHOURSgfs  ; do
      outfile=$COMOUT/${model_name}.t${hh}z.grd$vgrid.f$fh.grib2
      if [[ -s $outfile ]] ; then
	  continue
      fi
      imfile=$COMINGFSP.$vday/gfs.t${hh}z.master.grb2f$fh
      for lvl in $PLEVELStwind ; do
        $WGRIB2 $imfile -match ":TMP:$lvl mb:" $matchgrid  t.$lvl
        $WGRIB2 $imfile -match  "GRD:$lvl mb:" $matchgrid uv.$lvl
	cat t.$lvl uv.$lvl >> $outfile
      done
      rm -f t.$lvl uv.$lvl
    done
    done
    echo "copying of $model_name done"
  fi

#------------------------------------
fi
#------------------------------------
