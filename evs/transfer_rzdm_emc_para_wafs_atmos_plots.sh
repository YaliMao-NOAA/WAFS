#PBS -N transfer_EVS_wafs_plots_to_rzdm
#PBS -o /lfs/h2/emc/ptmp/yali.mao/log_transfer_EVS_wafs_plots_to_rzdm.out
#PBS -e /lfs/h2/emc/ptmp/yali.mao/log_transfer_EVS_wafs_plots_to_rzdm.out
#PBS -S /bin/bash
#PBS -q dev_transfer
#PBS -A VERF-DEV
#PBS -l walltime=00:30:00
#PBS -l select=1:ncpus=1:mem=5GB
#PBS -l debug=true
#PBS -V

if [ -z $MACHINE ] ; then
    . ~/envir_setting.sh
fi

RUN=${RUN:-"para"}
PDY=${PDY:-`$NDATE | cut -c1-8`}

plotDir=/lfs/h2/emc/vpppg/noscrub/yali.mao/evs/v1.0/plots/wafs
remoteDir=/home/people/emc/www/htdocs/users/verification/aviation/wafs/para/tar_files

rsync -ahr -P $plotDir/atmos.$PDY/*.tar ymao@emcrzdm.ncep.noaa.gov:$remoteDir/.


remoteUntarScript=/home/people/emc/www/htdocs/users/verification/aviation/wafs/scripts



