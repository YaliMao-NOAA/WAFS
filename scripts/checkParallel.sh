#!/bin/bash

module load prod_envir
module load prod_util

COMROOT=/lfs/h1/ops/para/com
DATA=/lfs/h2/emc/ptmp/$(whoami)
cd $DATA

run='dafs'

PDY=$( $NDATE -24 )
PDY=${PDY:0:8}

mailto="yali.mao@noaa.gov"
subject="Error reports of parallel run"

if [[ "$run" == 'dafs' ]] ; then
    ver='v1.0'
    COMIN="$COMROOT/$run/$ver/$run.$PDY"
    COMINwmo="$COMIN/wmo"
    for (( icyc=0 ; icyc<=23 ; icyc++ )) ; do
	cyc=$(printf "%02d" $((10#$icyc)))
	ngtg=$( ls $COMIN/*t${cyc}z*gtg* | wc -l )
	nifi=$( ls $COMIN/*t${cyc}z*ifi* | wc -l )
	if [[ $ngtg != 57 ]] ; then
	    echo "DAFS GTG is not completed at t${cyc}z on $PDY" >> $run.parallelcheck.$PDY
	fi
	if [[ $(( icyc / 3 * 3 )) == $icyc ]] ; then
	    if [[ $nifi != 90 ]] ; then
		echo "DAFS IFI is not completed at t${cyc}z on $PDY, with AK" >> $run.parallelcheck.$PDY
	    fi
	else
	    if [[ $nifi != 54 ]] ; then
		echo "DAFS IFI is not completed at t${cyc}z on $PDY, no AK" >> $run.parallelcheck.$PDY
            fi
	fi
    done
    if [[ -f  $run.parallelcheck.$PDY ]] ; then
	echo check data at $COMIN >> $run.parallelcheck.$PDY
	cat $run.parallelcheck.$PDY | mail -s "$subject of $run on $PDY" $mailto
    fi

fi
