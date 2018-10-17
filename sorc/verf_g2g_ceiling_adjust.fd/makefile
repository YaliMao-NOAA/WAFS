#!/bin/sh
#
#  This makefile is to compile ensembel production generator
#  Author: Binbin Zhou
#

CMD= verf_g2g_ceiling_adjust

#all:	check_prereqs $(CMD)
#all:	clean $(CMD) install

$(CMD):
	$(FC) $(FFLAGS) -o $(@) ceiling_adjust.f $(LIBS)
clean:
	-rm -f *.o $(CMD)
install:
	-mv $(CMD) ../../exec/$(CMD).$(MACHINE)
