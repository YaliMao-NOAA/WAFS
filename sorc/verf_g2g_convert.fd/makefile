#!/bin/sh
#
#  This makefile is to compile ensembel production generator
#  Author: Binbin Zhou
#  OS: Intel WCOSS
#

CMD= verf_g2g_convert

$(CMD):
	$(FC) $(FFLAGS) -o $(@) convert.f $(LIBS)

clean:
	@rm -f $(OBJS)

install:
	mv  $(CMD) ../../exec/$(CMD).$(MACHINE)

#
