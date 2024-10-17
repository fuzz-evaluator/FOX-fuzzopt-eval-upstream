#!/bin/bash

sudo apt-get install -y gperf \
        libcap-dev zipmerge zip zstd patchelf

python3 -m pip install meson==0.60.0 jinja2

# Get source
if [ ! -d systemd ]; then
    git clone https://github.com/systemd/systemd
    git -C systemd checkout 07faa4990fcc1e80c9ef63c09eb91bb73dab19cb
    cd systemd && cp tools/oss-fuzz.sh ./build.sh
    sed -i '119d;126d' ./build.sh
    cd -
fi
