#!/bin/bash

# Install prerequisites
# sudo apt-get update && \
#     sudo apt-get install -y cmake flex bison 
# Get source
if [ ! -d libpcap ]; then
    git clone https://github.com/the-tcpdump-group/libpcap.git libpcap
    # XXX: Fuzzbench does not have a pinned version so pinning to the head commit
    cd libpcap && git checkout c63961294842a15cdfc858e991d611e72aec6f8c
fi
