#! /usr/bin/bash
set -e

# Bundled config.sub/config.guess predate aarch64 triplets -- replace with
# the current ones from the gnuconfig package before configuring.
for f in config.sub config.guess; do
  find . -name "$f" -exec cp "$BUILD_PREFIX/share/gnuconfig/$f" {} \;
done

# Upstream hardcodes `dyturbo_LDFLAGS = -static` in src/Makefile.am, forcing
# a fully static final link -- but LHAPDF/CUBA/CHAPLIN/CERES/HELL are only
# available as shared libraries here, so the link fails with dozens of
# undefined LHAPDF/Fortran symbols. Strip the flag to link dynamically.
sed -i 's/^dyturbo_LDFLAGS = -static.*/dyturbo_LDFLAGS =/' src/Makefile.am

autoreconf --install --force

./configure --enable-Ofast --prefix=$PREFIX

NPROC=$(nproc 2>/dev/null || sysctl -n hw.ncpu)
make -j$NPROC
make install
