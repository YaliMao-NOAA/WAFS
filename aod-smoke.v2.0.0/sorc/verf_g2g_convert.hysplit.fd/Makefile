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


SRC=    convert_hysplit.f90

OBJ=    convert_hysplit.o

all: verf_g2g_convert.hysplit

LIBS= $(ESSL) $(MASS) $(OPTS) $(LIST) $(TRAPS) $(PROFILE) $(DEBUG) -L/nwprod/lib -lip_4 -lw3_4 -lbacio_4

.SUFFIXES: .o .f90

.f90.o: $(INCLS)
	$(FC) -c $<

convert_hysplit.o: convert_hysplit.f90

verf_g2g_convert.hysplit: $(OBJ)
	$(FC)  -o $(@) $(OBJ) $(LIBS)

clean:
	rm -f ${OBJ}
#

