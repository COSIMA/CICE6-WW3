#!/usr/bin/env bash

# The following build commands have been taken and adapted from the CIME build logs.

esmf_dir=/scratch/tm70/mrd599/esmf-8.3.0
. /etc/profile.d/modules.sh
module purge
module load openmpi intel-compiler intel-mkl netcdf pnetcdf python3-as-python
export NETCDF_PATH=/apps/netcdf/4.7.3
export PKG_CONFIG_PATH=/apps/netcdf/4.7.3/lib/pkgconfig:/apps/intel-ct/2022.1.0/mkl/lib/pkgconfig:/half-root/usr/lib64/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig
export ESMFMKFILE=$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default/esmf.mk

cesm_dir=/g/data/tm70/ds0092/CESM
cime_dir=$cesm_dir/cime/CIME/

rm -rf cdeps cmeps gptl include lib

mkdir -p include
mkdir -p lib

# Build gptl
# ====================
mkdir -p gptl
cd ./gptl
make -f $cime_dir/non_py/src/timing/Makefile install -C ./ MACFILE=../Macros.make GPTL_DIR=$cime_dir/non_py/src/timing GPTL_LIBDIR=./ SHAREDPATH=../ COMP_INTERFACE=nuopc COMPILER="intel" DEBUG="FALSE" INCROOT=../include LIBROOT=../lib MPILIB="openmpi" OS="LINUX"
cd ../

# Build mct (why is this needed)
# ====================
mkdir -p mct
cd ./mct
make -f $cime_dir/Tools/Makefile  -C ./ CIME_MODEL=cesm  SMP=TRUE  CASEROOT=../ CASETOOLS=$cime_dir/Tools  CIMEROOT=$cime_dir/../. SRCROOT=$cesm_dir COMP_INTERFACE="nuopc" COMPILER="intel" DEBUG="FALSE" EXEROOT=../ INCROOT=../include LIBROOT=../lib MACH="gadi" MPILIB="openmpi" NINST_VALUE="c1a1i1o1r1w1" OS="LINUX" PIO_VERSION=2 SHAREDLIBROOT=../ SMP_PRESENT="TRUE" USE_ESMF_LIB="TRUE" USE_MOAB="FALSE" COMP_LND="slnd" USE_TRILINOS="FALSE" USE_ALBANY="FALSE" USE_PETSC="FALSE" COMP_NAME=mct ./Makefile.conf
cd ../

# Build CDEPS using cmake
mkdir -p ./cdeps
cd ./cdeps
cmake -DSRC_ROOT=/g/data/tm70/ds0092/CESM  -Dcompile_threaded=TRUE  -DCASEROOT="$cesm_dir/cime/scripts/GMOM_JRA_WD" -DCIMEROOT="$cesm_dir/cime" -DCOMPILER="intel" -DDEBUG="FALSE" -DMACH="gadi" -DMPILIB="openmpi" -DNINST_VALUE="c1a1i1o1r1w1" -DOS="LINUX" -DPIO_VERSION="2" -DCMAKE_Fortran_COMPILER_WORKS=1 -DCMAKE_INSTALL_PREFIX:PATH=/ -DLIBROOT=$nuopc_bld_dir  -DPIO_C_LIBRARY=$nuopc_bld_dir/lib -DPIO_C_INCLUDE_DIR=$nuopc_bld_dir/include  -DPIO_Fortran_LIBRARY=$nuopc_bld_dir/lib -DPIO_Fortran_INCLUDE_DIR=$nuopc_bld_dir/include $cesm_dir/components/cdeps
make install VERBOSE=1 DESTDIR="./"

cd ../
cdeps_bld_dir=./cdeps

