#!/bin/sh
#
#  This makefile is to compile grid-to-grid all codes
#  Author: Binbin Zhou
#          20 Nov 2018
#  Modification: 
#    29 Nov 2018: Y Mao, make INC LIBS FFLAGS available at the previous step

SRCS=   gtgdef.f readcntl.f setarea.f \
	setfcst.f setlevel.f setmodel.f setobtyp.f  \
	stclst.f stldsp.f stlstr.f stnumb.f stread.f strmbl.f \
	strxbl.f getregion.f getnumber.f getGRIB2data.f \
	read_area.f sl1l2.f vl1l2.f fho.f getfho.f get_hasdata.f \
	getHGTsfc.f getTndGRIBdata.f getMeanClimData.f sal1l2.f \
	getAnomlyLevMrk.f val1l2.f afho.f FITWAV_1D.f \
	esl1l2.f evl1l2.f rhnt.f rhet.f sl1l2_S1.f efho.f \
	cfho.f getcfho.f \
	EFS.f getHiresClimData.f \
	DIST.f PROB.f naefs.f fho_fss.f FSS.f \
	readGRIB2.f getClimData_2.5deg.f getNAEFSanalysis.f \
	fhop.f readProbGRIB2.f DIST_special.f  \

OBJS=	${SRCS:.f=.o}

CMD=	verf_g2g_grid2grid_grib2
LIBS=	${IP_LIB8}

$(CMD):	$(OBJS)
	$(FC) $(FFLAGS) -o $(@) grid2grid.f  $(OBJS)  $(LIBS)

clean:
	@rm -f $(OBJS)

install:
	mv  $(CMD) ../../exec/$(CMD).$(MACHINE)

#check_prereqs:
#	/nwprod/spa_util/check_libs.bash $(LIBS)
#	/nwprod/spa_util/check_incs.bash $(INC)

########################################################
