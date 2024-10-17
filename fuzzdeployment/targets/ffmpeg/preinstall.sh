#!/bin/bash

# Install prerequisites
sudo apt-get update && \
    sudo apt-get install -y nasm

# Get source
if [ ! -d ffmpeg-6.1 ]; then
    wget https://ffmpeg.org/releases/ffmpeg-6.1.tar.xz
    tar -xf ffmpeg-6.1.tar.xz
fi


