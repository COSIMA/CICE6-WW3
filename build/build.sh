#!/usr/bin/env bash

# Can we create a "D_JRA_WD" build by switching out the active ocean component
# for a CDEPS DOCN DOM component? These scripts assume that the shared libs
# have already been created by CIME:
# `./case.build --sharedlib-only`
# To do the model builds, CIME uses cmake for some components and a monster
# do-it-all Makefile for others (see cime/CIME/Tools/Makefile). The Makefile
# expects a specific directory structure for the build.

ACTIVE_OCN=true

esmf_dir=/scratch/tm70/mrd599/esmf-8.3.0
. /etc/profile.d/modules.sh
module purge
module load openmpi intel-compiler intel-mkl netcdf pnetcdf python3-as-python
export NETCDF_PATH=/apps/netcdf/4.7.3
export PKG_CONFIG_PATH=/apps/netcdf/4.7.3/lib/pkgconfig:/apps/intel-ct/2022.1.0/mkl/lib/pkgconfig:/half-root/usr/lib64/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig
export ESMFMKFILE=$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default/esmf.mk

#cmeps_dir=$cesm_dir/components/cmeps
#A_bld_dir=/scratch/tm70/ds0092/cime/scratch/A/bld
#GMOM_bld_dir=/scratch/tm70/ds0092/cime/scratch/GMOM_JRA_WD/bld
# A_bld_dir=$GMOM_bld_dir
#nuopc_bld_dir=$GMOM_bld_dir/intel/openmpi/nodebug/nothreads/nuopc

cwd=$(pwd)

cesm_dir=/g/data/tm70/ds0092/CESM
sharedlib_root=/scratch/tm70/ds0092/cime/scratch/GMOM_JRA_WD/bld/intel/openmpi/nodebug/nothreads/nuopc

# Build CDEPS
# ====================
cdeps_bld_dir=${cwd}/cdeps
mkdir -p $cdeps_bld_dir
cd $cdeps_bld_dir
cmake -DSRC_ROOT=${cesm_dir}  -Dcompile_threaded="FALSE"  -DCASEROOT=${cwd} -DCIMEROOT="${cesm_dir}/cime" -DCOMPILER="intel" -DDEBUG="FALSE" -DMACH="gadi" -DMPILIB="openmpi" -DNINST_VALUE="c1a1i1o1r1w1" -DOS="LINUX" -DPIO_VERSION="2" -DCMAKE_Fortran_COMPILER_WORKS=1 -DCMAKE_INSTALL_PREFIX:PATH=/ -DLIBROOT=${sharedlib_root}  -DPIO_C_LIBRARY=${sharedlib_root}/lib -DPIO_C_INCLUDE_DIR=${sharedlib_root}/include  -DPIO_Fortran_LIBRARY=${sharedlib_root}/lib -DPIO_Fortran_INCLUDE_DIR=${sharedlib_root}/include $cesm_dir/components/cdeps
make install VERBOSE=1 DESTDIR="./"
cd ${cwd}

mkdir -p ${cwd}/lib

# Build atm data model
# ====================
cd ${cdeps_bld_dir}/datm
make datm
ln -sf ${cdeps_bld_dir}/datm/libdatm.a ${cwd}/lib/libatm.a
cd ${cwd}

# Build rof data model
# ====================
cd ${cdeps_bld_dir}/drof
make drof
ln -sf ${cdeps_bld_dir}/drof/libdrof.a ${cwd}/lib/librof.a
cd ${cwd}

# Build ocn model
# ====================
if [ "$ACTIVE_OCN" = true ] ; then
    echo "Not implemented"
else
    cd ${cdeps_bld_dir}/docn
    make docn
    ln -sf ${cdeps_bld_dir}/docn/libdocn.a ${cwd}/lib/libocn.a
    cd ${cwd}
fi

