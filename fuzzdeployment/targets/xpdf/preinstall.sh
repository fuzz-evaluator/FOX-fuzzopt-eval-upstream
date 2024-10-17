#!/bin/bash

# Install prerequisites
sudo apt-get update && \
    sudo apt-get install -y qt5-default libfreetype6-dev \
# Get source
if [ ! -d xpdf-4.04 ]; then
    wget https://dl.xpdfreader.com/old/xpdf-4.04.tar.gz
    tar -xf xpdf-4.04.tar.gz
fi
