export netcdf_ver=4.7.4
module load netcdf/$netcdf_ver

export intel_ver=19.1.3.304
export python_ver=3.8.6
export met_ver=10.1.1
export metplus_ver=4.1.1

module use /apps/ops/para/libs/modulefiles/compiler/intel/$intel_ver
module load intel
module load gsl
module load python/$python_ver
module load met/$met_ver
module load metplus/$metplus_ver

export MET_BASE=/apps/ops/para/libs/intel/19.1.3.304/met/10.1.1/share/met
export PATH=/apps/ops/para/libs/intel/19.1.3.304/met/10.1.1/bin:${PATH}
export MET_ROOT=/apps/ops/para/libs/intel/19.1.3.304/met/10.1.1
export MET_bin_exec=bin

area2_g45_masking=WAFC_Area2_one_g45.grib2
area2_g193_masking=WAFC_Area2_one_g193.grib2

grib2file=$area2_g45_masking
prefix=WAFS1P25

# For UKmet defined area 2, first interpolate from 1.25 degree to 0.25 degree
wgrib2 $area2_g45_masking -new_grid_winds grid -new_grid_interpolation neighbor -new_grid latlon 0:1440:0.25 90:721:-0.25 $area2_g193_masking

gen_vx_mask $grib2file $grib2file ${prefix}_SHEM.nc -type lat -thresh '>=-90&&<=-20' -name 'SHEM'

gen_vx_mask $grib2file $grib2file ${prefix}_NHEM.nc -type lat -thresh '>=20&&<=90' -name 'NHEM'

gen_vx_mask $grib2file $grib2file ${prefix}_TROPICS.nc -type lat -thresh '>=-20&&<=20' -name 'TROPICS'

gen_vx_mask $grib2file $grib2file ${prefix}_band.nc -type lat -thresh 'ge25&&le65'
gen_vx_mask ${prefix}_band.nc ${prefix}_band.nc ${prefix}_ASIA.nc -type lon -thresh 'ge60&&le145' -intersection -name 'ASIA'

gen_vx_mask $grib2file $grib2file ${prefix}_band.nc -type lat -thresh 'ge30&&le75'
gen_vx_mask ${prefix}_band.nc ${prefix}_band.nc ${prefix}_NPO.nc -type lon -thresh 'ge120&&le240' -intersection -name 'NPO'

gen_vx_mask $grib2file $grib2file ${prefix}_band.nc -type lat -thresh 'ge-55&&le-10'
gen_vx_mask ${prefix}_band.nc ${prefix}_band.nc ${prefix}_AUNZ.nc -type lon -thresh 'ge90&&le180' -intersection -name 'AUNZ'

gen_vx_mask $grib2file $grib2file ${prefix}_band.nc -type lat -thresh 'ge25&&le60'
gen_vx_mask ${prefix}_band.nc ${prefix}_band.nc ${prefix}_NAMER.nc -type lon -thresh 'ge-145&&le-50' -intersection -name 'NAMER'

gen_vx_mask $grib2file $grib2file ${prefix}_band.nc -type lat -thresh 'ge-7.2&&le7.16'
gen_vx_mask ${prefix}_band.nc ${prefix}_band.nc ${prefix}_EAST.nc -type lon -thresh 'ge-13.78&&le11.24' -intersection -name 'EAST'

gen_vx_mask $grib2file $grib2file ${prefix}_NATL_AR2.nc -type data -mask_field 'name="TMP"; level="L0";' -thresh '>0' -name 'NATL_AR2' -v 3

# Generate a plot(*.ps) file from a polygon(*.nc) file
plot_data_plane ${prefix}_SHM.nc ${prefix}_SHM.ps 'name="SHM"; level="(*,*)";'
plot_data_plane ${prefix}_NHM.nc ${prefix}_NHM.ps 'name="NHM"; level="(*,*)";'
plot_data_plane ${prefix}_TRP.nc ${prefix}_TRP.ps 'name="TRP"; level="(*,*)";'
plot_data_plane ${prefix}_ASIA.nc ${prefix}_ASIA.ps 'name="ASIA"; level="(*,*)";'
plot_data_plane ${prefix}_NPCF.nc ${prefix}_NPCF.ps 'name="NPCF"; level="(*,*)";'
plot_data_plane ${prefix}_AUNZ.nc ${prefix}_AUNZ.ps 'name="AUNZ"; level="(*,*)";'
plot_data_plane ${prefix}_NAMR.nc ${prefix}_NAMR.ps 'name="NAMR"; level="(*,*)";'
plot_data_plane ${prefix}_EAST.nc ${prefix}_EAST.ps 'name="EAST"; level="(*,*)";'
plot_data_plane ${prefix}_AR2.nc ${prefix}_AR2.ps 'name="AR2"; level="(*,*)";'
