#!/bin/bash
set -eu -o pipefail
ulimit -t unlimited
umask 0022

env=$1
spack env create "$env" ./spack.yaml
spack env activate "$env"

spack repo add repos/scinet

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
spack_yaml="$SPACK_ROOT/var/spack/environments/$env/spack.yaml"
yq="apptainer exec docker://mikefarah/yq yq"
$yq --inplace "with(.spack.packages[]|select(.externals); .require=\"$core_gcc\")" "$spack_yaml"

# don't create lmod modules for externals
$yq --inplace '.spack.modules.default.lmod.exclude += [(.spack.packages[]|select(.externals)|.externals[0].spec)]' "$spack_yaml"

# install basics
spack install --fail-fast

have_nvidia_gpus=false
if [[ -e /dev/nvidia0 ]]; then
    have_nvidia_gpus=true

    # this will be ignored if a package uses 'prefer:' in spack.yaml,
    # so don't do that
    spack config add "packages:all:prefer:+cuda cuda_arch=90"

    spack add cuda $core_gcc
fi

arch=$(spack arch)
target=$(spack arch --target)

# compilers
aocc="aocc@5.0"
gcc="gcc@14.2.0"
if $have_nvidia_gpus; then
    compilers=( "$gcc" )
else
    compilers=( "$aocc" )
fi
for compiler in "${compilers[@]}"; do
    spack install --add $compiler $core_gcc
    spack compiler find "$(spack location -i $compiler)"
    # XXX:TBD: compiler tests

    compiler="%$compiler"
    case $target in
    zen5)
        compiler+=" arch=$arch"
        ;;
    esac

    # mpi
    spack add openmpi@4 $compiler +cxx +legacylaunchers
    spack add openmpi@5 $compiler
    spack add mvapich@4 $compiler
    spack install --fail-fast
done

if $have_nvidia_gpus; then
    compiler="%$gcc"
else
    compiler="%$aocc arch=$arch"
fi
mpi="^openmpi@5 $compiler"
for pkg in amdblis amdlibflame eigen gsl openblas py-numpy stream; do
    spack add $pkg $compiler
done
for pkg in amdfftw fftw hdf5 osu-micro-benchmarks py-h5py py-mpi4py; do
    spack add $pkg $compiler $mpi
done
spack add lammps $compiler ^amdfftw $compiler $mpi
#spack add namd $compiler fftw=amdfftw
#spack add nekrs $compiler $mpi
if $have_nvidia_gpus; then
    # gpu node
    spack add gromacs $compiler ^amdfftw $compiler
    for pkg in py-torch; do
        spack add $pkg $compiler $mpi
    done
else
    # cpu node
    for pkg in amdscalapack hpcg netcdf-c netcdf-fortran parallel-netcdf quantum-espresso wrf; do
        spack add $pkg $compiler $mpi
    done
    spack add hpl $compiler ^amdblis $compiler $mpi
    spack add hpl $compiler ^openblas $compiler $mpi
fi
spack install --fail-fast

# regenerate module files
spack module lmod refresh --delete-tree --yes-to-all

