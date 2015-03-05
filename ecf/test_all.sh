#!/bin/ksh

. /u/Binbin.Zhou/.kshrc

dev=`cat /etc/dev`
if [ $dev = 'gyre' ] ; then
exit
fi


bsub </u/Binbin.Zhou/work/grid2grid/verf_g2g.v3.0.0/ecf/jverf_grid2grid_cloud_00.ecf
bsub < /u/Binbin.Zhou/work/grid2grid/verf_g2g.v3.0.0/ecf/jverf_grid2grid_etop_00.ecf  
bsub < /u/Binbin.Zhou/work/grid2grid/verf_g2g.v3.0.0/ecf/jverf_grid2grid_reflectivity_00.ecf  
bsub < /u/Binbin.Zhou/work/grid2grid/verf_g2g.v3.0.0/ecf/jverf_grid2grid_urma_00.ecf
bsub < /u/Binbin.Zhou/work/grid2grid/verf_g2g.v3.0.0/ecf/jverf_grid2grid_firewx_00.ecf
bsub < /u/Binbin.Zhou/work/grid2grid/verf_g2g.v3.0.0/ecf/jverf_grid2grid_ens_00.ecf
echo "Test begins" 

exit

sleep 10800
cp /ptmpp1/Binbin.Zhou/g2g/RFC2/com/verf/dev/vsdb/grid2grid/cloud/* /meso/noscrub/Binbin.Zhou/g2g/vsdb/cloud/vsdb
cp /ptmpp1/Binbin.Zhou/g2g/RFC2/com/verf/dev/vsdb/grid2grid/etop/* /meso/noscrub/Binbin.Zhou/g2g/vsdb/etop/vsdb
cp /ptmpp1/Binbin.Zhou/g2g/RFC2/com/verf/dev/vsdb/grid2grid/reflt/* /meso/noscrub/Binbin.Zhou/g2g/vsdb/reflt/vsdb
cp /ptmpp1/Binbin.Zhou/g2g/RFC2/com/verf/dev/vsdb/grid2grid/urma/* /meso/noscrub/Binbin.Zhou/g2g/vsdb/urma/vsdb
cp /ptmpp1/Binbin.Zhou/g2g/RFC2/com/verf/dev/vsdb/grid2grid/firewx/* /meso/noscrub/Binbin.Zhou/g2g/vsdb/firewx/vsdb
cp /ptmpp1/Binbin.Zhou/g2g/RFC2/com/verf/dev/vsdb/grid2grid/ens/* /meso/noscrub/Binbin.Zhou/g2g/vsdb/ens/vsdb

