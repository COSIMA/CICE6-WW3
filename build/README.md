Exploring CICE6-WW3-DOCN-DATM-DROF CESM build
=============================================

This directory contains scripts exploring building a CICE6-WW3-DOCN-DATM-DROF-SLND-SGLC CESM configuration. Three build scripts are provided. All assume that at the least the shared libs are already built at `/scratch/tm70/ds0092/cime/scratch/D_JRA_WD/bld`. The required shared libraries can be built using (for example) the CIME `GMOM_JRA_WD` compset:
```
./create_newcase --case D_JRA_WD --compset GMOM_JRA_WD --res T62_g16 --machine gadi --run-unsupported
cd D_JRA_WD
./case.setup
./case.build --sharedlib-only
```

`build.sh` (working)
--------------------
This script builds all the model components and the CMEPS `cesm.exe` exectuable. The script includes an option to build either MOM6 (`ACTIVE_OCN=true`) or a data ocean model (`ACTIVE_OCN=false`).

`build_switch.sh` (not working)
-------------------------------
This script uses a prior complete build of `GMOM_JRA_WD` and attempts to switch out the active ocean component for a data ocean at the final step of building the CMEPS `cesm.exe` executable. If you don't already have a complete build of `GMOM_JRA_WD`, first run:
```
./create_newcase --case GMOM_JRA_WD --compset GMOM_JRA_WD --res T62_g16 --machine gadi --run-unsupported
cd GMOM_JRA_WD
./case.setup
./case.build
```

`build_swap.sh` (not working)
-----------------------------
This script uses a prior complete build of `GMOM_JRA_WD` and attempts to swap the active ocean component for a data ocean. It is different from `build_switch.sh` in that the data ocean component replaces the active component in the `GMOM_JRA_WD` build directory. If you don't already have a complete build of `GMOM_JRA_WD`, see the description for `build_switch.sh` above.
