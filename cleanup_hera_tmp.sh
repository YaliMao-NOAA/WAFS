#!/bin/sh
# Clean temporary folder, stmp, on Theia, when files/folders are 7 days old

set -xa

TMP=/scratch2/NCEPDEV/stmp3/Yali.Mao

# gfs_prod_rzdm_prod: WAFS grib2 to RZDM server
# Subfolders sorted by dates
# (Need to manually clean up)

# wafs.vrfy.com.twindonly: to make up u/v/t verification
# (Can be delete after the make up is done)

# wafs.vrfy.com:  data for WAFS verification
# 1 subfolder  with newer date: Extract ICIP ICSEV from master file and archive to HPSS
# 2 subfolders with older date: Extract the incoming data from HPSS and re-organize the data
# (Automatically delete data to free disk storage when a new run begins)

# wafs.vrfy_prod.prod_grib2: regridded WAFS verfication data
# Need to keep up to 3 days of data to do continuous verification
# Subfolders sorted by dates
# (Need to manually clean up)

# wafs.vrfy_prod.prod_vsdb: temporary saved vsdb verfication data for each cycle
# One subfoder wafs/ and subfolder is not sorted
# (Need to manually clean up)

# wafs.vrfy_prod.prod_working: working folder of WAFS verification
# Saved just for debugging
# Not deleted in the script to void deleting others when running makeup verification
# Subfolders sorted by dates
# (Need to manually clean up)

# gfs_prod_rzdm_plotting_00 (or 06/12/18): plottings of WAFS icing and turbulence
# (Automatically delete data to free disk storage when a new run begins)

folders="gfs_prod_rzdm_prod \
         wafs.vrfy.com \
         wafs.vrfy_prod.prod_grib2 \
         wafs.vrfy_prod.prod_vsdb/wafs \
         wafs.vrfy_prod.prod_working \
         working_post \
         met_working \
         logs_post"

for dir in $folders ; do
  files=`find $TMP/$dir -mtime +7`
  rm -rf $files
done

files=`find $TMP/vsdb.prod.prod.* -mtime +3`
rm $files

files=`find $TMP/run_gfs_post.o* -mtime +3`
rm $files

