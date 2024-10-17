#!/bin/bash

if [ ! -d openssl ]; then
    git clone https://github.com/openssl/openssl.git
    git -C openssl checkout b0593c086dd303af31dc1e30233149978dd613c4 
fi
