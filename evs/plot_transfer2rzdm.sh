#PBS -N transfer_EVS_wafs_plots_to_rzdm
#PBS -o /lfs/h2/emc/ptmp/yali.mao/evs_plot/plot_transfer2rzdm.log
#PBS -e /lfs/h2/emc/ptmp/yali.mao/evs_plot/plot_transfer2rzdm.log
#PBS -S /bin/bash
#PBS -q dev_transfer
#PBS -A VERF-DEV
#PBS -l walltime=00:30:00
#PBS -l select=1:ncpus=1:mem=5GB
#PBS -l debug=true
#PBS -V
set -x
date

RUN=${RUN:-"para"}

plotdir=$COMROOT

remoteTar=/home/people/emc/www/htdocs/users/verification/aviation/wafs/para/tar_files

cd $plotdir
files=`ls tar*/*tar`
n=0
for file in $files ; do
    rsync -ahr -P $file  ymao@emcrzdm.ncep.noaa.gov:$remoteTar/$n.${file##*/}
    n=$(( n + 1))
done

remoteScript=/home/people/emc/www/htdocs/users/verification/aviation/wafs/scripts
ssh ymao@emcrzdm.ncep.noaa.gov "sh $remoteScript/untar_images_atmos.sh $RUN"

date


