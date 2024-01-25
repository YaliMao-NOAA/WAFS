#!/bin/sh

# If VDAY1 is specified, plot till the last day of the last month;
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
export COMOUT=$DATAplot/tar

SCRIPTplot=$HOMEsave/evs

######################################
# Step 1: if VDAY1 is specified usually when verification data is over more than 90 days,
######################################
if [ ! -z $VDAY1 ] ; then
    #==========================================
    # Job 1: prepare data
    #==========================================
    # VDAY1=20171201
    # Get  the last day of the last month
    VDAY2=`$NDATE | cut -c 1-6`0100
    export VDAY2=`$NDATE -24 $VDAY2 | cut -c 1-8`

    export DATAevs=$DATAplot/data
    jobid=$(qsub $SCRIPTplot/plot_extract_evs_data.sh)

    #==========================================
    # job 2: plot (rely on job 1)
    #==========================================
    export COMIN=$DATAevs
    export DATA=$DATAplot/working_long
    export DAYS_LIST=$(( ($(date +%s -d $VDAY2) - $(date +%s -d $VDAY1) )/(60*60*24) ))
    jobid=$(qsub -W depend=afterok:$jobid $SCRIPTplot/plot_plotting.sh)
fi

######################################
# Step 2: Plot anyway for 90 and 31 days
######################################
# In EVS workflow: 90 and 31 days
# jobs/JEVS_WAFS_ATMOS_PLOTS: export EVSINstat=$COMIN/stats/$COMPONENT
# in ush/wafs/evs_wafs_atmos_plots.sh: find $EVSINstat -name wafs.$day
export COMIN=/lfs/h1/ops/*/com/evs/*
export DATA=$DATAplot/working_short
export DAYS_LIST="90 31"
if [ -z $jobid ] ; then
    jobid=$(qsub $SCRIPTplot/plot_plotting.sh)
else
    jobid=$(qsub -W depend=afterok:$jobid $SCRIPTplot/plot_plotting.sh)
fi

######################################
# Step 3: transfer to RZDM (rely on job 2)
######################################
export RUN='para'
qsub -W depend=afterok:$jobid $SCRIPTplot/plot_transfer2rzdm.sh
