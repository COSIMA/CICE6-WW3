#!/usr/bin/env bash

# Build a "D_JRA_WD" compset (CICE6-WW3-DOCN-DATM-DROF-SLND-SGLC). Mostly 
# just a learning exercise unpacking how the CIME build system fits together.
#
# These scripts assume that the shared libs have already been created by CIME.
# 
# To do the model builds, CIME uses cmake for some components and a monster
# do-it-all Makefile for others (see cime/CIME/Tools/Makefile). The Makefile
# expects a specific directory structure for the build.

set -e

ACTIVE_OCN=true

esmf_dir=/scratch/tm70/mrd599/esmf-8.3.0
. /etc/profile.d/modules.sh
module purge
module load openmpi intel-compiler intel-mkl netcdf pnetcdf python3-as-python
export NETCDF_PATH=/apps/netcdf/4.7.3
export PKG_CONFIG_PATH=/apps/netcdf/4.7.3/lib/pkgconfig:/apps/intel-ct/2022.1.0/mkl/lib/pkgconfig:/half-root/usr/lib64/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig:/apps/netcdf/4.7.3/lib/Intel/pkgconfig
export ESMFMKFILE=$esmf_dir/lib/libg/Linux.intel.x86_64_medium.openmpi.default/esmf.mk

cwd=$(pwd)

cesm_dir=/g/data/tm70/ds0092/CESM
bld_dir=/scratch/tm70/ds0092/cime/scratch/D_JRA_WD_mom/bld
sharedlib_dir=${bld_dir}/intel/openmpi/nodebug/nothreads/nuopc


echo -e "Building data atm model"
echo -e "===================="
cd ${bld_dir}/atm/obj
make datm  2>&1 | tee ${bld_dir}/atm.bldlog
ln -sf ${bld_dir}/atm/obj/libdatm.a ${bld_dir}/lib/libatm.a
cd ${cwd}
echo -e "====================\n"

echo -e "Building data rof model"
echo -e "===================="
cd ${bld_dir}/rof/obj
make drof  2>&1 | tee ${bld_dir}/rof.bldlog
ln -sf ${bld_dir}/rof/obj/libdrof.a ${bld_dir}/lib/librof.a
cd ${cwd}
echo -e "====================\n"

ocn_obj=${bld_dir}/ocn/obj
if [ "$ACTIVE_OCN" = true ] ; then
    echo -e "Building mom6"
    echo -e "===================="
    if [ -L ${ocn_obj} ]; then
        unlink ${ocn_obj}
    fi
    mkdir -p ${ocn_obj}/FMS
    
    cp ${cwd}/Filepath.fms ${ocn_obj}/FMS/Filepath
    make -f ${cesm_dir}/libraries/FMS/Makefile.cesm -C ${ocn_obj}/FMS CASEROOT=${cwd} USER_INCLDIR="-I${cesm_dir}/libraries/FMS/src/include -I${cesm_dir}/libraries/FMS/src/fms2_io/include -I${cesm_dir}/libraries/FMS/src/mpp/include" COMPLIB=${bld_dir}/lib/libfms.a CASETOOLS=${cesm_dir}/cime/CIME/Tools CIMEROOT=${cesm_dir}/cime COMP_INTERFACE="nuopc" COMPILER="intel" DEBUG="FALSE" EXEROOT=${bld_dir} INCROOT=${bld_dir}/lib/include LIBROOT=${bld_dir}/lib MACH="gadi" MPILIB="openmpi" NINST_VALUE="c1a1i1o1r1w1" OS="LINUX" SHAREDLIBROOT=${bld_dir} USE_ESMF_LIB="TRUE" BUILD_THREADED="FALSE"  2>&1 | tee ${bld_dir}/ocn.bldlog

    cd ${ocn_obj}
    cp ${cwd}/Filepath.mom6 ${ocn_obj}/Filepath
    make complib -j 8 COMP_NAME="mom" COMPLIB=${bld_dir}/lib/libocn.a -f ${cesm_dir}/cime/CIME/Tools/Makefile USER_INCLDIR="-I${cesm_dir}/libraries/FMS/src/include -I${cesm_dir}/libraries/FMS/src/mpp/include -I${bld_dir}/ocn/obj/FMS" CIME_MODEL="cesm" SMP="FALSE" CASEROOT=${cwd} CASETOOLS=${cesm_dir}/cime/CIME/Tools CIMEROOT=${cesm_dir}/cime SRCROOT=${cesm_dir} COMP_INTERFACE="nuopc" COMPILER="intel" DEBUG="FALSE" EXEROOT=${bld_dir} INCROOT=${bld_dir}/lib/include LIBROOT=${bld_dir}/lib MACH="gadi" MPILIB="openmpi" NINST_VALUE="c1a1i1o1r1w1" OS="LINUX" PIO_VERSION=2 SHAREDLIBROOT=${bld_dir} SMP_PRESENT="FALSE" USE_ESMF_LIB="TRUE" USE_MOAB="FALSE" COMP_LND="slnd" COMP_ATM="datm" USE_PETSC="FALSE"  2>&1 | tee -a ${bld_dir}/ocn.bldlog
    USE_FMS="TRUE"
