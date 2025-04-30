#!/bin/sh
set -eu
umask 0022

spack_version=${1:-v0.23}

# download
git clone -c feature.manyFiles=true --depth=1 \
	--branch="releases/$spack_version" \
	https://github.com/spack/spack.git "$spack_version"

# setup spack environment
. "$spack_version/share/spack/setup-env.sh"

# common cache directory
mkdir -p cache
spack config --scope=site add "config:source_cache:/scinet/spack/cache"

# we have lots of cores
spack config --scope=site add "config:build_jobs:128"

# don't put 'linux' in the arch directories
spack config --scope=site add "config:install_tree:projections:all:'{architecture.os}-{architecture.target}/{compiler.name}-{compiler.version}/{name}-{version}-{hash}'"

