#!/bin/bash

# Install prerequisites
sudo apt-get update && \
    sudo apt-get install -y tcl curl 

# Get source
if [ ! -d sqlite3 ]; then
    mkdir sqlite3 && cd sqlite3
    curl 'https://sqlite.org/src/tarball/sqlite.tar.gz?r=c78cbf2e86850cc6' -o sqlite3.tar.gz && \
        tar xzf sqlite3.tar.gz --strip-components 1
fi