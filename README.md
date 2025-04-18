# SciNet's spack config (experimental)

## Installation

```
umask 0022
git clone git@github.com:SciNetHPC/spack-config /scinet/spack
cd /scinet/spack
./install-spack-version.sh
```

## Create environment

```
rm -r ~/.spack
cd /scinet/spack
. use.sh
./create-env.sh test
```

