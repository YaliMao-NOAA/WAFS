#!/bin/bash
set -x

PDY=$1
cyc=$2
fhr=$3
COMINgefs="/lfs/h1/ops/prod/com/gefs/v12.3/gefs.$PDY/$cyc/atmos/sfcsig"
COMOUT=/lfs/h2/emc/ptmp/yali.mao/gefs_nemsio/com/gefs/v12.3/gefs.$PDY/$cyc/atmos/sfcsig
mkdir -p $COMOUT

for (( i=0; i<=30; i++ )); do
    memID=$(printf "%02d" $i)
    if [[ $memID == '00' ]] ; then
        export member=gec$memID
    else
        export member=gep$memID
    fi

    LOGFILE="${COMINgefs}/${member}.t${cyc}z.logf${fhr}.nemsio"
    SLEEP_LOOP_MAX=360
    SLEEP_INT=5
    ic=1
    while [ $ic -le $SLEEP_LOOP_MAX ]; do
        if [ -f $LOGFILE ]; then
            break
        else
            ic=$(( $ic + 1 ))
            sleep $SLEEP_INT
        fi
        if [ $ic -eq $SLEEP_LOOP_MAX ]; then
            echo FATAL ERROR: $LOGFILE not exists
            export err=9
            exit $err
        fi # [ $ic -eq $SLEEP_LOOP_MAX ]                                                                                                                                                               
    done # [ $ic -le $SLEEP_LOOP_MAX ]

    cp ${COMINgefs}/${member}.t${cyc}z.logf${fhr}.nemsio $COMOUT/.
    cp ${COMINgefs}/${member}.t${cyc}z.atmf${fhr}.nemsio $COMOUT/.
    cp ${COMINgefs}/${member}.t${cyc}z.sfcf${fhr}.nemsio $COMOUT/.
done
