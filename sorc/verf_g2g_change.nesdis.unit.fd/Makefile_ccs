#!/bin/sh
#

FC=     xlf
ARCH     = auto
OPTS     =  -qnosave -qarch=$(ARCH) -qmaxmem=-1 -NS2000
LIST     =
#FREE     = -qfree
FREE     =
TRAPS    =
PROFILE  =
DEBUG    = -g
MEM      =
MAP      =
W3LIBDIR = /nwprod/lib
ESSL     = -lessl
MASS     = -lmass


SRC=    change_nesdis_unit.f90

OBJ=    change_nesdis_unit.o

all:	verf_g2g_change.nesdis.unit

LIBS= $(ESSL) $(MASS) $(OPTS) $(LIST) $(TRAPS) $(PROFILE) $(DEBUG) -L/nwprod/lib -lip_4 -lw3_4 -lbacio_4

.SUFFIXES: .o .f90

.f90.o: $(INCLS)
	$(FC) -c $<

change_nesdis_unit.o: change_nesdis_unit.f90

verf_g2g_change.nesdis.unit: $(OBJ)
	$(FC)  -o $(@) $(OBJ) $(LIBS)

clean:
	rm -f ${OBJ}
#

