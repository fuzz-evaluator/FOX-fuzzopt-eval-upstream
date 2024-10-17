#!/bin/bash

ROOTDIR="/workspace/fuzzopt-eval/fuzzdeployment/targets"
TARGETS="freetype libpng_read_fuzzer mbedtls libarchive binutils"

setup() {
./preinstall.sh
./build_aflpp.sh aflpp
./build_aflpp.sh cmplog 
./build_aflpp.sh optfuzz_nogllvm
}

for target in $TARGETS; do
	echo "Setting up $target"
	cd $ROOTDIR/$target
	setup
done
