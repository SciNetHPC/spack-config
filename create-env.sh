#!/bin/bash
set -eu -o pipefail
ulimit -t unlimited
umask 0022

env=$1
spack env create "$env" ./spack.yaml
spack env activate "$env"

spack repo add repos/scinet
spack config add "config:template_dirs:$PWD/templates"

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
spack external find bzip2 cpio dos2unix file gnupg ncurses which xz zip zlib
spack external find # packages tagged with the "build-tools" or "core-packages"

# XXX:HACK try to prevent externals concretizing w/ multiple compilers
# https://github.com/spack/spack/issues/49697
core_gcc='%gcc@11.5.0'
apptainer exec docker://mikefarah/yq yq --inplace \
    "with(.spack.packages[]|select(.buildable==\"false\"); .require=\"%gcc@11.5.0\")" \
    "$SPACK_ROOT/var/spack/environments/$env/spack.yaml"

# install basics
spack install --fail-fast

# compilers
aocc="aocc@5.0"
compilers=( "$aocc" )
for compiler in "${compilers[@]}"; do
    spack install --add $compiler $core_gcc
    spack compiler find "$(spack location -i $compiler)"
    # XXX:TBD: compiler tests

    compiler="%$compiler"

    # mpi
    #spack install --add openmpi@4 $compiler +cxx +legacylaunchers
    spack install --add openmpi@5 $compiler
    spack install --add mvapich@4 $compiler
done

aocc="%$aocc"
mpi="^openmpi@5 $aocc"
for pkg in amdblis amdlibflame amdscalapack eigen gsl openblas stream; do
    spack add $pkg $aocc
done
for pkg in amdfftw fftw hdf5 hpcg netcdf-c netcdf-fortran osu-micro-benchmarks parallel-netcdf wrf; do
    spack add $pkg $aocc $mpi
done
spack add lammps $aocc ^amdfftw $aocc $mpi
spack add hpl $aocc ^amdblis $aocc $mpi
spack install --fail-fast

# regenerate module files
spack module lmod refresh --delete-tree --yes-to-all

