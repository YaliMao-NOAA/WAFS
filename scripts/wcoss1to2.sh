#!/bin/sh

#BSUB -oo /gpfs/dell3/ptmp/Yali.Mao/transfer.wcoss2.o%J
#BSUB -eo /gpfs/dell3/ptmp/Yali.Mao/transfer.wcoss2.o%J
#BSUB -J data_transfer
#BSUB -W 02:50
#BSUB -q dev_transfer
#BSUB -P GFS-DEV
#BSUB -R affinity[core(1)]
#BSUB -M 1024

#scp PATH1/FILE1 yali.mao@ddxfer04.wcoss2.ncep.noaa.gov:PATH2/FILE2
#scp cp_icesev.sh yali.mao@ddxfer04.wcoss2.ncep.noaa.gov:/lfs/h2/emc/vpppg/noscrub/yali.mao/git/.
mkdir -p /gpfs/dell3/ptmp/Yali.Mao/wafs_dwn2023
cd /gpfs/dell3/ptmp/Yali.Mao/wafs_dwn2023
#scp yali.mao@cdxfer04.wcoss2.ncep.noaa.gov:/lfs/h2/emc/vpppg/noscrub/yali.mao/wafs_dwn2023/com/gfs/v16.2/gfs.20220526/06/atmos/gfs.t06z.wafs_0p25_unblended.f*.grib2 .
#scp yali.mao@cdxfer04.wcoss2.ncep.noaa.gov:/lfs/h2/emc/vpppg/noscrub/yali.mao/dcom/20220526/wgrbbul/ukmet_wafs/* .
scp /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/scripts/wcoss1to2.sh yali.mao@cdxfer04.wcoss2.ncep.noaa.gov:/lfs/h2/emc/vpppg/noscrub/yali.mao/git/save/scripts/.
