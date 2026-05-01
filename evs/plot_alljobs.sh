#!/bin/sh

# If long_range is yes, plot the last day of the last month back to 5 years ago;
# otherwise plot 90 or 31 days.

set -xa

extract_prepare_data="yes" # yes / no, embedded in [ $long_range = "yes"  ] 

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
if [ $extract_prepare_data = "yes" ] ; then
    rm -fr $DATAplot;
else
    cd $DATAplot
    rm -r plot* tar* working*
fi
mkdir -p $DATAplot; cd $DATAplot

SCRIPTplot=$HOMEsave/evs

# Get  the last day of the last month
VDATE=`$NDATE | cut -c 1-6`0100
export VDATE=`$NDATE -24 $VDATE | cut -c 1-8`

###### for one year plotting
###### export VDATE=20251231

######################################
# Step 1: if long_range is yes, plot the last day of the last month back to 5 years ago
######################################
if [ $long_range = "yes"  ] ; then
    #==========================================
    # Job 1: prepare data
    #==========================================
    # VDAY1=20171201
    export VDAY1=`$NDATE -$((5*365*24)) ${VDATE}00 | cut -c 1-6`01
###### for one year plotting
######    export VDAY1=`$NDATE -$((365*24)) ${VDATE}00 | cut -c 1-6`31
######    export VDAY1=20250101
    export DATAevs=$DATAplot/data
    
    if [ $extract_prepare_data = "yes" ] ; then
	#PBS -o /lfs/h2/emc/ptmp/yali.mao/evs_plot/extract_evs_data.log
	jobid_data=$(qsub $SCRIPTplot/plot_extract_evs_data.sh)
    fi

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
    export VAR_NAMES_GCIP=ICESEV
    var=$VAR_NAMES_GCIP
    export COMOUT=$DATAplot/tar_long.$var
    export DATA=$DATAplot/working_long.$var
    logfile=$DATAplot/plotting.log.$var
    jobname=jevs_plot$var

    if [ $extract_prepare_data = "yes" ] ; then
	jobid=$(qsub -W depend=afterok:$jobid_data -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=01:30:00 -l place=shared,select=2:ncpus=110:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)
    else
	jobid=$(qsub -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=01:30:00 -l place=shared,select=2:ncpus=110:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)
    fi

    export OBSERVATIONS=GFS
    for var in TMP WIND WIND80 ; do # TMP WIND WIND80 UGRD_VGRD
	export VAR_NAMES_GFS=$var
	export COMOUT=$DATAplot/tar_long.$var
	export DATA=$DATAplot/working_long.$var
	logfile=$DATAplot/plotting.log.$var
	jobname=jevs_plot$var
	if [ $extract_prepare_data = "yes" ] ; then
	    jobid=$(qsub -W depend=afterok:$jobid_data -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=03:30:00 -l place=shared,select=2:ncpus=120:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)
	else
	    jobid=$(qsub -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=03:30:00 -l place=shared,select=2:ncpus=120:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)
	fi
	#jobid=${jobid//.*/}
	jobids="$jobid:$jobids"
    done
    jobids=${jobids::-1}
fi

######################################
# Step 2: Plot anyway for 90
######################################
# In EVS workflow: 90 days
export COMIN=
export VDATE=
export COMOUT=$DATAplot/tar_short
export VAR_NAMES_GCIP=
export VAR_NAMES_GFS=
export OBSERVATIONS="GCIP GFS"
logfile=$DATAplot/plotting.log.short
jobname=jevs_plot.short
export DAYS_LIST="90"
export DATA=$DATAplot/working_short.$DAYS_LIST
if [ -z $jobids ] ; then
    jobid1=$(qsub -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=01:00:00 -l place=shared,select=1:ncpus=60:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)
else
    jobid1=$(qsub -W depend=afterok:$jobids -V -q dev -A VERF-DEV -j oe -o $logfile -l walltime=01:00:00 -l place=shared,select=1:ncpus=60:mem=200GB -N $jobname $SCRIPTplot/plot_plotting.sh)
fi

###### for one year plotting
###### exit

######################################
# Step 3: transfer to RZDM (rely on job 2)
######################################
export RUN='prod'
export COMOUT=$DATAplot
qsub -W depend=afterok:$jobid1 $SCRIPTplot/plot_transfer2rzdm.sh
