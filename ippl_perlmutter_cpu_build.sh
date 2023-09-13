#!/bin/bash

set -x
set -e

#ml load cray-mpich
#ml load cmake/3.24.3
#ml load cudatoolkit/12.0
#cmake --version
#ml load mpich/4.1.1
ml rm cray-mpich
export CPATH=/global/homes/s/smuralik/IPPL/mpich/gnu/mpich/4.1.1/include:$CPATH
export PATH=/global/homes/s/smuralik/IPPL/mpich/gnu/mpich/4.1.1/bin:$PATH
export LD_LIBRARY_PATH=/global/homes/s/smuralik/IPPL/mpich/gnu/mpich/4.1.1/lib:$LD_LIBRARY_PATH


# 3 steps
# 1. Build Kokkos
step_1=true
# 2. Build Heffte
step_2=true
# 3. Build ippl by using the Kokkos and Heffte builds
step_3=true

HOME_DIR=$(pwd)
threads=8
export CRAYPE_LINK_TYPE=dynamic
#export MPICH_GPU_SUPPORT_ENABLED=1

# Step 1 - Kokkos
KOKKOS_VER=4.1.00
KOKKOS_SRC=${HOME_DIR}/kokkos_src_${KOKKOS_VER}
KOKKOS_INSTALL_PREFIX="${HOME_DIR}/kokkos/${KOKKOS_VER}"

if [ $step_1 = true ]; then

    if [ ! -d ${KOKKOS_SRC} ]; then
    git clone -b ${KOKKOS_VER} https://github.com/kokkos/kokkos.git ${KOKKOS_SRC}
    fi
    cd ${KOKKOS_SRC}

    mkdir build && cd build
    cmake \
        -DCMAKE_INSTALL_PREFIX=${KOKKOS_INSTALL_PREFIX} \
	-DCMAKE_CXX_COMPILER="$(which gcc)" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_EXTENSIONS=OFF \
        -DCMAKE_CXX_STANDARD=20 \
        -DKokkos_ENABLE_SERIAL=OFF \
        -DKokkos_ENABLE_OPENMP=ON \
        -DKokkos_ENABLE_CUDA=OFF \
        -DKokkos_ARCH_ZEN2=ON \
        -DKokkos_ENABLE_TESTS=OFF \
        ${KOKKOS_SRC}

    make -j$threads
    make install -j$threads
    cd ${HOME_DIR}
    rm -rf ${KOKKOS_SRC}
fi

#Step 2 - Heffte
HEFFTE_VER=2.3.0
HEFFTE_SRC=${HOME_DIR}/heffte_${HEFFTE_VER}
HEFFTE_INSTALL_PREFIX="${HOME_DIR}/heffte_install/${HEFFTE_VER}"

if [ $step_2 = true ]; then

    if [ ! -d ${HEFFTE_SRC} ]; then
    git clone https://github.com/icl-utk-edu/heffte.git ${HEFFTE_SRC}
    fi
    cd ${HEFFTE_SRC}
    #git checkout f7e72ad
    #git checkout tags/v${HEFFTE_VER}

    # The cuda_add_cufft_to_target is now deprecated and is causing issues in finding cufft
    sed -i 's/cuda_add_cufft_to_target/#cuda_add_cufft_to_target/' CMakeLists.txt

    if [ -d build ]; then
        rm -rf build
    fi
    mkdir build && cd build
    cmake \
    -DCMAKE_CXX_COMPILER=mpicxx \
    -DCMAKE_INSTALL_PREFIX=${HEFFTE_INSTALL_PREFIX} \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_CXX_FLAGS="-I/global/homes/s/smuralik/IPPL/mpich/gnu/mpich/4.1.1/include" \
    -DCMAKE_CXX_STANDARD=20 \
    -S ${HEFFTE_SRC}

    make -j$threads
    make install -j$threads
    cd ${HOME_DIR}
    rm -rf ${HEFFTE_SRC}
fi

# Step 3 - ippl
ippl_SRC=${HOME_DIR}/ippl
if [ $step_3 = true ]; then

    if [ ! -d ${ippl_SRC} ]; then
        #git clone https://github.com/IPPL-framework/ippl.git ${ippl_SRC}
    	git clone https://github.com/Arc676/ippl.git
    fi

    cd ${ippl_SRC}

    #git checkout master
    git checkout fixes-and-cleanup
    if [ ! -d build ]; then
        mkdir -p build
    fi
    cd build
    rm -rf *


    cmake \
        -DCMAKE_CXX_EXTENSIONS=OFF \
        -DMPI_C_COMPILER=mpicc \
        -DMPI_CXX_COMPILER=mpicxx \
        -DENABLE_TESTS=ON -DENABLE_UNIT_TESTS=OFF \
        -DENABLE_FFT=ON \
        -DENABLE_SOLVERS=ON \
        -DENABLE_ALPINE=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DKokkos_DIR=${KOKKOS_INSTALL_PREFIX}/lib64/cmake/Kokkos \
        -DHeffte_DIR=${HEFFTE_INSTALL_PREFIX}/lib/cmake/Heffte \
        ${ippl_SRC}

    cd alpine
    make -j$threads LandauDamping
fi
