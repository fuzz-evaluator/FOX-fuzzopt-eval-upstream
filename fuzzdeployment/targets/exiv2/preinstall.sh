#!/bin/bash

sudo apt install -y libinih-dev libbrotli-dev libclang-rt-15-dev

HERE=$PWD
# Install brotli
if [ ! -d brotli ]; then
	git clone https://github.com/google/brotli
	git -C brotli checkout 200f37984a22be6ec56c2e8a16ab1a9822c891f6 
	cd brotli
	mkdir out && cd out
	cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=./installed ..
	sudo cmake --build . --config Release --target install
fi

cd $PWD
# Get source
if [ ! -d exiv2-0.28.0-Source ]; then
    wget https://github.com/Exiv2/exiv2/releases/download/v0.28.0/exiv2-0.28.0-Source.tar.gz
    tar -xf exiv2-0.28.0-Source.tar.gz 
fi


