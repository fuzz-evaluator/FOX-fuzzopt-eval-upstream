#!/bin/bash

if [ ! -d ogg ]; then
    git clone https://github.com/xiph/ogg.git && \
    git -C ogg checkout db5c7a49ce7ebda47b15b78471e78fb7f2483e22
fi
if [ ! -d vorbis ]; then
    git clone https://github.com/xiph/vorbis.git
    # Pinning to the most recent commit that was tested
    git -C vorbis checkout 84c023699c
fi
if [ ! -f decode_fuzzer.cc ]; then
    wget -qO decode_fuzzer.cc https://raw.githubusercontent.com/google/oss-fuzz/688aadaf44499ddada755562109e5ca5eb3c5662/projects/vorbis/decode_fuzzer.cc
fi
