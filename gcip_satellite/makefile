SHELL=/bin/sh
#
SRCS=   write_ndfd_grib2.f90 write_ndfd_grib2.f90
OBJS=   satellite.o  write_ndfd_grib2.o
# Tunable parameters
#
# FC		Name of the fortran compiling system to use
# LDFLAGS	Flags to the loader
# LIBS		List of libraries
# CMD		Name of the executable
# PROFLIB	Library needed for profiling
#
#FC =	 ifort	
#LDFLAGS = -p -bnoquiet -bloadmap:mug
#LDFLAGS = -pg
#INC = /nwprod/lib/incmod/g2_4
#LIBS = -L/nwprod/lib -lg2_4 -lw3nco_v2.0.3_4 -lbacio_4 -ljasper -lpng -lz
LIBS = ${G2_LIB4} ${W3NCO_LIB4} ${BACIO_LIB4} ${IP_LIB4} ${SP_LIB4} ${JASPER_LIB} ${PNG_LIB} ${Z_LIB}  ${BUFR_LIB4}

CMD =	gcip_satellite
#PROFLIB =	-lprof

# To perform the default compilation, use the first line
# To compile with flowtracing turned on, use the second line
# To compile giving profile additonal information, use the third line
# WARNING:  SIMULTANEOUSLY PROFILING AND FLOWTRACING IS NOT RECOMMENDED 
FFLAGS =	-O -I ${G2_INC4}
FFLAGST =      -O -FR -I ${G2_INC4}

# Lines from here on down should not need to be changed.  They are the
# actual rules which make uses to build a.out.
#
.SUFFIXES:	.f .o .f90
%.o: %.mod

$(CMD):		$(OBJS)
	$(FC) $(LDFLAGS) -o $(@) $(OBJS) $(LIBS)
	rm *.o *.mod

.f.o:
	$(FC) $(FFLAGS) -c $<
.f90.o:
	$(FC) $(FFLAGST) -c $<

clean:
	-rm -f $(OBJS)

clobber:	clean
	-rm -f $(CMD) $(CMD).prof

void:	clobber
	-rm -f $(SRCS) makefile

install:
	mv $(CMD) ../../exec/.
