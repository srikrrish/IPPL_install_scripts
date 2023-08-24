#!/bin/bash

year=2022

#ml Stages/${year}
#ml GCC
#ml OpenMPI
#ml CMake

# 3 steps
# 1. Build Kokkos
step_1=true
# 2. Build Heffte
step_2=true
# 3. Build ippl by using the Kokkos and Heffte builds
step_3=true


HOME_DIR=$(pwd)
threads=16

# Step 1 - Kokkos
KOKKOS_VER=4.1.00
KOKKOS_SRC=${HOME_DIR}/kokkos_${KOKKOS_VER}
KOKKOS_INSTALL_PREFIX="${HOME_DIR}/kokkos_install_${year}/${KOKKOS_VER}"

if [ $step_1 = true ]; then

    if [ ! -d ${KOKKOS_SRC} ]; then
    git clone https://github.com/kokkos/kokkos.git ${KOKKOS_SRC}
    fi
    cd ${KOKKOS_SRC}
    git checkout tags/${KOKKOS_VER}

    export NVCC_WRAPPER_DEFAULT_COMPILER="$(which gcc)"

    mkdir -p build && cd build
    rm -rf *

    cmake \
        -DCMAKE_INSTALL_PREFIX=${KOKKOS_INSTALL_PREFIX} \
        -DCMAKE_CXX_COMPILER="${KOKKOS_SRC}/bin/nvcc_wrapper" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_EXTENSIONS=OFF \
        -DCMAKE_CXX_STANDARD=17 \
        -DKokkos_ENABLE_SERIAL=ON \
        -DKokkos_ARCH_AMPERE80=ON \
        -DKokkos_ENABLE_OPENMP=OFF \
        -DKokkos_ENABLE_CUDA=ON \
        -DKokkos_ENABLE_CUDA_LAMBDA=ON \
        -DKokkos_ENABLE_CUDA_UVM=OFF \
        ${KOKKOS_SRC}

    make -j$threads
    make install -j$threads
    cd ${HOME_DIR}
fi

#Step 2 - Heffte
HEFFTE_VER=2.3.0
HEFFTE_SRC=${HOME_DIR}/heffte_${HEFFTE_VER}
HEFFTE_INSTALL_PREFIX="${HOME_DIR}/heffte_install_${year}/${HEFFTE_VER}"


if [ $step_2 = true ]; then

    if [ ! -d ${HEFFTE_SRC} ]; then
    git clone https://github.com/icl-utk-edu/heffte.git ${HEFFTE_SRC}
    fi
    cd ${HEFFTE_SRC}
    # git checkout tags/v${HEFFTE_VER}
    #git checkout 029367d
    git checkout f7e72ad


    mkdir -p build && cd build
    rm -rf *

    cmake \
        -DCMAKE_INSTALL_PREFIX=${HEFFTE_INSTALL_PREFIX} \
        -DMPI_CXX_COMPILER="$(which mpicxx)" \
        -DCMAKE_BUILD_TYPE=Release \
        -DHeffte_ENABLE_CUDA=ON \
        -DCUDA_TOOLKIT_ROOT_DIR="${CUDA_HOME}" \
        ${HEFFTE_SRC}

    make -j$threads
    make install -j$threads
    cd ${HOME_DIR}
fi

# Step 3 - ippl
ippl_SRC=${HOME_DIR}/ippl

if [ $step_3 = true ]; then

    if [ ! -d ${ippl_SRC} ]; then
        git clone https://gitlab.psi.ch/OPAL/Libraries/ippl.git ${ippl_SRC}
    fi

    cd ${ippl_SRC}
    git checkout tags/IPPL-3.0.1

    export NVCC_WRAPPER_DEFAULT_COMPILER="$(which gcc)"

    if [ ! -d build_${year}_gcc ]; then
      mkdir -p build_${year}_gcc
    fi
    cd build_${year}_gcc

    rm -rf *
    echo ${ippl_SRC}

    cmake \
        -DCMAKE_CXX_EXTENSIONS=OFF \
        -DCMAKE_CXX_COMPILER=${KOKKOS_INSTALL_PREFIX}/bin/nvcc_wrapper \
        -DENABLE_TESTS=ON \
        -DENABLE_UNIT_TESTS=OFF \
        -DENABLE_FFT=ON \
        -DENABLE_SOLVERS=ON \
        -DENABLE_ALPINE=ON \
        -DCMAKE_CXX_FLAGS="--expt-extended-lambda -arch=sm_80" \
        -DCMAKE_BUILD_TYPE=Release \
        -DKokkos_DIR=${KOKKOS_INSTALL_PREFIX}/lib64/cmake/Kokkos \
        -DHeffte_DIR=${HEFFTE_INSTALL_PREFIX}/lib/cmake/Heffte \
        ${ippl_SRC}

    #make -j8
    cd alpine
    make -j$threads PenningTrap
    mkdir data
fi
