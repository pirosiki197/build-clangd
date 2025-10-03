#!/usr/bin/env bash
#
# build-clangd.sh
#
# This script builds GCC and then uses it to build LLVM/Clangd from source.
# It is designed for older environments like CentOS 7 where the system compiler is outdated.
# It also collects all relevant license files and places them in the installation directory.
#

# Stop on any error
set -eu

# --- Configuration ---
# Installation destination. All final files will be placed here.
readonly PREFIX="${HOME}/.local"

# Temporary directories for the build process.
readonly _build_dir="${HOME}/build"

# Directory to store license files.
readonly LICENSE_DIR="${PREFIX}/share/licenses/clangd-stack"


# --- Build Functions ---

function build_gmp() {
    echo "--- 1/5: Building GMP ---"
    cd /tmp
    curl -L https://gcc.gnu.org/pub/gcc/infrastructure/gmp-6.2.1.tar.bz2 | tar -xj
    cd gmp-6.2.1

    # Collect license
    cp COPYING "${LICENSE_DIR}/gmp-COPYING"

    ./configure --prefix="${PREFIX}" --disable-shared --enable-static
    make -j"$(nproc)"
    make install
}

function build_mpfr() {
    echo "--- 2/5: Building MPFR ---"
    cd /tmp
    curl -L https://gcc.gnu.org/pub/gcc/infrastructure/mpfr-4.1.0.tar.bz2 | tar -xj
    cd mpfr-4.1.0

    # Collect license
    cp COPYING "${LICENSE_DIR}/mpfr-COPYING"

    ./configure --prefix="${PREFIX}" --with-gmp="${PREFIX}" --disable-shared --enable-static
    make -j"$(nproc)"
    make install
}

function build_mpc() {
    echo "--- 3/5: Building MPC ---"
    cd /tmp
    curl -L https://gcc.gnu.org/pub/gcc/infrastructure/mpc-1.2.1.tar.gz | tar -xz
    cd mpc-1.2.1

    # Collect license
    cp COPYING "${LICENSE_DIR}/mpc-COPYING"

    ./configure --prefix="${PREFIX}" --with-gmp="${PREFIX}" --with-mpfr="${PREFIX}" --disable-shared --enable-static
    make -j"$(nproc)"
    make install
}

function build_gcc() {
    echo "--- 4/5: Building GCC ---"
    cd /tmp
    curl -L https://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-12.2.0/gcc-12.2.0.tar.xz | tar -xJ
    cd gcc-12.2.0

    # Collect licenses
    cp COPYING "${LICENSE_DIR}/gcc-COPYING"
    cp COPYING.RUNTIME "${LICENSE_DIR}/gcc-COPYING.RUNTIME"
    cp COPYING.LIB "${LICENSE_DIR}/gcc-COPYING.LIB"

    mkdir _build && cd _build
    ../configure --prefix="${PREFIX}" --with-gmp="${PREFIX}" --with-mpfr="${PREFIX}" --with-mpc="${PREFIX}" \
        --disable-multilib --enable-languages=c,c++
    make -j"$(nproc)"
    make install
}

function build_llvm() {
    echo "--- 5/5: Building LLVM/Clangd ---"
    cd "${_build_dir}"
    curl -L https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.0/llvm-project-15.0.0.src.tar.xz | tar -xJ
    cd llvm-project-15.0.0.src

    # Collect license
    cp llvm/LICENSE.TXT "${LICENSE_DIR}/llvm-LICENSE.TXT"

    mkdir _build && cd _build

    # Use the newly built GCC to compile LLVM
    CC="${PREFIX}/bin/gcc" CXX="${PREFIX}/bin/g++" \
    cmake ../llvm \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
        -DLLVM_ENABLE_PROJECTS='clang;clang-tools-extra'

    make -j"$(nproc)" || make
    make install
}

# --- Main Execution ---
function main() {
    echo "Starting the build process for clangd."
    echo "Installation prefix: ${PREFIX}"

    # Create all necessary directories
    mkdir -p "${PREFIX}" "${_build_dir}" "${LICENSE_DIR}"

    # Set up environment variables for the build process
    export PATH="${PREFIX}/bin:${PATH}"
    export LD_LIBRARY_PATH="${PREFIX}/lib:${PREFIX}/lib64"
    export LD_RUN_PATH="${PREFIX}/lib:${PREFIX}/lib64"
    export LDFLAGS="-L${PREFIX}/lib -L${PREFIX}/lib64"

    # Run build functions in order of dependency
    build_gmp
    build_mpfr
    build_mpc
    build_gcc
    build_llvm

    # Clean up temporary build directories
    echo "Cleaning up build directories..."
    rm -rf "${_build_dir:?}"/*

    echo ""
    echo "✅ Success! clangd and its dependencies have been installed to ${PREFIX}"
    echo "License files have been collected in ${LICENSE_DIR}"
    echo "To use it, add the following lines to your ~/.bashrc or ~/.zshrc and restart your shell:"
    echo "export PATH=\"${PREFIX}/bin:\$PATH\""
    echo "export LD_LIBRARY_PATH=\"${PREFIX}/lib64:${PREFIX}/lib:\$LD_LIBRARY_PATH\""
}

# Run the main function
main
