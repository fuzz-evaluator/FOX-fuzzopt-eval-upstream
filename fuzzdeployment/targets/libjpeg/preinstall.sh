#!/bin/bash

sudo apt-get update && sudo apt install -y make automake libtool nasm

# Get source
if [ ! -d libjpeg-turbo ]; then
    git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git
    cd libjpeg-turbo && git checkout b0971e47d76fdb81270e93bbf11ff5558073350d
    cd -
fi
