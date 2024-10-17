#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="decode_fuzzer"

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build

# XXX: We do this cleanup because make clean targets do not seem to be working correctly for vorbis leaving stale state behind
rm -rf ogg vorbis
./preinstall.sh

cd ogg
./autogen.sh
./configure --prefix=$PWD/../binaries/aflpp_build --enable-static --disable-shared --disable-crc
make -j $(nproc)
make install

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

cd ../vorbis 
git clean -df
git checkout -f .
./autogen.sh
./configure --prefix=$PWD/../binaries/aflpp_build --enable-static --disable-shared
make -j $(nproc)
make install

cd ..

$CXX $CXXFLAGS -std=c++11 decode_fuzzer.cc \
	-o $PWD/binaries/aflpp_build/decode_fuzzer -L"$PWD/binaries/aflpp_build/lib" -I"$PWD/binaries/aflpp_build/include" \
    /workspace/AFLplusplus/libAFLDriver.a -lvorbisfile -lvorbis -logg

elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build 

# XXX: We do this cleanup because make clean targets do not seem to be working correctly for vorbis leaving stale state behind
rm -rf ogg vorbis
./preinstall.sh

cd ogg
./autogen.sh
./configure --prefix=$PWD/../binaries/cmplog_build --enable-static --disable-shared --disable-crc
make -j $(nproc)
make install

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export AFL_LLVM_CMPLOG=1

cd ../vorbis 
git clean -df
git checkout -f .
./autogen.sh
./configure --prefix=$PWD/../binaries/cmplog_build --enable-static --disable-shared
make -j $(nproc)
make install

cd ..

$CXX $CXXFLAGS -std=c++11 decode_fuzzer.cc \
	-o $PWD/binaries/cmplog_build/decode_fuzzer -L"$PWD/binaries/cmplog_build/lib" -I"$PWD/binaries/cmplog_build/include" \
    /workspace/AFLplusplus/libAFLDriver.a -lvorbisfile -lvorbis -logg


elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ../binaries/optfuzz_build

rm -f /dev/shm/*

rm -rf ogg vorbis
./preinstall.sh

cd ogg
./autogen.sh
./configure --prefix=$PWD/../binaries/optfuzz_build --enable-static --disable-shared --disable-crc
make -j $(nproc)
make install

export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++

cd ../vorbis 
git clean -df
git checkout -f .
./autogen.sh
./configure --prefix=$PWD/../binaries/optfuzz_build --enable-static --disable-shared
make -j $(nproc)
make install

cd ..

$CXX $CXXFLAGS -std=c++11 decode_fuzzer.cc \
    -o $PWD/binaries/optfuzz_build/decode_fuzzer -L"$PWD/binaries/optfuzz_build/lib" -I"$PWD/binaries/optfuzz_build/include" \
    /workspace/OptFuzzer/libAFLDriver.a -lvorbisfile -lvorbis -logg

cp /dev/shm/br_src_map ../binaries/optfuzz_build
cp /dev/shm/strcmp_err_log ../binaries/optfuzz_build

# Create auxiliary files
cd ./binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-12 $BIN_NAME.bc
python /workspace/fuzzopt-eval/fuzzdeployment/fix_long_fun_name.py $BIN_NAME.ll
mkdir -p cfg_out_$BIN_NAME
cd cfg_out_$BIN_NAME
opt -dot-cfg ../$BIN_NAME\_fix.ll
for f in $(ls -a | grep '^\.*'|grep dot);do mv $f ${f:1};done
cd ..
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ../binaries/optfuzz_build

rm -f /dev/shm/*

rm -rf ogg vorbis
./preinstall.sh

cd ogg
./autogen.sh
./configure --prefix=$PWD/../binaries/optfuzz_build --enable-static --disable-shared --disable-crc
make -j $(nproc)
make install

export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++

cd ../vorbis 
git clean -df
git checkout -f .
./autogen.sh
./configure --prefix=$PWD/../binaries/optfuzz_build --enable-static --disable-shared
make -j $(nproc)
make install

cd ..

$CXX $CXXFLAGS -std=c++11 decode_fuzzer.cc \
    -o $PWD/binaries/optfuzz_build/decode_fuzzer -L"$PWD/binaries/optfuzz_build/lib" -I"$PWD/binaries/optfuzz_build/include" \
    /workspace/OptFuzzer/libAFLDriver.a -lvorbisfile -lvorbis -logg

cp /dev/shm/instrument_meta_data ./binaries/optfuzz_build

# Create auxiliary files
cd ./binaries/optfuzz_build/
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
