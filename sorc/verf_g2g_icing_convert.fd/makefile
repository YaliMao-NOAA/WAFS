#----------------------------------------
# Clear out all suffixes
.SUFFIXES:
# list what we use
.SUFFIXES: .f90 .o

FC=	ifort

INCS   = -I$(SFCIO_INC4) \
           -I$(NEMSIO_INC) \
           -I$(SIGIO_INC4) \
           -I$(G2_INC4) \
           -I$(G2TMPL_INC) \
           -I$(GFSIO_INC4) \
           -I$(W3EMC_INC4) \
           -I$(CRTM_INC) \
	   -I$(IP_INC4)


LIBS     = $(WRFIO_LIB) \
           $(G2TMPL_LIB) \
           $(G2_LIB4) \
           $(JASPER_LIB) \
           $(PNG_LIB) \
           $(Z_LIB) \
           $(NEMSIO_LIB) \
           $(GFSIO_LIB4) \
           $(SIGIO_LIB4) \
           $(SFCIO_LIB4) \
           $(IP_LIB4) \
           $(SP_LIB4) \
           $(W3EMC_LIB4) \
           $(W3NCO_LIB4) \
           $(BACIO_LIB4) \
           $(CRTM_LIB)

# defines a suffix rule for .f90 -> .o
.f90.o :
	$(FC) $(FFLAGS) $(INCS) -c -C $<

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
	mv $(PROG) ../../exec/$(PROG).$(MACHINE)
