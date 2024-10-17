#!/bin/bash

# Install prerequisites
sudo apt-get update && \
    sudo apt-get install -y texinfo help2man\

# XXX: Using 2.36 instead of 2.40 because that would have compilation issues with optfuzz
if [ ! -d binutils-2.34 ]; then
    wget https://ftp.gnu.org/gnu/binutils/binutils-2.34.tar.xz
    tar -xf binutils-2.34.tar.xz
fi

