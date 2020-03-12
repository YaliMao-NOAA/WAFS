export opt1=' -set_grib_type same -new_grid_winds earth '
export opt21=' -new_grid_interpolation bilinear  -if '
export opt22=":(LAND|CSNOW|CRAIN|CFRZR|CICEP|ICSEV):"
export opt23=' -new_grid_interpolation neighbor -fi '
export opt24=' -set_bitmap 1 -set_grib_max_bits 16 -if '
export opt25=":(APCP|ACPCP|PRATE|CPRAT):"
export opt26=' -set_grib_max_bits 25 -fi -if '
export opt27=":(APCP|ACPCP|PRATE|CPRAT|DZDT):"
export opt28=' -new_grid_interpolation budget -fi '
export grid0p25="latlon 0:1440:0.25 90:721:-0.25"
export grid0p125="latlon 0:2880:0.25 90:1441:-0.125"


export RUN=gfs
export CDATE=2019083012
export PDY=`echo $CDATE | cut -c1-8`
export cyc=`echo $CDATE | cut -c9-10`
export cycle=t${cyc}z

export COMOUT=/scratch2/NCEPDEV/stmp3/$LOGNAME/com2/gfs/test/${RUN}.$PDY/${cyc}
set -xa
export DATA=/scratch2/NCEPDEV/stmp3/$LOGNAME/tmp
rm -rf $DATA
mkdir $DATA
cd $DATA

post_times=030
export rawfile=/scratch4/NCEPDEV/stmp3/Yali.Mao/com2/gfs/test/gfs.20190830/12/gfs.t${cyc}z.master.grb2f${post_times}
date


nproc=30
ncount=`$WGRIB2 $rawfile |wc -l`
inv=`expr $ncount / $nproc`

iproc=0
end=0
# To speed up grid converting process, seperate large input file 
# into $nproc individual small files group by record order
while [ $iproc -le $nproc ] ; do # iproc starts at 0, there might be nproc+1 processors
  start=`expr ${end} + 1`
  end=`expr ${start} + ${inv} - 1`
  if [[ $end -ge $ncount ]] ;then
      end=$ncount
  fi

  # if final record of each piece is ugrd, add vgrd
  # interpolate u and v together                       
  $WGRIB2 -d $end $rawfile |egrep -i "ugrd|ustm|uflx"
  rc=$?
  if [[ $rc -eq 0 ]] ; then
      end=`expr ${end} + 1`
  fi
  echo "$iproc  sh $HOMEsave/scripts/filter.converter.sh $rawfile $iproc $start $end" >> $DATA/poescript

  iproc=`expr $iproc + 1`

  # Has reached the end of records, exists the loop
  if [ $end -eq $ncount ]; then
      nproc=$iproc # The acutal number of processors are used
      break
  fi

done

chmod 775 $DATA/poescript

sbatch -A ovp  -n $nproc --wrap "srun -l --multi-prog $DATA/poescript"


#Wait till all jobs are done
sleepmax=600
inv=5
sleeptime=0
ndone=`grep ": filter converter done" slurm*out | wc -l`
while [ $ndone -lt $nproc ] ; do
  sleep $inv
  ndone=`grep ": filter converter done" slurm*out | wc -l`
  sleeptime=$(( sleeptime + inv ))
  if [[ $sleeptime -gt $sleepmax ]] ; then
      echo "ERROR!!! Fail to generate individual files "
      exit
  fi
done


iproc=0
# Combine the converted individual small files to a complete file
rm $COMOUT/gfs.t${cyc}z.0p25.grb2f${post_times}
rm $COMOUT/gfs.t${cyc}z.0p125.grb2f${post_times}
while [ $iproc -lt $nproc ]; do
  cat tmp.0p25_$iproc >> $COMOUT/gfs.t${cyc}z.0p25.grb2f${post_times}
  cat tmp.0p125_$iproc >> $COMOUT/gfs.t${cyc}z.0p125.grb2f${post_times}
  iproc=`expr $iproc + 1`
done

#module load mvapich2

date
