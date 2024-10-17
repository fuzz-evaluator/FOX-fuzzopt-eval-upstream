#!/bin/bash

# Install prerequisites
# sudo apt-get update && \
#     sudo apt-get install -y nasm

# Get source
if [ ! -d libtiff-v4.5.0 ]; then
    wget https://gitlab.com/libtiff/libtiff/-/archive/v4.5.0/libtiff-v4.5.0.tar.gz
    tar -xf libtiff-v4.5.0.tar.gz
    cd libtiff-v4.5.0
    ./autogen.sh
    cd -
fi
