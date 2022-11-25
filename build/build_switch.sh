#!/usr/bin/env bash

# Can we just switch out the ocn component when we build the executable?

set -e

esmf_dir=/scratch/tm70/mrd599/esmf-8.3.0
. /etc/profile.d/modules.sh
module purge
module load openmpi intel-compiler intel-mkl netcdf pnetcdf python3-as-python
export NETCDF_PATH=/apps/netcdf/4.7.3
export PKG_CONFIG_PATH=/apps/netcdf/4.7.3/lib/pkgconfig:/apps/intel-ct/2022.1.0/mkl/lib/pkgconfig:/half-root/usr/lib64/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig
export ESMFMKFILE=$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default/esmf.mk

cwd=$(pwd)

cesm_dir=/g/data/tm70/ds0092/CESM

GMOM_bld_dir=/scratch/tm70/ds0092/cime/scratch/GMOM_JRA_WD/bld
D_bld_dir=/scratch/tm70/ds0092/cime/scratch/D_JRA_WD/bld

sharedlib_dir=${GMOM_bld_dir}/intel/openmpi/nodebug/nothreads/nuopc

echo -e "Building data ocn model"
echo -e "===================="
# ln has annoying behaviour with target dirs
ocn_obj=${D_bld_dir}/ocn/obj
if [ -d ${ocn_obj} ] && [ ! -L ${ocn_obj} ]; then
    rm -r ${ocn_obj}
fi
ln -sf ${sharedlib_dir}/CDEPS/docn ${ocn_obj}
cd ${ocn_obj}
make docn
ln -sf ${ocn_obj}/libdocn.a ${D_bld_dir}/lib/libocn.a
echo -e "====================\n"

# Compile and link executable manually
echo -e "Building CMEPS executable"
echo -e "===================="
cd ${D_bld_dir}/cpl/obj
flags="-I. -I${sharedlib_dir}/CDEPS/fox/include -I${sharedlib_dir}/CDEPS/dshr -I${sharedlib_dir}/include -I${sharedlib_dir}/nuopc/esmf/c1a1i1o1r1w1/include -I/apps/netcdf/4.7.3/include -I${GMOM_bld_dir}/atm/obj -I${GMOM_bld_dir}/ice/obj -I${D_bld_dir}/ocn/obj -I${GMOM_bld_dir}/glc/obj -I${GMOM_bld_dir}/rof/obj -I${GMOM_bld_dir}/wav/obj -I${GMOM_bld_dir}/esp/obj -I${GMOM_bld_dir}/lnd/obj -I. -I${cesm_dir}/components/cmeps/mediator -I${cesm_dir}/components/cmeps/cesm/flux_atmocn -I${cesm_dir}/comonents/cmeps/cesm/driver -I${GMOM_bld_dir}/lib/include -qno-opt-dynamic-align  -convert big_endian -assume byterecl -ftz -traceback -assume realloc_lhs -fp-model source -O2 -debug minimal -I${esmf_dir}/mod/modg/Linux.intel.x86_64_medium.openmpi.default -I${esmf_dir}/src/include -I/apps/netcdf/4.7.3/include  -DLINUX  -DCESMCOUPLED -DFORTRANUNDERSCORE -DCPRINTEL -DNDEBUG -DUSE_ESMF_LIB -DHAVE_MPI -DNUOPC_INTERFACE -DPIO2 -DHAVE_SLASHPROC -DESMF_VERSION_MAJOR=8 -DESMF_VERSION_MINOR=3 -DATM_PRESENT -DICE_PRESENT -DOCN_PRESENT -DROF_PRESENT -DWAV_PRESENT -DMED_PRESENT -DPIO2 -free -DUSE_CONTIGUOUS="

# The order of these is important it would seem
cmeps_src_files=( cesm/driver/esm_time_mod.F90 mediator/med_kind_mod.F90 cesm/flux_atmocn/shr_flux_mod.F90 cesm/driver/t_driver_timers_mod.F90 cesm/driver/util.F90 mediator/med_constants_mod.F90 mediator/med_utils_mod.F90 mediator/med_methods_mod.F90 mediator/med_internalstate_mod.F90 mediator/med_phases_ocnalb_mod.F90 mediator/med_io_mod.F90 mediator/med_time_mod.F90 mediator/esmFlds.F90 mediator/med_phases_profile_mod.F90 mediator/med_diag_mod.F90 mediator/med_map_mod.F90 mediator/med_merge_mod.F90 mediator/esmFldsExchange_cesm_mod.F90 mediator/esmFldsExchange_nems_mod.F90 mediator/esmFldsExchange_hafs_mod.F90 mediator/med_phases_history_mod.F90 mediator/med_phases_prep_lnd_mod.F90 mediator/med_phases_prep_ice_mod.F90 mediator/med_fraction_mod.F90 mediator/med_phases_prep_rof_mod.F90 mediator/med_phases_prep_wav_mod.F90 mediator/med_phases_aofluxes_mod.F90 mediator/med_phases_post_wav_mod.F90 mediator/med_phases_post_rof_mod.F90 mediator/med_phases_post_glc_mod.F90 mediator/med_phases_post_atm_mod.F90 mediator/med_phases_prep_glc_mod.F90 mediator/med_phases_post_ice_mod.F90 mediator/med_phases_post_lnd_mod.F90 mediator/med_phases_restart_mod.F90 mediator/med_phases_post_ocn_mod.F90 mediator/med_phases_prep_atm_mod.F90 mediator/med_phases_prep_ocn_mod.F90 mediator/med.F90 cesm/driver/esm.F90 cesm/driver/ensemble_driver.F90 cesm/driver/esmApp.F90 )

object_files=()
for file in ${cmeps_src_files[@]}; do
    mpif90 -c $flags ${cesm_dir}/components/cmeps/$file
    bname=$(basename $file)
    object_files+=( "./${bname%.F90}.o" )
done

mpif90 -o ${D_bld_dir}/cesm.exe ${object_files[@]} -L${GMOM_bld_dir}/lib/ -latm -lice -lrof -lwav -L${D_bld_dir}/lib/ -locn -L${sharedlib_dir}/CDEPS/dshr -ldshr -L${sharedlib_dir}/CDEPS/streams -lstreams -L${sharedlib_dir}/nuopc/esmf/c1a1i1o1r1w1/lib -lcsm_share -L${sharedlib_dir}/lib -lpiof -lpioc -lgptl -lmct -lmpeu -mkl=cluster -mkl=cluster -lnetcdf -lnetcdff -lmkl_intel_lp64 -lmkl_core -lmkl_intel_thread -liomp5 -lm -L${sharedlib_dir}/CDEPS/fox/lib -lFoX_dom -lFoX_sax -lFoX_utils -lFoX_fsys -lFoX_wxml -lFoX_common -lFoX_fsys -L${esmf_dir}/lib/libg/Linux.intel.x86_64_medium.openmpi.default -Wl,-rpath,${esmf_dir}/lib/libg/Linux.intel.x86_64_medium.openmpi.default -lesmf -lmpi_cxx -cxxlib -lrt -ldl -mkl -lnetcdff -lnetcdf -lpioc -L${esmf_dir}/lib/libg/Linux.intel.x86_64_medium.openmpi.default -L/apps/netcdf/4.7.3/lib

cd ${cwd}
echo -e "===================="