else
    echo -e "Building data ocn model"
    echo -e "===================="
    # ln has annoying behaviour with target dirs
    if [ -d ${ocn_obj} ] && [ ! -L ${ocn_obj} ]; then
        rm -r ${ocn_obj}
    fi
    ln -sf ${sharedlib_dir}/CDEPS/docn ${ocn_obj}
    cd ${ocn_obj}
    make docn  2>&1 | tee ${bld_dir}/ocn.bldlog
    ln -sf ${ocn_obj}/libdocn.a ${bld_dir}/lib/libocn.a
    USE_FMS="FALSE"
fi
cd ${cwd}
echo -e "====================\n"

echo -e "Building cice6"
echo -e "===================="
cd ${bld_dir}/ice/obj
cp ${cwd}/Filepath.cice6 ${bld_dir}/ice/obj/Filepath
make complib -j 8 COMP_NAME=cice COMPLIB=${bld_dir}/lib/libice.a -f ${cesm_dir}/cime/CIME/Tools/Makefile USER_CPPDEFS=" -Dncdf" CIME_MODEL="cesm"  SMP="FALSE" CASEROOT=${cwd} CASETOOLS=${cesm_dir}/cime/CIME/Tools CIMEROOT=${cesm_dir}/cime SRCROOT=${cesm_dir} COMP_INTERFACE="nuopc" COMPILER="intel" DEBUG="FALSE" EXEROOT=${bld_dir} INCROOT=${bld_dir}/lib/include LIBROOT=${bld_dir}/lib MACH="gadi" MPILIB="openmpi" NINST_VALUE="c1a1i1o1r1w1" OS="LINUX" PIO_VERSION=2 SHAREDLIBROOT=${bld_dir} SMP_PRESENT="FALSE" USE_ESMF_LIB="TRUE" USE_MOAB="FALSE" COMP_LND="slnd" COMP_ATM="datm" USE_PETSC="FALSE"  2>&1 | tee ${bld_dir}/ice.bldlog
cd ${cwd}
echo -e "====================\n"

echo -e "Building ww3"
echo -e "===================="
cd ${bld_dir}/wav/obj
cmake -DCASEROOT=${cwd} -DCIMEROOT=${cesm_dir}/cime -DCOMPILER="intel" -DLIBROOT=${bld_dir}/lib -DMACH="gadi" -DMPILIB="openmpi" -DNINST_VALUE="c1a1i1o1r1w1" -DOS="LINUX" -DCMAKE_Fortran_COMPILER_WORKS=1 -DCMAKE_INSTALL_PREFIX:PATH=/ -DLIBROOT=${bld_dir}/lib ${cesm_dir}/components/ww3dev/WW3/model/src  2>&1 | tee ${bld_dir}/wav.bldlog
make install VERBOSE=1 DESTDIR=${bld_dir}  2>&1 | tee -a ${bld_dir}/wav.bldlog
cd ${cwd}
echo -e "====================\n"

echo -e "Building CMEPS executable"
echo -e "===================="
cd ${bld_dir}/cpl/obj
cp ${cwd}/Filepath.cmeps ${bld_dir}/cpl/obj/Filepath
make exec_se -j 8 EXEC_SE=${bld_dir}/cesm.exe COMP_NAME="driver" CIME_MODEL="cesm"  SMP="FALSE" CASEROOT=${cwd} CASETOOLS=${cesm_dir}/cime/CIME/Tools CIMEROOT=${cesm_dir}/cime SRCROOT=${cesm_dir} COMP_INTERFACE="nuopc" COMPILER="intel" DEBUG="FALSE" EXEROOT=${bld_dir} INCROOT=${bld_dir}/lib/include LIBROOT=${bld_dir}/lib MACH="gadi" MPILIB="openmpi" NINST_VALUE="c1a1i1o1r1w1" OS="LINUX" PIO_VERSION=2 SHAREDLIBROOT=${bld_dir} SMP_PRESENT="FALSE" USE_ESMF_LIB="TRUE" USE_MOAB="FALSE" COMP_LND="slnd" COMP_ATM="datm" USE_PETSC="FALSE" USE_FMS=${USE_FMS} LND_PRESENT="FALSE" GLC_PRESENT="FALSE" ESP_PRESENT="FALSE" IAC_PRESENT="FALSE" -f ${cesm_dir}/cime/CIME/Tools/Makefile  2>&1 | tee ${bld_dir}/cesm.bldlog
cd ${cwd}
echo -e "====================\n"
