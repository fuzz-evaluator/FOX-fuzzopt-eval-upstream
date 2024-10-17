#!/bin/bash

# Get and install package
if [ ! -d libarchive-3.6.2 ]; then 
     wget https://github.com/libarchive/libarchive/releases/download/v3.6.2/libarchive-3.6.2.tar.xz
     tar -xf libarchive-3.6.2.tar.xz
fi
