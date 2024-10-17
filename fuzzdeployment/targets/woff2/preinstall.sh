#!/bin/bash

if [ ! -d woff2 ]; then
    git clone https://github.com/google/woff2.git  
    cd woff2 && git checkout 9476664fd6931ea6ec532c94b816d8fbbe3aed90 && cd -
fi
if [ ! -d brotli ]; then
    git clone https://github.com/google/brotli.git
    cd brotli && git checkout 3a9032ba8733532a6cd6727970bade7f7c0e2f52 && cd -
fi
