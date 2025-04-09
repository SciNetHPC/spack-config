#!/bin/sh

# clear out CCEnv
clearLmod --quiet
unset $(env | grep -Eo '^__LMOD_[^=]+')
unset FPATH MANPATH

# setup spack
. /scinet/spack/v0.23/share/spack/setup-env.sh
export SPACK_DISABLE_LOCAL_CONFIG=true

if [ $# -ne 0 ]; then
    # activate environment
    spack env activate "$1"

    # lmod
    . $(spack location -i lmod)/lmod/lmod/init/bash
    module use "$SPACK_ROOT/var/spack/environments/$1/modules/Core"
fi
