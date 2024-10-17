#!/bin/bash

# Get source
if [ ! -d mbedtls ]; then
    git clone https://github.com/Mbed-TLS/mbedtls.git mbedtls
    git -C mbedtls checkout 169d9e6eb4096cb48aa25651f42b276089841087
    cd mbedtls && pip install -r scripts/basic.requirements.txt
    # XXX: The seed corpora are source from the below two repos
    # git clone --depth 1 https://github.com/google/boringssl.git boringssl
    # git clone --recursive https://github.com/openssl/openssl.git openssl
    cd -
fi
