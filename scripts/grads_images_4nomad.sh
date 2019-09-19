#!/bin/ksh
. /u/Yali.Mao/.kshrc

#######################################################
# create FIP images and load up to nomad server, using grads
#######################################################

# usage: ksh grads_images_4nomad.sh [blnd us uk gfip fip rap nam] 

set -x

#######################################################
# run script only on develop machine
#######################################################
developMachine=`cat /etc/dev` # tide / gyre
thisMachine=`hostname` # # t1... / g1...
# The first letters of $developMachine and $thisMachine must match; otherwise exit
if [ `echo $developMachine | cut -c 1-1` != `echo $thisMachine | cut -c 1-1` ] ; then
  exit
fi

# to save time, $models don't include max, which will be specified inside the loop
# inputs: BLND US UK GFIP FIP RAP GFIS NAM
#
# inputs and all others match onevent.js on nomad
# all in lower cases

PATH=$PATH:/usr/bin:/nwprod/util/exec/:/usrx/local/GrADS/2.0.2/bin/:/usrx/local/GrADS/2.0.2/lib/:/global/save/Yali.Mao/grads/
export GADDIR=/usrx/local/GrADS/2.0.2/lib

rm -r /ptmpp1/Yali.Mao/nomad_www/*
mkdir -p /ptmpp1/Yali.Mao/nomad_www
cd /ptmpp1/Yali.Mao/nomad_www
mkdir -p /ptmpp1/Yali.Mao/nomad_www/imgs
rm -r /ptmpp1/Yali.Mao/nomad_www/imgs/*

## 3 kinds of vertical levels
# flight levels,   the input
set -A flevels   fl030 fl060 fl100 fl140 fl180 fl240
# pressure levels, matching flight level
set -A plevels   900   800   700   600   500   400
# hybrid levels,   matching flight levels
set -A hlevels   914   1828  3048  4267  5486  7315
# set plevel matching flheight

models=$@
typeset -l models

set -A modelModels
# icing potential display name in grads
set -A potentials

# create new images for yesterday
dates=`ndate -24 | cut -c1-8`
# The web server keeps the data of the day before yesterday and remove the data before 

cycles="00 06 12 18"

for modelarg in $models ; do

  #################################################
  # set appropriate flight levels and forecast hours
  #################################################

  fhours="06 12 18 24 30 36"
  flights="fl030 fl060 fl100 fl140 fl180 fl240"

  if [ $modelarg = "blnd"  -o $modelarg = "us" -o $modelarg = "uk" ] ; then
      # no fl030
      flights="fl060 fl100 fl140 fl180 fl240"
  elif [ $modelarg = "rap" ] ; then
      fhours="06 09 12 15 18"
  elif [ $modelarg = "fip" ] ; then
      fhours="06 09 12"
  fi

  unset modelModels
  unset potentials

  for date in $dates ; do
    for cycle in $cycles ; do
      for fhour in $fhours ; do

	#################################################
        # copy files and set appropriate icing field name
	# in grads control file
	#################################################

	# grbfile0 - global, will be set as "" if not existing.
	# grbfile1 - conus

	# modelModels[0], potentials[0] - for unique or mean values
	# modelModels[1], potentials[1] - for max values if existing

	grbfile0=global.$modelarg.t${cycle}z.f${fhour}
	grbfile1=conus.$modelarg.t${cycle}z.f${fhour}

	if [ $modelarg = "blnd" ] ; then 

	  modelModels[0]=blndmn
	  modelModels[1]=blndmax
	  potentials[0]=MEIPprs
	  potentials[1]=MAIPprs

	  # global
	  cnvgrib -g21 /com/gfs/prod/gfs.$date/WAFS_blended_${date}${cycle}f${fhour}.grib2 $grbfile0.tmp
          # BLND US UK: icing and turbulence on different vertical levels.
          # The contrl file created from grib2ctl.pl may not be correct.
          # So extract icing products only
	  #
	  # must use [[ ]] for wildcard matching
	  wgrib $grbfile0.tmp | grep "5=16[89]" | wgrib -i -grib $grbfile0.tmp -o $grbfile0
	  rm $grbfile0.tmp

	  # conus
	  copygb -g252 -i2,1 -x $grbfile0 $grbfile1

	elif [ $modelarg = "us" ] ; then

	  modelModels[0]=usmn
	  modelModels[1]=usmax
	  potentials[0]=MEIPprs
	  potentials[1]=MAIPprs

	  # global
	  cp /com/gfs/prod/gfs.$date/gfs.t${cycle}z.wafs_grb45f${fhour} $grbfile0.tmp
          # extract icing products only
	  wgrib $grbfile0.tmp | grep "5=16[89]" | wgrib -i -grib $grbfile0.tmp -o $grbfile0
	  $grbfile0.tmp

	  # conus
	  copygb -g252 -i2,1 -x $grbfile0 $grbfile1

	elif [ $modelarg = 'uk' ] ; then

	  modelModels[0]=ukmn
	  modelModels[1]=ukmax
	  potentials[0]=NBDSFprs
	  potentials[1]=NDDSFprs

	  # global
	  cnvgrib -g21 /dcom/us007003/$date/wgrbbul/ukmet_wafs/EGRR_WAFS_unblended_${date}_${cycle}z_t${fhour}.grib2 $grbfile0.tmp
          # extract icing products only
	  wgrib $grbfile0.tmp | grep "5=16[89]" | wgrib -i -grib $grbfile0.tmp -o $grbfile0
	  $grbfile0.tmp

	  # conus
	  copygb -g252 -i2,1 -x $grbfile0 $grbfile1

	elif [ $modelarg = 'gfip' ] ; then

	  modelModels[0]=gfip
	  potentials[0]=MEIPprs

	  # global
	  cp /ptmpp1/Yali.Mao/gfip.$date/gfs.t${cycle}z.master.grbf$fhour $grbfile0

	  # conus
	  cp /ptmpp1/Yali.Mao/gfip.$date/gfs.t${cycle}z.gfip.grbf$fhour $grbfile1

	elif [ $modelarg = 'fip' ] ; then

	  grbfile0=""

	  modelModels[0]=fip
	  # convert from probability to potential
          (( rate = 0.84-0.033*$fhour ))
	  potentials[0]=ICPRBhml/$rate

	  # extract/re-organize FIP data
	  head=YAW
          # [BCDGJM] stands for forecast hour
          # B:1  C:2  D:3  G:6  J:9  M:12
	  if [ $fhour = '06' ] ; then
	      cfhour=G
	  elif [ $fhour = '09' ] ; then
	      cfhour=J
	  elif [ $fhour = '12' ] ; then
	      cfhour=M
	  fi
	  for lvl in 39 50 60 70 81 90 ; do
            infile=/dcom/us007003/$date/wgrbbul/adds_fip/${head}$cfhour${lvl}.grb
	    search=`echo ${date} | cut -c 3-8`${cycle}  
	    wgrib $infile |grep "d=${search}:" | wgrib -i -grib $infile -o x.$lvl
	    cat x.$lvl >> $grbfile1
	  done 
	  rm -f x.*

	elif [ $modelarg = 'rap' ] ; then

	  grbfile0=""

	  modelModels[0]=rap
	  potentials[0]=MEIPhml

	  cp /ptmpp1/Yali.Mao/fipVf/$modelarg/$modelarg.$date/$modelarg.t${cycle}z.fip252.grbf$fhour $grbfile1

	elif [ $modelarg = 'nam' ] ; then

	  grbfile0=""

	  modelModels[0]=nam
	  potentials[0]=MEIPhml

	  cp /ptmpp1/Yali.Mao/fipVf/$modelarg/$modelarg.$date/$modelarg.t${cycle}z.fip221.grbf$fhour $grbfile1

	fi


        #################################################
	# loop over global and conus
        #################################################
	for grbfile in $grbfile0 $grbfile1 ; do

          domain=`echo $grbfile | cut -d '.' -f1`

	  ith=0
	  while [[ $ith < ${#modelModels[@]} ]] ; do
            model=${modelModels[${ith}]};
            potential=${potentials[${ith}]};
	    

	    (( ith = ith + 1 ))
	   echo $ith 

            #################################################
	    # create grads control file
	    #################################################

	    grib2ctl.pl -verf $grbfile > ${grbfile}.ctl
	    gribmap -i ${grbfile}.ctl

	    #################################################
            # set plevel matching flheight
            #################################################
	    for flevel in $flights ; do

	      i=0
	      while [[ $i < ${#flevels[@]} ]] ; do 
	        if [ $flevel = ${flevels[${i}]} ] ; then
	          # if [ $model = 'gfip' -o $model = 'fip' -o $model = 'nam' -o $model = 'rap' ] ; then
                  if [ $model = 'fip' -o $model = 'nam' -o $model = 'rap' ] ; then
 		    plevel=${hlevels[$i]}
		  else
		    plevel=${plevels[$i]}
		  fi
		  break
		fi
		(( i = i + 1 ))
	      done

              #################################################
	      ## start of the kernel part
	      #################################################

	      export outputfile=${domain}.${model}.${date}t${cycle}zf${fhour}.${flevel}.png
	      export grbfile
	      export plevel
	      export potential
	      export gradstitle="`echo $model | tr '[a-z]' '[A-Z]'` ice potential, `echo ${flevel} | tr '[a-z]' '[A-Z]'`, ${date}t${cycle}zf${fhour}"

	      echo $plevel $gradstitle

	      cat > plotgrads << EOF
'open ${grbfile}.ctl'
'set lev ${plevel}'

'/global/save/Yali.Mao/grads/rgbColors.gs'
'set clevs 0 0.1 0.2 0.3 0.4 0.5 0.6 0.7'
'd $potential'
'/global/save/Yali.Mao/grads/cbar'
'draw title $gradstitle'
'printim imgs/$outputfile png'

'quit'
EOF

	      grads -blc "run plotgrads"

	      ## end of kernel part

	    done
	  done
	done
      done
    done
  done
done

# transfer images to nomad server
ksh /global/save/Yali.Mao/scripts/grads_images_scp2nomad.sh


exit
