#!/bin/sh

set -xa

fh=$1

# PDY, cyc and fh must be exported by the caller

prod=${prod:-prod}

# For GCIP:
if [[ $fh = "000" ]] || [[ $fh = "003" ]] ; then
  cyc2=$(( cyc + fh ))
  cyc2=`printf "%02d" $cyc2`
fi

fhour=$fh
if [ $prod = para ] ; then
  fh="$(printf "%02d" $(( 10#$fh )) )"
fi


# Skip plotting if forecast hour is greater than 36
if [[ $fhour > 036 ]] ; then
  exit 0 
fi

########################################################
###  Do plotting                                     ###
########################################################

DATAplot=$DATAROOTplot/plot.f$fh
mkdir -p $DATAplot
cd $DATAplot
rm $DATAplot/*

if [[ $fhour == "000" ]] || [[ $fhour == "003" ]] ; then
  # copy GCIP data
  cp $DATAgrib2/*t${cyc2}z.gcip.f00.grib2 .
else
  # copy GFIP data
  cp $DATAgrib2/gfs.t${cyc}z.wafs_0p25.grb2f$fh .
fi
for grb2file in `ls` ; do
   severity=severity

   sh $HOMEsave/grads/plotWafs.sh original potential $grb2file
   sh $HOMEsave/grads/plotWafs.sh original $severity  $grb2file
   sh $HOMEsave/grads/plotWafs.sh conus  potential $grb2file
   sh $HOMEsave/grads/plotWafs.sh conus  $severity  $grb2file
   sh $HOMEsave/grads/plotWafs.sh hawaii  potential $grb2file
   sh $HOMEsave/grads/plotWafs.sh hawaii  $severity  $grb2file
   sh $HOMEsave/grads/plotWafs.sh alaska  potential $grb2file
   sh $HOMEsave/grads/plotWafs.sh alaska  $severity  $grb2file

   if [[ $grb2file =~ "wafs" ]] ; then
       sh $HOMEsave/grads/plotWafs.sh original turbulence $grb2file
       sh $HOMEsave/grads/plotWafs.sh conus turbulence $grb2file
       sh $HOMEsave/grads/plotWafs.sh hawaii turbulence $grb2file
       sh $HOMEsave/grads/plotWafs.sh alaska turbulence $grb2file
   fi
done

# Don't upload CAT MWT to rzdm web site
rm *cat.png
rm *mwt.png

# Mark this job for $fh is finished 
echo $PDY $cyc $fh >> $TMP/GCIP_GFIP_GTG_2_rzdm.working/GCIP_GFIP_GTG_2_rzdm.list

exit 0
