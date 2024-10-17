#!/bin/bash
if [ ! -d re2 ]; then
    git clone https://github.com/google/re2
    cd re2 && git checkout tags/2022-12-01
fi

