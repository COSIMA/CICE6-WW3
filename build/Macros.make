
# This file is auto-generated, do not edit. If you want to change
# sharedlib flags, you can edit the cmake_macros in this case. You
# can change flags for specific sharedlibs only by checking COMP_NAME.

CFLAGS :=  -qno-opt-dynamic-align -fp-model precise -std=gnu99 -O2 -debug minimal
CPPDEFS := $(CPPDEFS)  -DCESMCOUPLED -DFORTRANUNDERSCORE -DCPRINTEL
CXX_LDFLAGS :=  -cxxlib
CXX_LINKER := FORTRAN
FC_AUTO_R8 := -r8
FFLAGS :=  -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source -O2 -debug minimal
FFLAGS_NOOPT := -O0
FIXEDFLAGS := -fixed
FREEFLAGS := -free
LDFLAGS := 
MACRO_FILE := 
MPICC := mpicc
MPICXX := mpicxx
MPIFC := mpif90
SCC := icc
SCXX := icpc
SFC := ifort
SLIBS := $(SLIBS)  -mkl=cluster -mkl=cluster -lnetcdf -lnetcdff -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread -liomp5 -lm
SUPPORTS_CXX := TRUE

ifeq "$(COMP_NAME)" "mom"
  CPPDEFS := $(CPPDEFS)  -DCESMCOUPLED -Duse_LARGEFILE -DFORTRANUNDERSCORE -DCPRINTEL
  FFLAGS :=  $(FC_AUTO_R8)  -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source -O2 -debug minimal
endif
ifeq "$(COMP_NAME)" "gptl"
  CPPDEFS := $(CPPDEFS)  -DCESMCOUPLED -DFORTRANUNDERSCORE -DCPRINTEL -DHAVE_NANOTIME -DBIT64 -DHAVE_VPRINTF -DHAVE_BACKTRACE -DHAVE_SLASHPROC -DHAVE_COMM_F2C -DHAVE_TIMES -DHAVE_GETTIMEOFDAY
endif
