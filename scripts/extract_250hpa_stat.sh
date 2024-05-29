datafolder=/lfs/h2/emc/ptmp/yali.mao/evs_plot/data
years="2018 2019 2020 2021 2022 2023 2024"
for year in $years ; do
    cd $datafolder/$year
    grep "P250    ANALYS \(TROPICS\|NHEM\|SHEM\)" * | grep -v "WIND80" > $datafolder/extract_$year.stat
done

: '
datafolder_in=/lfs/h2/emc/vpppg/noscrub/yali.mao/vsdb/wafs/prod.prod
datafolder_out=/lfs/h2/emc/ptmp/yali.mao/uk_vsdb
cd $datafolder_in
files=`ls twind*vsdb`
for file in $files ; do
    grep "P250 =" $file | grep "\(NPCF\|AR2\)" > $datafolder_out/p250_$file
done
'

