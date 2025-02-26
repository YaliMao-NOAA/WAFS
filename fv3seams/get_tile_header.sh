#!/bin/sh
module load netcdf
set -x

fixdirC384=/lfs/h2/emc/global/save/emc.global/FIX/fix_nco_gfsv16/fix_fv3
fixdirC768=$fixdirC384
fixdirC1152=/lfs/h2/emc/global/noscrub/emc.global/FIX/fix/orog/20240917

subdirs="C1152 C768 C384"

for subdir in $subdirs ; do
    fixdir="fixdir$subdir"
    for ntile in 1 2 3 4 5 6 ; do
	ncdump ${!fixdir}/$subdir/${subdir}_grid.tile$ntile.nc > ${subdir}_grid.tile$ntile.txt
    done
done
