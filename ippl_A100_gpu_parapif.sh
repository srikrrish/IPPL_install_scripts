#!/bin/bash

# 4 steps
# 1. Build Kokkos
step_1=true
# 2. Build Heffte
step_2=true
# 3. Build FINUFFT
step_3=true
# 4. Build ippl by using the Kokkos, Heffte and FINUFFT builds
step_4=true


HOME_DIR=$(pwd)
threads=8

# Step 1 - Kokkos
KOKKOS_VER=4.2.00
KOKKOS_SRC=${HOME_DIR}/kokkos_${KOKKOS_VER}
KOKKOS_INSTALL_PREFIX="${HOME_DIR}/kokkos_4_2_00_install_2024_psmpi_toolchain/${KOKKOS_VER}"

if [ $step_1 = true ]; then

    if [ ! -d ${KOKKOS_SRC} ]; then
    git clone https://github.com/kokkos/kokkos.git ${KOKKOS_SRC}
    fi
    cd ${KOKKOS_SRC}
    git checkout tags/${KOKKOS_VER}

    export NVCC_WRAPPER_DEFAULT_COMPILER="$(which gcc)"

    mkdir -p build_psmpi && cd build_psmpi
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
HEFFTE_VER=2.4.0
HEFFTE_SRC=${HOME_DIR}/heffte_${HEFFTE_VER}
HEFFTE_INSTALL_PREFIX="${HOME_DIR}/heffte_2_4_0_install_2024_psmpi_toolchain/${HEFFTE_VER}"

if [ $step_2 = true ]; then

    if [ ! -d ${HEFFTE_SRC} ]; then
    git clone https://github.com/icl-utk-edu/heffte.git ${HEFFTE_SRC}
    fi
    cd ${HEFFTE_SRC}
    git checkout tags/v${HEFFTE_VER}
    #git checkout 029367d


    mkdir -p build_psmpi && cd build_psmpi
    rm -rf *

    cmake \
        -DCMAKE_INSTALL_PREFIX=${HEFFTE_INSTALL_PREFIX} \
        -DMPI_CXX_COMPILER="$(which mpicxx)" \
        -DCMAKE_BUILD_TYPE=Release \
        -DHeffte_ENABLE_CUDA=ON \
        -DCUDA_TOOLKIT_ROOT_DIR="${CUDA_HOME}" \
        -DCMAKE_CUDA_ARCHITECTURES=80 \
        ${HEFFTE_SRC}

    make -j$threads
    make install -j$threads
    cd ${HOME_DIR}
fi

#Step 3 - FINUFFT
FINUFFT_VER=2.2.0
FINUFFT_SRC=${HOME_DIR}/finufft_${FINUFFT_VER}
FINUFFT_INSTALL_PREFIX="${HOME_DIR}/finufft_2_2_0_install_2024_psmpi_toolchain/${FINUFFT_VER}"

if [ $step_3 = true ]; then

    if [ ! -d ${FINUFFT_SRC} ]; then
    git clone https://github.com/flatironinstitute/finufft.git ${FINUFFT_SRC}
    fi
    cd ${FINUFFT_SRC}
    #git checkout tags/v${FINUFFT_VER}
    git checkout 871bb8fe


    mkdir -p build_psmpi && cd build_psmpi
    rm -rf *

    cmake \
        -DCMAKE_INSTALL_PREFIX=${FINUFFT_INSTALL_PREFIX} \
        -DFINUFFT_USE_CUDA=ON \
        -DFINUFFT_USE_CPU=OFF \
        -DCMAKE_CUDA_ARCHITECTURES=80 \
        ${FINUFFT_SRC}

    #If we do make install or cmake --target install then finufft_errors.h is not
    #being copied to the include directory. That's why doing it like this
    cmake --build . -j$threads
    cp libcufinufft.so ../lib
    cd ${HOME_DIR}
fi

export CUFINUFFT_DIR=${FINUFFT_SRC}


# Step 3 - ippl
ippl_SRC=${HOME_DIR}/ippl

if [ $step_4 = true ]; then

    if [ ! -d ${ippl_SRC} ]; then
        git clone https://github.com/srikrrish/ippl.git ${ippl_SRC}
    fi

    cd ${ippl_SRC}
    git checkout tags/parapif-paper

    export NVCC_WRAPPER_DEFAULT_COMPILER="$(which gcc)"

    if [ ! -d build_with_kokkos_4_2_00_heffte_2_4_0_finufft_2_2_0_psmpi_2024 ]; then
    mkdir -p build_with_kokkos_4_2_00_heffte_2_4_0_finufft_2_2_0_psmpi_2024
    fi
    cd build_with_kokkos_4_2_00_heffte_2_4_0_finufft_2_2_0_psmpi_2024

    rm -rf *
    echo ${ippl_SRC}

    cmake \
        -DCMAKE_CXX_EXTENSIONS=OFF \
        -DCMAKE_CXX_COMPILER=${KOKKOS_INSTALL_PREFIX}/bin/nvcc_wrapper \
        -DENABLE_TESTS=ON \
        -DENABLE_UNIT_TESTS=OFF \
        -DENABLE_FFT=ON \
        -DENABLE_NUFFT=ON \
        -DENABLE_SOLVERS=ON \
        -DENABLE_ALPINE=ON \
        -DCMAKE_CXX_FLAGS="--expt-extended-lambda -arch=sm_80" \
        -DCMAKE_BUILD_TYPE=Release \
        -DKokkos_DIR=${KOKKOS_INSTALL_PREFIX}/lib64/cmake/Kokkos \
        -DHeffte_DIR=${HEFFTE_INSTALL_PREFIX}/lib/cmake/Heffte \
        ${ippl_SRC}

    cd alpine/PinT
    make -j$threads
    mkdir data
    cd ../ElectrostaticPIF
    make -j$threads
    mkdir data
fi
