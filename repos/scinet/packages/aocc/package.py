# Copyright 2013-2024 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)
import glob
import os
from llnl.util import tty

from spack.package import *
from spack.pkg.builtin.llvm import LlvmDetection


class Aocc(Package, LlvmDetection, CompilerPackage):
    """
    The AOCC compiler system is a high performance, production quality code
    generation tool.  The AOCC environment provides various options to developers
    when building and optimizing C, C++, and Fortran applications targeting 32-bit
    and 64-bit Linux platforms.  The AOCC compiler system offers a high level of
    advanced optimizations, multi-threading and processor support that includes
    global optimization, vectorization, inter-procedural analyses, loop
    transformations, and code generation.  AMD also provides highly optimized
    libraries, which extract the optimal performance from each x86 processor core
    when utilized.  The AOCC Compiler Suite simplifies and accelerates development
    and tuning for x86 applications.

    Installation requires acceptance of the EULA by setting the +license-agreed variant.
    https://www.amd.com/en/developer/aocc/aocc-compiler/eula.html

    Example for installation: \'spack install aocc +license-agreed\'
    """

    _name = "aocc"
    homepage = "https://www.amd.com/en/developer/aocc.html"

    maintainers("amd-toolchain-support")

    version(
        ver="5.0.0",
        sha256="966fac2d2c759e9de6e969c10ada7a7b306c113f7f1e07ea376829ec86380daa",
        url="https://download.amd.com/developer/eula/aocc/aocc-5-0/aocc-compiler-5.0.0.tar",
        preferred=True,
    )
    version(
        ver="4.2.0",
        sha256="ed5a560ec745b24dc0685ccdcbde914843fb2f2dfbfce1ba592de4ffbce1ccab",
        url="https://download.amd.com/developer/eula/aocc/aocc-4-2/aocc-compiler-4.2.0.tar",
    )
    version(
        ver="4.1.0",
        sha256="5b04bfdb751c68dfb9470b34235d76efa80a6b662a123c3375b255982cb52acd",
        url="https://download.amd.com/developer/eula/aocc/aocc-4-1/aocc-compiler-4.1.0.tar",
    )
    version(
        ver="4.0.0",
        sha256="2729ec524cbc927618e479994330eeb72df5947e90cfcc49434009eee29bf7d4",
        url="https://download.amd.com/developer/eula/aocc-compiler/aocc-compiler-4.0.0.tar",
    )
    version(
        ver="3.2.0",
        sha256="8493525b3df77f48ee16f3395a68ad4c42e18233a44b4d9282b25dbb95b113ec",
        url="https://download.amd.com/developer/eula/aocc-compiler/aocc-compiler-3.2.0.tar",
    )

    requires("%gcc")
    depends_on("patchelf@:0.17", when="@:5 %gcc", type="build")

    # Licensing
    license_url = "https://www.amd.com/en/developer/aocc/aocc-compiler/eula.html"

    depends_on("libxml2")
    depends_on("zlib-api")
    depends_on("ncurses")
    depends_on("libtool")

    variant(
        "license-agreed",
        default=False,
        sticky=True,
        description="Confirm acceptance of the EULA ({0})".format(license_url),
    )

    conflicts(
        "~license-agreed",
        msg=(
            "Installation of {0} requires acceptance of the EULA (found at {1}). Set the "
            "+license-agreed variant to confirm acceptance of the EULA"
        ).format(_name, license_url),
    )

    @run_before("install")
    def license_reminder(self):
        if self.spec.satisfies("+license-agreed"):
            tty.msg(
                "Reminder: by setting +license-agreed you are confirming you agree to the terms "
                "of the {0} EULA (found at {1})".format(self.spec.name, self.license_url)
            )
        else:
            # Conflict means we should never get here...
            msg = (
                "Installation of {0} requires acceptance of the EULA (found at {1}). Set the "
                "+license-agreed variant to confirm acceptance of the EULA"
            ).format(self.spec.name, self.license_url)
            raise InstallError(msg)

    def install(self, spec, prefix):
        print("Installing AOCC Compiler ... ")
        install_tree(".", prefix)

    @run_after("install")
    def cfg_files(self):
        # Add path to gcc/g++ such that clang/clang++ can always find a full gcc installation
        # including libstdc++.so and header files.
        if self.spec.satisfies("%gcc") and self.compiler.cxx is not None:
            compiler_options = "--gcc-toolchain={}".format(self.compiler.prefix)
            for compiler in ["clang", "clang++"]:
                with open(join_path(self.prefix.bin, "{}.cfg".format(compiler)), "w") as f:
                    f.write(compiler_options)

        # help flang find gcc
        if self.spec.satisfies("@:5 %gcc") and self.compiler.prefix != "/usr":
            # help flang{1,2} find libquadmath
            libdir = self._libquadmath_dir()
            patchelf = which("patchelf")
            patchelf.add_default_arg("--set-rpath", libdir)
            patchelf(join_path(self.prefix.bin, "flang1"))
            patchelf(join_path(self.prefix.bin, "flang2"))

            # pass --gcc-toolchain & -Wl,-rpath to flang
            # flang.cfg is ignored, so replace the flang symlink with a wrapper script
            compiler_options += ' -Wno-unused-command-line-argument "-Wl,-rpath,{libdir}"'
            clang = join_path(self.prefix.bin, "clang")
            flang = join_path(self.prefix.bin, "flang")
            assert os.path.islink(flang)
            os.unlink(flang)
            with open(flang, "x") as f:
                f.write(f'#!/bin/sh\nexec -a "$0" "{clang}" {compiler_options} "$@"\n')
            set_executable(flang)

    def _libquadmath_dir(self):
        for lib in ["lib64", "lib"]:
            libdir = join_path(self.compiler.prefix, lib)
            if glob.glob(join_path(libdir, "libquadmath.*")):
                return libdir
        return None

    compiler_version_regex = r"AOCC_(\d+[._]\d+[._]\d+)"
    fortran_names = ["flang"]
