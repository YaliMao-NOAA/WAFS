#!/bin/sh
set -xeua
set -A pdy 
dd=7;while [ $((dd=10#$dd+1)) -le 8 ] ; do [ ${#dd} -lt 2 ] && dd=0$dd
	PDY=200310$dd
	$g01/fnl/faa_qsub_daily.sh 
done
