set -xa

rawfile=$1
iproc=$2
start=$3
end=$4

tmprawfile=tmprawfile_$iproc
$WGRIB2 $rawfile -for ${start}:${end} -grib $tmprawfile

$WGRIB2 $tmprawfile $opt1 $opt21 $opt22 $opt23 $opt24 $opt25 $opt26 $opt27 $opt28 -new_grid $grid0p25 tmp.0p25_$iproc

$WGRIB2 $tmprawfile $opt1 $opt21 $opt22 $opt23 $opt24 $opt25 $opt26 $opt27 $opt28 -new_grid $grid0p125 tmp.0p125_$iproc

echo "filter converter done $iproc" > convert_done.$iproc
