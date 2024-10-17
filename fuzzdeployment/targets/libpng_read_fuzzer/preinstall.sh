#!/bin/bash

# Install prerequisites
# sudo apt-get update && \
#     sudo apt-get install -y git make autoconf automake libtool pkg-config zlib1g-dev \
#     	liblzma-dev

# Get source
if [ ! -d libpng ]; then
    git clone https://github.com/glennrp/libpng.git
    git -C libpng checkout cd0ea2a7f53b603d3d9b5b891c779c430047b39a
fi
