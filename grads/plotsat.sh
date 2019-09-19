set -xa

PDY=$1

if [[ -z $2 ]] ; then
    HHs="00 03 06 09 12 15 18 21"
else
    HHs=$2
fi

for HH in $HHs ; do

  if [ $(( $HH % 6 )) -ne 0 ] ; then 
    DIRHH=`/nwprod/util/exec/ndate -3 $PDY$HH | cut -c9-10`
  else
    DIRHH=$HH
  fi
  cd /ptmpp1/Yali.Mao/wafs_gcip$DIRHH.2
  cp /global/save/Yali.Mao/grads/*gs .

  products="SSR VIS SIR LIR"

  cat <<EOF >tmp.gs
EOF

  for product in $products ; do
    curl -O ftp://140.90.107.15/pub/smcd/opdb/globalmosaicgeosat/testdata/GLOBCOMP$product.$PDY$HH
    /global/save/Yali.Mao/wafs/gcip/sat/sat  GLOBCOMP$product.$PDY$HH
    wait 10
    mv test.grid1 $product.grd
    ksh /global/save/Yali.Mao/grads/gcm.sh $product.grd

    img=$product.$PDY$HH.png

    cat <<EOF >>tmp.gs
*
'open $product.grd.ctl'
'rgbColors.gs'
'd brtmpclm'
'printim $img png'
'close 1'
EOF

  done

  grads  -lbxc "tmp.gs"
  wait 20
done
rm tmp.gs