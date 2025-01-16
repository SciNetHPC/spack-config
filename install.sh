#!/bin/sh

spack_version=${1:-v0.23}

# prerequisites
# https://spack.readthedocs.io/en/latest/getting_started.html
sudo dnf install -y \
	bzip2 \
	gcc-toolset-13 \
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

# configure compiler
(
	. /opt/rh/gcc-toolset-13/enable
	spack compiler find --scope=site
)

# use OS for basic and/or sensitive packages
# https://github.com/NERSC/spack-infrastructure/blob/main/spack-externals.md
{
	sudo dnf install -y \
		libcurl-devel \
		m4 \
		openssl-devel

	spack external find --scope=site \
		--not-buildable \
		coreutils \
		curl \
		diffutils \
		findutils \
		git \
		m4 \
		openssh \
		openssl \
		sed \
		slurm \
		tar \
		unzip
}

# add repos
spack repo add repos/scinet

