#!/bin/bash

# Install prerequisites
sudo apt-get update && \
    sudo apt-get install -y libpcap-dev

# Get source
if [ ! -d tcpdump-4.99.4 ]; then
    wget https://www.tcpdump.org/release/tcpdump-4.99.4.tar.gz
    tar -xf tcpdump-4.99.4.tar.gz
fi
