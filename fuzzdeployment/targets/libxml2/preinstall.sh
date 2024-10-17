#!/bin/bash

# Install prerequisites
sudo apt-get update && \
    sudo apt-get install -y git make autoconf automake libtool pkg-config zlib1g-dev \
    	liblzma-dev

# Get source
if [ ! -d libxml2-2.11.5 ]; then
    wget https://download.gnome.org/sources/libxml2/2.11/libxml2-2.11.5.tar.xz
    tar -xf libxml2-2.11.5.tar.xz
fi


