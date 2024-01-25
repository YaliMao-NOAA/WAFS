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

date

RUN=${RUN:-"para"}

plotdir=$COMOUT

remoteTar=/home/people/emc/www/htdocs/users/verification/aviation/wafs/para/tar_files

rsync -ahr -P $plotdir/*.tar ymao@emcrzdm.ncep.noaa.gov:$remoteTar/.

remoteScript=/home/people/emc/www/htdocs/users/verification/aviation/wafs/scripts
ssh ymao@emcrzdm.ncep.noaa.gov "sh $remoteScript/untar_images_atmos.sh $RUN"

date


