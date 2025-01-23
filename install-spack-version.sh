#!/bin/sh
set -eu

spack_version=${1:-v0.23}

# prerequisites
# https://spack.readthedocs.io/en/latest/getting_started.html
sudo dnf install -y \
	bzip2 \
	git \
	patch \
	python3 \
	unzip \
	xz

# download
git clone -c feature.manyFiles=true --depth=1 \
	--branch=releases/$spack_version \
	https://github.com/spack/spack.git $spack_version

# setup spack environment
. $spack_version/share/spack/setup-env.sh

# use OS for basic and/or sensitive packages
# https://github.com/NERSC/spack-infrastructure/blob/main/spack-externals.md
{
	sudo dnf install -y \
		libcurl-devel \
		openssl-devel

	spack external find --scope=site \
		--not-buildable \
		coreutils \
		curl \
		diffutils \
		findutils \
		git \
		openssh \
		openssl \
		sed \
		tar
}

