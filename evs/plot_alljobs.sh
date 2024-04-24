#!/bin/sh

# If long_range is yes, plot the last day of the last month back to 5 years ago;
# otherwise plot 90 or 31 days.

set -xa

if [ -z $MACHINE ] ; then
    . ~/envir_setting.sh
fi

# If run on WCOSS2, only run on dev machine
if [ $MACHINE_DEV = 'no' ] ; then
    echo "This is not a dev $MACHINE machine, quit job"
    exit 1
fi
date

DATAplot=/lfs/h2/emc/ptmp/yali.mao/evs_plot
rm -fr $DATAplot; mkdir -p $DATAplot; cd $DATAplot

SCRIPTplot=$HOMEsave/evs

# Get  the last day of the last month
VDATE=`$NDATE | cut -c 1-6`0100
export VDATE=`$NDATE -24 $VDATE | cut -c 1-8`

######################################
# Step 1: if long_range is yes, plot the last day of the last month back to 5 years ago
######################################
if [ $long_range = "yes"  ] ; then
    #==========================================
    # Job 1: prepare data
    #==========================================
    # VDAY1=20171201
    export VDAY1=`$NDATE -$((5*365*24)) ${VDATE}00 | cut -c 1-6`01

    export DATAevs=$DATAplot/data
    jobid_data=$(qsub $SCRIPTplot/plot_extract_evs_data.sh)

    #==========================================
    # job 2: plot (rely on job 1)
    #==========================================
    #PBS -N jevs_wafs_plots
    #PBS -o /lfs/h2/emc/ptmp/yali.mao/evs_plot/plotting.log
    #PBS -e /lfs/h2/emc/ptmp/yali.mao/evs_plot/plotting.log
    #PBS -S /bin/bash
    #PBS -q dev
    #PBS -A VERF-DEV
    #PBS -l walltime=05:00:00
    #PBS -l place=shared,select=1:ncpus=70:mem=200GB
    #PBS -l debug=true
    #PBS -V
    export COMIN=$DATAevs
    export DAYS_LIST=$(( ($(date +%s -d $VDATE) - $(date +%s -d $VDAY1) )/(60*60*24) ))

    export OBSERVATIONS=GCIP
    export COMOUT=$DATAplot/tar_long.gcip
    export DATA=$DATAplot/working_long.gcip
    logfile=$DATAplot/plotting.log.gcip
    jobname=jevs_plotgcip
    jobid=$(qsub -W depend=afterok:$jobid_data -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=00:30:00 -l place=shared,select=2:ncpus=110:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)

    export OBSERVATIONS=GFS
    for var in TMP WIND WIND80 ; do # TMP WIND WIND80 WDIR
	export COMOUT=$DATAplot/tar_long.$var
	export DATA=$DATAplot/working_long.$var
	export VAR_NAME_GFS=$var
	logfile=$DATAplot/plotting.log.$var
	jobname=jevs_plot$var
	jobid=$(qsub -W depend=afterok:$jobid_data -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=03:00:00 -l place=shared,select=1:ncpus=60:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)
	#jobid=${jobid//.*/}
	jobids="$jobid:$jobids"
    done
    jobids=${jobids::-1}
fi

######################################
# Step 2: Plot anyway for 90 and 31 days
######################################
# In EVS workflow: 90 and 31 days
# jobs/JEVS_WAFS_ATMOS_PLOTS: export EVSINstat=$COMIN/stats/$COMPONENT
# in ush/wafs/evs_wafs_atmos_plots.sh: find $EVSINstat -name wafs.$day
export COMIN=/lfs/h1/ops/*/com/evs/*
export DAYS_LIST="90 31"
export COMOUT=$DATAplot/tar_short
export DATA=$DATAplot/working_short
export VAR_NAME_GFS=
logfile=$DATAplot/plotting.log.short
jobname=jevs_plot.short
if [ -z $jobids ] ; then
    jobid=$(qsub -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=01:00:00 -l place=shared,select=1:ncpus=60:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)
else
    jobid=$(qsub -W depend=afterok:$jobids -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=01:00:00 -l place=shared,select=1:ncpus=60:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)
fi

######################################
# Step 3: transfer to RZDM (rely on job 2)
######################################
export RUN='prod'
export COMROOT=$DATAplot
qsub -W depend=afterok:$jobid $SCRIPTplot/plot_transfer2rzdm.sh
