list(APPEND fortran_src
satellite.f90
write_ndfd_grib2.f90
)

# Set compiler flags.
if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -g -traceback")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O3")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -check -check bounds -check noarg_temp_created -check nopointer -fp-stack-check -fstack-protector-all -fpe0 -debug -ftrapuv")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -g -fbacktrace")
  set(CMAKE_Fortran_FLAGS_RELEASE "-O2")
  set(CMAKE_Fortran_FLAGS_DEBUG "-O0 -ggdb -fno-unsafe-math-optimizations -frounding-math -fsignaling-nans -ffpe-trap=invalid,zero,overflow -fbounds-check")
endif()

set(exe_name gcip_satellite.x)
add_executable(${exe_name} ${fortran_src})
set_target_properties(${exe_name} PROPERTIES LINKER_LANGUAGE Fortran)
target_link_libraries(
  ${exe_name}
  g2::g2_4
  ip::ip_4
  sp::sp_4
  bacio::bacio_4
  w3emc::w3emc_4
  bufr::bufr_4
  NetCDF::NetCDF_Fortran
)

install(
  TARGETS ${exe_name}
  EXPORT ${PROJECT_NAME}Exports
  RUNTIME DESTINATION
  ${CMAKE_INSTALL_BINDIR})
