#%Module################################################

# used by:
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/g2g_verif.v3.0.12
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/nemsio/makefile.sh

# module purge
# /gpfs/dell2/emc/modeling/noscrub/Yali.Mao/git/save/modules_setting.sh
# module list

#=====================================================#
if [[ `hostname` =~ ^tfe ]] ; then
#=====================================================#
  export MACHINE=theia

  #========== Theia ====================#

  # Loading Intel Compiler Suite
  #module use /apps/modules/modulefamilies/intel
  module load intel/15.1.133
  module load impi/5.0.3.048
  module load netcdf/3.6.3

  #module use /contrib/modulefiles


  # Loding nceplibs modules
  #module use /scratch3/NCEPDEV/nwprod/lib/modulefiles
  module load sigio/v2.0.1
  module load jasper/v1.900.1
  module load png/v1.2.44
  module load z/v1.2.6
  module load sfcio/v1.0.0
  module load nemsio/v2.2.2
  module load bacio/v2.0.1
  module load g2/v3.1.0
  module load xmlparse/v2.0.0
  module load gfsio/v1.1.0
  module load ip/v3.0.0
  module load sp/v2.0.2
  module load w3emc/v2.2.0
  module load w3nco/v2.0.6
  module load crtm/v2.2.3
  module load g2tmpl/v1.5.0

  module use /scratch3/NCEPDEV/stmp1/gwv/wrf.post.lib/modulefiles
  module load wrf-io-v1.1.1

  export FC=ifort

  export INC="-I ${IP_INC4} -I ${G2_INC4}"
  export LIBS="${IP_LIB4} ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4}  ${SP_LIB4} ${G2_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB} ${BUFR_LIB4}"
  export FREE="-FR"
  export OPENMP="-qopenmp"

  export myFFLAGS="${INC} -g -O2 -convert big_endian"

# From Fanglin
# module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/python/modulefiles
# module load python/3.6.1-emc

#=====================================================#
elif [[ `hostname` =~ ^tfe ]] ; then
#=====================================================#
  export MACHINE=theia

  #========== Theia ====================#

  # Loading Intel Compiler Suite
  #module use /apps/modules/modulefamilies/intel
  module load intel/15.1.133
  module load impi/5.0.3.048
  module load netcdf/3.6.3

  #module use /contrib/modulefiles


  # Loding nceplibs modules
  #module use /scratch3/NCEPDEV/nwprod/lib/modulefiles
  module load sigio/v2.0.1
  module load jasper/v1.900.1
  module load png/v1.2.44
  module load z/v1.2.6
  module load sfcio/v1.0.0
  module load nemsio/v2.2.2
  module load bacio/v2.0.1
  module load g2/v3.1.0
  module load xmlparse/v2.0.0
  module load gfsio/v1.1.0
  module load ip/v3.0.0
  module load sp/v2.0.2
  module load w3emc/v2.2.0
  module load w3nco/v2.0.6
  module load crtm/v2.2.3
  module load g2tmpl/v1.5.0

  module use /scratch3/NCEPDEV/stmp1/gwv/wrf.post.lib/modulefiles
  module load wrf-io-v1.1.1

  export FC=ifort

  export INC="-I ${IP_INC4} -I ${G2_INC4}"
  export LIBS="${IP_LIB4} ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4}  ${SP_LIB4} ${G2_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB} ${BUFR_LIB4}"
  export FREE="-FR"
  export OPENMP="-qopenmp"

  export myFFLAGS="${INC} -g -O2 -convert big_endian"

# From Fanglin
# module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/python/modulefiles
# module load python/3.6.1-emc

