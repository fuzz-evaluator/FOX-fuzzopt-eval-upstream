#!/bin/bash

# Install prerequisites
sudo apt-get update && \
    sudo apt-get install -y ragel pkg-config\

python3.8 -m pip install ninja meson==0.56.0

# Get source
if [ ! -d harfbuzz ]; then
    git clone https://github.com/harfbuzz/harfbuzz.git
    cd harfbuzz && git checkout cb47dca74cbf6d147aac9cf3067f249555aa68b1
fi
