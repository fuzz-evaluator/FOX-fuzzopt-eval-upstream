#!/bin/bash

# Get and install dependency
if [ ! -d libarchive-3.4.3 ]; then 
     wget https://github.com/libarchive/libarchive/releases/download/v3.4.3/libarchive-3.4.3.tar.xz
     tar -xf libarchive-3.4.3.tar.xz
     cd libarchive-3.4.3
     ./configure --disable-shared
     make clean
     make -j `nproc`
     sudo make install
     cd -
fi

# Get source
if [ ! -d freetype2 ]; then
    git clone git://git.sv.nongnu.org/freetype/freetype2.git
    cd freetype2 && git checkout cd02d359a6d0455e9d16b87bf9665961c4699538
    ./autogen.sh
fi