#=====================================================#
elif [[ `hostname` =~ ^[g|t][0-9]{1} ]] ; then
#     `cat /etc/dev` # gyre/tide/luna/surg
#=====================================================#
  export MACHINE=wcoss

  #========== Gyre/Tide =====================#
  module load ibmpe ics lsf
  module load hpss/4.0.1.2
  module load grib_util
  module load prod_util
  module load prod_envir # not sure why, it can't be loaded on WCOSS

  module load HDF5/1.8.9/serial
  module load g2/v3.1.0
  module load bacio/v2.0.1
  module load nemsio/v2.2.2
  module load w3nco/v2.0.6
  module load w3emc/v2.2.0
  module load sp/v2.0.2
  module load ip/v3.0.0
  module load jasper
  module load png
  module load z

  export FC=ifort

  export INC="-I /nwprod/lib/incmod/g2_4 -I /nwprod2/lib/ip/v3.0.0/include/ip_v3.0.0_8"
#  export INC="-I $IP_LIB8"
  export LIBS="-L /nwprod/lib -lip_4 -lw3nco_4 -lw3emc_4 -lbacio_4 -lsp_4 -lg2_4 -ljasper -lpng -lz -lbufr_4_64"
  export FREE="-FR"
  export OPENMP="-openmp"

  export myFFLAGS="${INC} -g -O2 -convert big_endian"


#=====================================================#
elif [[ `hostname` =~ ^[l|s]login ]] ; then
#=====================================================#

  export MACHINE=cray

  #========== Surge/Luna ====================#
  module purge

  # Loading Intel Compiler Suite
  module load PrgEnv-intel
  module load craype-sandybridge
#  module switch intel intel/15.0.3.187

  # Loading nceplibs modules
  module use -a /usrx/local/prod/modulefiles
  module load NetCDF-intel-sandybridge/4.2
  module load zlib-intel-sandybridge/1.2.7
  module load jasper-gnu-sandybridge/1.900.1
  module load png-intel-sandybridge/1.2.49

  module use -a /gpfs/hps/nco/ops/nwprod/lib/modulefiles
  module load w3nco-intel/2.0.6
  module load w3emc-intel/2.2.0
  module load bacio-intel/2.0.1
  module load g2-intel/3.1.0
  module load g2tmpl-intel/1.5.0
  module load sigio-intel/2.0.1
  module load sfcio-intel/1.0.0
  module load bufr-intel/11.0.1
  module load nemsio-intel/2.2.3

#  module load ip-intel/2.0.0
  module load ip-intel/3.0.0
  module load sp-intel/2.0.2

  module load gcc/6.3.0
  module load grib_util/1.1.0
  module load prod_util/1.0.33

  export FC=ftn

  export INC="-I ${IP_INC4} -I ${G2_INC4}"
  export LIBS="${IP_LIB4} ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4}  ${SP_LIB4} ${G2_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB} ${BUFR_LIB4}"
  export FREE="-FR"
  export OPENMP="-openmp"

  export myFFLAGS="${INC} -g -O2 -convert big_endian"

#=====================================================#
else
#=====================================================#

  export MACHINE=dell

  #========== Venus/Mars ====================#
  module purge

  module load ips/18.0.1.163
  module load impi/18.0.1

  module load prod_util/1.1.0
  module load prod_envir/1.0.2

  module load jasper/1.900.1
  module load libpng/1.2.59
  module load NetCDF/3.6.3
  module load zlib/1.2.11

  module load w3emc/2.3.0
  module load w3nco/2.0.6
  module load bacio/2.0.2
  module load g2/3.1.0
  module load g2tmpl/1.5.0
  module load sfcio/1.0.0
  module load nemsio/2.2.3
  module load ip/3.0.1
  module load sp/2.0.2
  module load bufr/11.2.0
  #module load bufr_dumplist/1.5.0
  #module use -a /gpfs/dell1/nco/ops/nwpara/modulefiles/compiler_prod/ips/18.0.1
  module load bufr_dumplist/2.0.0

  export FC=ifort

  export INC="-I ${IP_INC4} -I ${G2_INC4}"
  export LIBS="${IP_LIB4} ${W3NCO_LIB4} ${W3EMC_LIB4} ${BACIO_LIB4}  ${SP_LIB4} ${G2_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB} ${BUFR_LIB4}"
  export FREE="-FR"
  export OPENMP="-qopenmp"

  export myFFLAGS="${INC} -g -O2 -convert big_endian"

#=====================================================#
fi
#=====================================================#

