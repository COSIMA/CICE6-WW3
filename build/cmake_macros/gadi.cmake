if (COMP_NAME STREQUAL gptl)
  string(APPEND CPPDEFS " -DHAVE_NANOTIME -DBIT64 -DHAVE_VPRINTF -DHAVE_BACKTRACE -DHAVE_SLASHPROC -DHAVE_COMM_F2C -DHAVE_TIMES -DHAVE_GETTIMEOFDAY")
endif()

set(LDFLAGS "")
string(APPEND SLIBS " -mkl=cluster -lnetcdf -lnetcdff -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread -liomp5 -lm")
