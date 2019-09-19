fhoursdefault="012 018 024 036"
DATA=/gpfs/hps/ptmp/Yali.Mao/test
mkdir -p $DATA
cd $DATA

COMROOT=/gpfs/dell1/nco/ops/com/gfs/para

HOST='ftp.rap.ucar.edu'
USER='anonymous'
PASSWD='yali.mao@noaa.gov'

===========repeat the following when needed================

fhours="012 018 024 036"
PDYs="20190428"
cycles="12 18"

for PDY in $PDYs ; do
for cyc in $cycles ; do
for fh in $fhours ; do
  COMIN=$COMROOT/gfs.$PDY/$cyc
  ln -s $COMIN/gfs.t${cyc}z.atmf$fh.nemsio gfs.t${cyc}z.atmf$fh.nemsio.$PDY
  ln -s $COMIN/gfs.t${cyc}z.sfcf$fh.nemsio gfs.t${cyc}z.sfcf$fh.nemsio.$PDY

  ftp -pn $HOST <<EOF
user $USER $PASSWD
passive
cd incoming/irap/gtg_fv3
bin
prompt
put gfs.t${cyc}z.atmf$fh.nemsio.$PDY
put gfs.t${cyc}z.sfcf$fh.nemsio.$PDY
bye
EOF

  echo "$PDY$cyc $fh">> nemsio.makeup
  scp nemsio.makeup ymao@emcrzdm:/home/ftp/emc/unaff/ymao/fv3_nemsio_list/.

done
done
done


===========repeat the following when needed================
fhours=$fhoursdefault

PDYs="20190429 20190430 20190501 20190502 20190503 20190504 20190505 20190506"
cycles="00 06 12 18"


for PDY in $PDYs ; do
for cyc in $cycles ; do
for fh in $fhours ; do
  COMIN=$COMROOT/gfs.$PDY/$cyc
  ln -s $COMIN/gfs.t${cyc}z.atmf$fh.nemsio gfs.t${cyc}z.atmf$fh.nemsio.$PDY
  ln -s $COMIN/gfs.t${cyc}z.sfcf$fh.nemsio gfs.t${cyc}z.sfcf$fh.nemsio.$PDY

  ftp -pn $HOST <<EOF
user $USER $PASSWD
passive
cd incoming/irap/gtg_fv3
bin
prompt
put gfs.t${cyc}z.atmf$fh.nemsio.$PDY
put gfs.t${cyc}z.sfcf$fh.nemsio.$PDY
bye
EOF

  echo "$PDY$cyc $fh">> nemsio.makeup
  scp nemsio.makeup ymao@emcrzdm:/home/ftp/emc/unaff/ymao/fv3_nemsio_list/.

done
done
done

