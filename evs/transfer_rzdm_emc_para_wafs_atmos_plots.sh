#PBS -N transfer_rzdm_emc_para_global_det_wave_plots
#PBS -o /u/mallory.row/cron_jobs/logs/log_transfer_rzdm_emc_para_global_det_wave_plots.out
#PBS -e /u/mallory.row/cron_jobs/logs/log_transfer_rzdm_emc_para_global_det_wave_plots.out
#PBS -S /bin/bash
#PBS -q dev_transfer
#PBS -A VERF-DEV
#PBS -l walltime=03:00:00
#PBS -l select=1:ncpus=1:mem=5GB
#PBS -l debug=true
#PBS -V

export PDYm1=$(date -d "24 hours ago" '+%Y%m%d')
rsync -ahr -P /lfs/h2/emc/ptmp/emc.vpppg/evs/v1.0/plots/global_det/wave.${PDYm1}/*.tar mrow@emcrzdm.ncep.noaa.gov:/home/people/emc/www/htdocs/users/verification/global/gfs/para/wave/tar_files/.
