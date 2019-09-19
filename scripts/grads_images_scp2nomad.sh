#!/bin/ksh

#########################################
# transfer vsdb data to NOMAD           #
# for crontab, daily                    #
#########################################

sourceDir="/ptmpp1/Yali.Mao/nomad_www"
targetServer="yali.mao@emc-ls-nomad7"
targetDir="/var/www/htdocs/WAFS/EMC_VSDB_verif_demo/display"

# keep the data for the day before yesterday

# remote delete the data before the day before yesterday 
# (more than 2160 minutes / more than 1 and a half days)
ssh $targetServer "find $targetDir/imgs/ -mmin +2160 -delete" 2>/dev/null

scp -r $sourceDir/imgs $targetServer:$targetDir/.

exit