# Build CICE6
# ====================
cd ${cwd}/cice6
make complib -j 8 COMP_NAME=cice COMPLIB=${cwd}/lib/libice.a -f ${cesm_dir}/cime/CIME/Tools/Makefile USER_CPPDEFS=" -Dncdf" CIME_MODEL=cesm  SMP=FALSE CASEROOT=${cwd} CASETOOLS=${cesm_dir}/cime/CIME/Tools CIMEROOT=${cesm_dir}/cime SRCROOT=${cesm_dir} COMP_INTERFACE="nuopc" COMPILER="intel" DEBUG="FALSE" EXEROOT="/scratch/tm70/ds0092/cime/scratch/GMOM_JRA_WD/bld" RUNDIR="/scratch/tm70/ds0092/cime/scratch/GMOM_JRA_WD/run" INCROOT="/scratch/tm70/ds0092/cime/scratch/GMOM_JRA_WD/bld/lib/include" LIBROOT="/scratch/tm70/ds0092/cime/scratch/GMOM_JRA_WD/bld/lib" MACH="gadi" MPILIB="openmpi" NINST_VALUE="c1a1i1o1r1w1" OS="LINUX" PIO_VERSION=2 SHAREDLIBROOT="/scratch/tm70/ds0092/cime/scratch/GMOM_JRA_WD/bld" SMP_PRESENT="FALSE" USE_ESMF_LIB="TRUE" USE_MOAB="FALSE" COMP_LND="slnd" USE_PETSC="FALSE"

# Build WW3
# ====================


# Compile CMEPS source
flags="-I. -I$nuopc_bld_dir/CDEPS/fox/include -I$nuopc_bld_dir/CDEPS/dshr -I$nuopc_bld_dir/include -I$nuopc_bld_dir/CDEPS/include -I$nuopc_bld_dir/nuopc/esmf/c1a1i1o1r1w1/include -I$nuopc_bld_dir/finclude -I/apps/netcdf/4.7.3/include -I$GMOM_bld_dir/atm/obj -I$GMOM_bld_dir/ice/obj -I$A_bld_dir/ocn/obj -I$GMOM_bld_dir/glc/obj -I$GMOM_bld_dir/rof/obj -I$GMOM_bld_dir/wav/obj -I$GMOM_bld_dir/esp/obj -I$GMOM_bld_dir/iac/obj -I$GMOM_bld_dir/lnd/obj -I. -I$cesm_dir/cime/scripts/GMOM_JRA_WD/SourceMods/src.drv -I$cmeps_dir/mediator -I$cmeps_dir/cesm/flux_atmocn -I$cmeps_dir/cmeps/cesm/driver -I$GMOM_bld_dir/lib/include -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source -O2 -debug minimal -I$esmf_dir/mod/modg/Linux.intel.x86_64_medium.openmpi.default -I$esmf_dir/src/include -I/apps/netcdf/4.7.3/include  -DLINUX  -DCESMCOUPLED -DFORTRANUNDERSCORE -DCPRINTEL -DNDEBUG -DUSE_ESMF_LIB -DHAVE_MPI -DNUOPC_INTERFACE -DPIO2 -DHAVE_SLASHPROC -DESMF_VERSION_MAJOR=8 -DESMF_VERSION_MINOR=3 -DATM_PRESENT -DICE_PRESENT -DOCN_PRESENT -DROF_PRESENT -DWAV_PRESENT -DMED_PRESENT -DPIO2 -free -DUSE_CONTIGUOUS="

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

mpif90 -o ./cesm.exe ${object_files[@]} -L$GMOM_bld_dir/lib/ -latm -lice -lrof -lwav -L$A_bld_dir/lib/ -locn -L$nuopc_bld_dir/CDEPS/dshr -ldshr -L$nuopc_bld_dir/CDEPS/streams -lstreams -L$nuopc_bld_dir/nuopc/esmf/c1a1i1o1r1w1/lib -lcsm_share -L$nuopc_bld_dir/lib -lpiof -lpioc -lgptl -lmct -lmpeu -mkl=cluster -mkl=cluster -lnetcdf -lnetcdff -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread -liomp5 -lm -L$nuopc_bld_dir/CDEPS/fox/lib -lFoX_dom -lFoX_sax -lFoX_utils -lFoX_fsys -lFoX_wxml -lFoX_common -lFoX_fsys -L$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default -Wl,-rpath,$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default -lesmf -lmpi_cxx -cxxlib -lrt -ldl -mkl -lnetcdff -lnetcdf -lpioc -L$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default -L/apps/netcdf/4.7.3/lib
