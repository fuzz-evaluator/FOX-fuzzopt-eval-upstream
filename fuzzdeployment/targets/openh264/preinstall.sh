#!/bin/bash

sudo apt-get update && sudo apt-get install -y nasm subversion

# Get source
if [ ! -d openh264 ]; then
    git clone --depth 1 https://github.com/cisco/openh264.git 
    # XXX: No commit specified so pinning to the latest commit tested
    cd openh264 && git checkout 986606644aca8f795fc04f76dcc758d88378e4a0
fi
