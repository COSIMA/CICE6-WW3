#!/usr/bin/env bash

# Can we create a "D_JRA_WD" build by switching out the active ocean component
# for a CDEPS DOCN DOM component? These scripts assume that the shared libs
# have already been created by CIME:
# `./case.build --sharedlib-only`
# To do the model builds, CIME uses cmake for some components and a monster
# do-it-all Makefile for others (see cime/CIME/Tools/Makefile). The Makefile
# expects a specific directory structure for the build.

ACTIVE_OCN=false

esmf_dir=/scratch/tm70/mrd599/esmf-8.3.0
. /etc/profile.d/modules.sh
module purge
module load openmpi intel-compiler intel-mkl netcdf pnetcdf python3-as-python
export NETCDF_PATH=/apps/netcdf/4.7.3
export PKG_CONFIG_PATH=/apps/netcdf/4.7.3/lib/pkgconfig:/apps/intel-ct/2022.1.0/mkl/lib/pkgconfig:/half-root/usr/lib64/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig
export ESMFMKFILE=$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default/esmf.mk

cwd=$(pwd)

cesm_dir=/g/data/tm70/ds0092/CESM
bld_dir=/scratch/tm70/ds0092/cime/scratch/D_JRA_WD/bld
sharedlib_dir=${bld_dir}/intel/openmpi/nodebug/nothreads/nuopc


echo -e "Building data atm model"
echo -e "===================="
cd ${bld_dir}/atm/obj
make datm
ln -sf ${bld_dir}/atm/obj/libdatm.a ${bld_dir}/lib/libatm.a
cd ${cwd}
echo -e "====================\n"

echo -e "Building data rof model"
echo -e "===================="
cd ${bld_dir}/rof/obj
make drof
ln -sf ${bld_dir}/rof/obj/libdrof.a ${bld_dir}/lib/librof.a
cd ${cwd}
echo -e "====================\n"

if [ "$ACTIVE_OCN" = true ] ; then
    echo -e "Building mom6"
    echo -e "===================="
    echo -e "    Not implemented" && exit
else
    echo -e "Building data ocn model"
    echo -e "===================="
    # ln has annoying behaviour with target dirs
    ocn_obj=${bld_dir}/ocn/obj
    if [ -d ${ocn_obj} ] && [ ! -L ${ocn_obj} ]; then
        rm -r ${ocn_obj}
    fi
    ln -sf ${sharedlib_dir}/CDEPS/docn ${ocn_obj}
    cd ${ocn_obj}
    make docn
    ln -sf ${ocn_obj}/libdocn.a ${bld_dir}/lib/libocn.a
fi
cd ${cwd}
echo -e "====================\n"

echo -e "Building cice6"
echo -e "===================="
# Note, the generic CIME Makefile used here looks for xmlquery in 
# CASEROOT. However, it only uses this to query what the atm
# component is, which is not important to the ice build. So I think
# we can safely set CASEROOT=${cwd} and copy other files looked for
# CASEROOT to there (Depends.intel, Macros.make)
cd ${bld_dir}/ice/obj
cp ${cwd}/Filepath.cice6 ${bld_dir}/ice/obj/Filepath
make complib -j 8 COMP_NAME=cice COMPLIB=${bld_dir}/lib/libice.a -f ${cesm_dir}/cime/CIME/Tools/Makefile USER_CPPDEFS=" -Dncdf" CIME_MODEL=cesm  SMP=FALSE CASEROOT=${cwd} CASETOOLS=${cesm_dir}/cime/CIME/Tools CIMEROOT=${cesm_dir}/cime SRCROOT=${cesm_dir} COMP_INTERFACE="nuopc" COMPILER="intel" DEBUG="FALSE" EXEROOT=${bld_dir} INCROOT="${bld_dir}/lib/include" LIBROOT="${bld_dir}/lib" MACH="gadi" MPILIB="openmpi" NINST_VALUE="c1a1i1o1r1w1" OS="LINUX" PIO_VERSION=2 SHAREDLIBROOT=${bld_dir} SMP_PRESENT="FALSE" USE_ESMF_LIB="TRUE" USE_MOAB="FALSE" COMP_LND="slnd" USE_PETSC="FALSE"
cd ${cwd}
echo -e "====================\n"

# Build WW3
# ====================
echo -e "Building ww3"
echo -e "===================="
cd ${bld_dir}/wav/obj
cmake -DCASEROOT=${cwd} -DCIMEROOT=${cesm_dir}/cime -DCOMPILER="intel" -DLIBROOT=${bld_dir}/lib -DMACH="gadi" -DMPILIB="openmpi" -DNINST_VALUE="c1a1i1o1r1w1" -DOS="LINUX" -DCMAKE_Fortran_COMPILER_WORKS=1 -DCMAKE_INSTALL_PREFIX:PATH=/ -DLIBROOT=${bld_dir}/lib ${cesm_dir}/components/ww3dev/WW3/model/src
make install VERBOSE=1 DESTDIR=${bld_dir}
echo -e "====================\n"

exit

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
