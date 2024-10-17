#!/bin/bash

ROOTDIR="/workspace/fuzzopt-eval/fuzzdeployment/targets"
TARGETS="xpdf bloaty curl freetype harfbuzz jsoncpp lcms libjpeg libpcap libpng_read_fuzzer libxml2_xml mbedtls openh264 openssl openthread proj4 re2 sqlite3 stbi systemd vorbis woff2 zlibunc libarchive exiv2 ffmpeg binutils libtiff tcpdump libxml2 jasper libxslt"

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
