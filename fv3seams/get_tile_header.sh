#!/bin/sh
module load netcdf

fixdir=/lfs/h2/emc/global/save/emc.global/FIX/fix_nco_gfsv16/fix_fv3

subdirs="C768 C384"

for subdir in $subdirs ; do
    for ntile in 1 2 3 4 5 6 ; do
	ncdump $fixdir/$subdir/${subdir}_grid.tile$ntile.nc > ${subdir}_grid.tile$ntile.txt
    done
done
