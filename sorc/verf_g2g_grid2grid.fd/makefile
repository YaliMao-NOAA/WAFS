#!/bin/sh
#
#  This makefile is to compile grid-to-grid all codes
#  Author: Binbin Zhou
#          20 Feb 2005
#  OS: AIX (IBM-blue)
#  After compile, comp_info file is generated for compiling infomation 
#
#  Modification: 7/20/2011: use ncepxlf -O3 -qhot -bmaxdata:0x12000000000 to compile


FC=    ifort -O3 -openmp -auto

SRCS=   gtgdef.f readcntl.f setarea.f \
	setfcst.f setlevel.f setmodel.f setobtyp.f  \
	stclst.f stldsp.f stlstr.f stnumb.f stread.f strmbl.f \
	strxbl.f getregion.f getnumber.f getGRIBdata.f \
	read_area.f sl1l2.f vl1l2.f fho.f getfho.f get_hasdata.f \
	getHGTsfc.f getTndGRIBdata.f getMeanClimData.f sal1l2.f \
	getAnomlyLevMrk.f val1l2.f afho.f FITWAV_2D.f FITWAV_1D.f \
	esl1l2.f evl1l2.f rhnt.f rhet.f sl1l2_S1.f efho.f \
	EFS.f getHiresClimData.f \
	DIST.f PROB.f naefs.f
OBJ=${SRCS:.f=.o}

LIBS=-L/nwprod/lib -lip_4 -lw3nco_4 -lw3emc_4  -lbacio_4 -lsp_4

verf_g2g_grid2grid: $(OBJ)
	$(FC) -o $(@) grid2grid.f $(OBJ) $(LIBS)
########################################################
