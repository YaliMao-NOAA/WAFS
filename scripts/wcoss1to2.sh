#!/bin/sh

#BSUB -oo /gpfs/dell3/ptmp/Yali.Mao/transfer.wcoss2.o%J
#BSUB -eo /gpfs/dell3/ptmp/Yali.Mao/transfer.wcoss2.o%J
#BSUB -J data_transfer
#BSUB -W 02:50
#BSUB -q dev_transfer
#BSUB -P GFS-DEV
#BSUB -R affinity[core(1)]
#BSUB -M 1024

#scp PATH1/FILE1 Yali.Mao@ddxfer04.wcoss2.ncep.noaa.gov:PATH2/FILE2
scp cp_icesev.sh Yali.Mao@ddxfer04.wcoss2.ncep.noaa.gov:/lfs/h2/emc/vpppg/noscrub/Yali.Mao/git/.

