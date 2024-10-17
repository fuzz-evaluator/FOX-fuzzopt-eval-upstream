#!/bin/bash

# Get source
if [ ! -d zlib ]; then
    git clone --depth 1 -b develop https://github.com/madler/zlib.git
fi
