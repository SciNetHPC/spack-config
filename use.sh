#!/bin/sh
# shellcheck disable=SC1091

unset BASH_ENV

# clear out CCEnv
# originally we used `clearLmod --quiet`, but that doesn't work in scripts
module --force purge
eval "$("$LMOD_DIR/clearLMOD_cmd" --shell bash --full --quiet)"
# shellcheck disable=SC2046
unset $(env | grep -Eo '^__LMOD_[^=]+')
unset FPATH MANPATH

# setup spack
. /scinet/spack/v0.23/share/spack/setup-env.sh
export SPACK_DISABLE_LOCAL_CONFIG=x

if [ $# -ne 0 ]; then
    # activate environment
    spack env activate "$1"

    # lmod
    . "$(spack location -i lmod)/lmod/lmod/init/bash"
    module use "$SPACK_ROOT/var/spack/environments/$1/modules/Core"
fi
