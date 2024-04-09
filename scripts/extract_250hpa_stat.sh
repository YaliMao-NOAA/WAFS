datafolder=/lfs/h2/emc/ptmp/yali.mao/evs_plot.old/data
years="2018 2019 2020 2021 2022 2023 2024"
for year in $years ; do
    cd $datafolder/$year
    grep "P250    ANALYS \(NPO\|NATL_AR2\)" * | grep -v "WIND80" > $datafolder/extract_$year.stat
done
