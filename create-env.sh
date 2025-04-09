#!/bin/bash
set -eu -o pipefail
ulimit -t unlimited
umask 0022

env=$1
spack env create "$env" ./spack.yaml
spack env activate "$env"

# use OS for basic and/or sensitive packages
# https://github.com/NERSC/spack-infrastructure/blob/main/spack-externals.md
spack external find --not-buildable \
    coreutils \
    curl \
    diffutils \
    findutils \
    git \
    openssh \
    openssl \
    rsync \
    sed \
    slurm \
    tar
spack external find bzip2 cpio dos2unix file gnupg ncurses python ruby which xz zip zlib
spack external find # packages tagged with the "build-tools" or "core-packages"

# install basics
spack install --fail-fast

# compilers
core_gcc='%gcc@11.5.0'
for compiler in gcc@14; do
    spack install --add $compiler $core_gcc
    spack compiler find "$(spack location -i $compiler)"
    # XXX:TBD: compiler tests
done

# mpi
for compiler in %aocc@5.0 ; do # %gcc@14; do
    spack add openmpi@4 $compiler +cxx +legacylaunchers
    #spack add openmpi@5 $compiler
done
spack install --fail-fast

spack add wrf %aocc build_type=dm+sm ^openmpi
spack install

# regenerate module files
spack module lmod refresh --delete-tree --yes-to-all