# Compile CMEPS source
flags="-I. -I$cdeps_bld_dir/fox/include -I$cdeps_bld_dir/dshr -I$nuopc_bld_dir/include -I$cdeps_bld_dir/include -I$nuopc_bld_dir/nuopc/esmf/c1a1i1o1r1w1/include -I$nuopc_bld_dir/finclude -I/apps/netcdf/4.7.3/include -I$GMOM_bld_dir/atm/obj -I$GMOM_bld_dir/ice/obj -I$A_bld_dir/ocn/obj -I$GMOM_bld_dir/glc/obj -I$GMOM_bld_dir/rof/obj -I$GMOM_bld_dir/wav/obj -I$GMOM_bld_dir/esp/obj -I$GMOM_bld_dir/iac/obj -I$GMOM_bld_dir/lnd/obj -I. -I$cesm_dir/cime/scripts/GMOM_JRA_WD/SourceMods/src.drv -I$cmeps_dir/mediator -I$cmeps_dir/cesm/flux_atmocn -I$cmeps_dir/cmeps/cesm/driver -I$GMOM_bld_dir/lib/include -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source -O2 -debug minimal -I$esmf_dir/mod/modg/Linux.intel.x86_64_medium.openmpi.default -I$esmf_dir/src/include -I/apps/netcdf/4.7.3/include  -DLINUX  -DCESMCOUPLED -DFORTRANUNDERSCORE -DCPRINTEL -DNDEBUG -DUSE_ESMF_LIB -DHAVE_MPI -DNUOPC_INTERFACE -DPIO2 -DHAVE_SLASHPROC -DESMF_VERSION_MAJOR=8 -DESMF_VERSION_MINOR=3 -DATM_PRESENT -DICE_PRESENT -DOCN_PRESENT -DROF_PRESENT -DWAV_PRESENT -DMED_PRESENT -DPIO2 -free -DUSE_CONTIGUOUS="

# The order of these is important
cmeps_src_files=( cesm/driver/esm_time_mod.F90 mediator/med_kind_mod.F90 cesm/flux_atmocn/shr_flux_mod.F90 cesm/driver/t_driver_timers_mod.F90 cesm/driver/util.F90 mediator/med_constants_mod.F90 mediator/med_utils_mod.F90 mediator/med_methods_mod.F90 mediator/med_internalstate_mod.F90 mediator/med_phases_ocnalb_mod.F90 mediator/med_io_mod.F90 mediator/med_time_mod.F90 mediator/esmFlds.F90 mediator/med_phases_profile_mod.F90 mediator/med_diag_mod.F90 mediator/med_map_mod.F90 mediator/med_merge_mod.F90 mediator/esmFldsExchange_cesm_mod.F90 mediator/esmFldsExchange_nems_mod.F90 mediator/esmFldsExchange_hafs_mod.F90 mediator/med_phases_history_mod.F90 mediator/med_phases_prep_lnd_mod.F90 mediator/med_phases_prep_ice_mod.F90 mediator/med_fraction_mod.F90 mediator/med_phases_prep_rof_mod.F90 mediator/med_phases_prep_wav_mod.F90 mediator/med_phases_aofluxes_mod.F90 mediator/med_phases_post_wav_mod.F90 mediator/med_phases_post_rof_mod.F90 mediator/med_phases_post_glc_mod.F90 mediator/med_phases_post_atm_mod.F90 mediator/med_phases_prep_glc_mod.F90 mediator/med_phases_post_ice_mod.F90 mediator/med_phases_post_lnd_mod.F90 mediator/med_phases_restart_mod.F90 mediator/med_phases_post_ocn_mod.F90 mediator/med_phases_prep_atm_mod.F90 mediator/med_phases_prep_ocn_mod.F90 mediator/med.F90 cesm/driver/esm.F90 cesm/driver/ensemble_driver.F90 cesm/driver/esmApp.F90 )

for file in ${cmeps_src_files[@]}; do
    mpif90 -c $flags $cmeps_dir/$file
done

# Compile cesm executable
mkdir -p ./cmeps
mv *.mod *.o ./cmeps/

object_files=()
for file in ${cmeps_src_files[@]}; do
    bname=$(basename $file)
    object_files+=( "./cmeps/${bname%.F90}.o" )
done

mpif90 -o ./cesm.exe ${object_files[@]} -L$GMOM_bld_dir/lib/ -latm -lice -lrof -lwav -L$A_bld_dir/lib/ -locn -L$cdeps_bld_dir/dshr -ldshr -L$cdeps_bld_dir/streams -lstreams -L$nuopc_bld_dir/nuopc/esmf/c1a1i1o1r1w1/lib -lcsm_share -L$nuopc_bld_dir/lib -lpiof -lpioc -lgptl -lmct -lmpeu -mkl=cluster -mkl=cluster -lnetcdf -lnetcdff -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread -liomp5 -lm -L$cdeps_bld_dir/fox/lib -lFoX_dom -lFoX_sax -lFoX_utils -lFoX_fsys -lFoX_wxml -lFoX_common -lFoX_fsys -L$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default -Wl,-rpath,$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default -lesmf -lmpi_cxx -cxxlib -lrt -ldl -mkl -lnetcdff -lnetcdf -lpioc -L$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default -L/apps/netcdf/4.7.3/lib
