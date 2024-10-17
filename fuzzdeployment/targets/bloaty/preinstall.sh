#!/bin/bash

# Install prerequisites
sudo apt-get update && \
    sudo apt-get install -y cmake ninja-build

# Get source (as done in fuzzbench)
if [ ! -d bloaty ]; then
    git clone https://github.com/google/bloaty.git bloaty
    git -C bloaty checkout 52948c107c8f81045e7f9223ec02706b19cfa882
fi


