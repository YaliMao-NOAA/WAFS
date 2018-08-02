#!/bin/sh
#
#  This makefile is to compile grid-to-grid all codes
#  Author: Binbin Zhou
#          20 Feb 2005
#  Modification: 6/20/2014: changed to grib2 version

FFLAGS = -convert big_endian -O3 -auto -I $(INC)

SRCS=   gtgdef.f readcntl.f setarea.f \
	setfcst.f setlevel.f setmodel.f setobtyp.f  \
	stclst.f stldsp.f stlstr.f stnumb.f stread.f strmbl.f \
	strxbl.f getregion.f getnumber.f getGRIB2data.f \
	read_area.f sl1l2.f vl1l2.f fho.f getfho.f get_hasdata.f \
	getHGTsfc.f getTndGRIBdata.f getMeanClimData.f sal1l2.f \
	getAnomlyLevMrk.f val1l2.f afho.f FITWAV_2D.f FITWAV_1D.f \
	esl1l2.f evl1l2.f rhnt.f rhet.f sl1l2_S1.f efho.f \
	EFS.f getHiresClimData.f \
	DIST.f PROB.f naefs.f fho_fss.f FSS.f \
        getcfho.f cfho.f \
	readGRIB2.f
OBJ=${SRCS:.f=.o}

verf_g2g_grid2grid: $(OBJ)
	$(FC) $(FFLAGS) -o $(@) grid2grid.f  $(OBJ)  $(LIBS) $(OPENMP)
	mkdir -p ../../exec/
	mv  $(@) ../../exec/.

clean:
	@rm -f $(OBJ)
########################################################
