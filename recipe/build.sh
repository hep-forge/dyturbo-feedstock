#! /usr/bin/bash
set -e

# Bundled config.sub/config.guess predate aarch64 triplets -- replace with
# the current ones from the gnuconfig package before configuring.
for f in config.sub config.guess; do
  find . -name "$f" -exec cp "$BUILD_PREFIX/share/gnuconfig/$f" {} \;
done

# Upstream hardcodes `dyturbo_LDFLAGS = -static` in both src/Makefile.am
# and the pre-shipped src/Makefile.in, forcing a fully static final link
# -- but LHAPDF/CUBA/CHAPLIN/CERES/HELL are only available as shared
# libraries here, so the link fails with dozens of undefined LHAPDF/
# Fortran symbols. Patch the pre-generated Makefile.in directly (the
# tarball's `test/` directory used by configure.ac's AC_CONFIG_FILES
# doesn't exist, so a full autoreconf fails on this release).
sed -i 's/^dyturbo_LDFLAGS = -static.*/dyturbo_LDFLAGS =/' src/Makefile.am src/Makefile.in

# configure auto-fetches and builds its own bundled Cuba copy (separate
# from the `cuba` host dependency above) if it doesn't like what it
# finds; that vendored copy has the exact same stddecl.h
# `typedef enum { false, true } bool;` C23-reserved-keyword break as the
# standalone cuba-feedstock (see its build.sh) -- pin -std=gnu99 here
# too so the bundled sub-build compiles under any compiler's default.
export CFLAGS="${CFLAGS} -std=gnu99"

./configure --enable-Ofast --prefix=$PREFIX

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
make -j$NPROC
make install
