#! /usr/bin/bash

./configure --enable-Ofast --prefix=$PREFIX

make -j$(nproc)
make install
