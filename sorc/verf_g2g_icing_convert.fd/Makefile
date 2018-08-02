FFLAGS = -FR -I$(INC) -g -O2

#----------------------------------------
# Clear out all suffixes
.SUFFIXES:
# list what we use
.SUFFIXES: .f90 .o
# defines a suffix rule for .f90 -> .o
.f90.o :
	$(FC) $(FFLAGS) -c -C $<

#----------------------------------------
# Macros
# Can Not Dynamically Reset Macros
# The last macro declaration defines the overall macro definition to be used everywhere.
# It's discouraged to use globbing (*, ?). It works for GNU make, but not for the Cray or IBM SP.
PROG = verf_g2g_icing_convert
SRCS = convert_icing_level.f90

# To substitute ".f90" with ".o" in the list given by $(SRCS)
OBJS = $(SRCS:.f90=.o)
MODS = `echo $(SRCS:.f90=.mod)|tr A-Z a-z`

#----------------------------------------
# default target by convention is ``all''
all : $(PROG)
$(PROG) : $(OBJS)
	$(FC) $? $(LIBS) -o $(PROG)
	@rm -f $(OBJS)
$(OBJS) :

clean:
	@echo "rm -f $(OBJS) $(MODS)"
	@rm -f $(OBJS) $(MODS)

install:
	mv $(PROG) ../../exec/.
