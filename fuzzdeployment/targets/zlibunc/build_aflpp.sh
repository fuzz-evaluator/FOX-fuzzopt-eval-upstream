#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="zlib_uncompress_fuzzer"

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build

# Refresh dict
mkdir -p dict
rm -f dict/keyval.dict

cd zlib 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

./configure
make -j$(nproc) clean
make -j$(nproc) all

$CXX $CXXFLAGS -std=c++11 -I. ../zlib_uncompress_fuzzer.cc -o $PWD/../binaries/aflpp_build/$BIN_NAME /workspace/AFLplusplus/libAFLDriver.a ./libz.a

elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd zlib 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++

./configure
make -j$(nproc) clean
make -j$(nproc) all

$CXX $CXXFLAGS -std=c++11 -I. ../zlib_uncompress_fuzzer.cc -o $PWD/../binaries/cmplog_build/$BIN_NAME /workspace/AFLplusplus/libAFLDriver.a ./libz.a


elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd zlib 
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
rm -f /dev/shm/*
./configure
make -j$(nproc) clean
make -j$(nproc) all

$CXX $CXXFLAGS -std=c++11 -I. ../zlib_uncompress_fuzzer.cc -o $PWD/../binaries/optfuzz_build/$BIN_NAME /workspace/OptFuzzer/libAFLDriver.a ./libz.a
cp /dev/shm/strcmp_err_log ../binaries/optfuzz_build

cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-12 $BIN_NAME.bc
python /workspace/fuzzopt-eval/fuzzdeployment/fix_long_fun_name.py $BIN_NAME.ll
mkdir -p cfg_out_$BIN_NAME
cd cfg_out_$BIN_NAME
opt -dot-cfg ../$BIN_NAME\_fix.ll
for f in $(ls -a | grep '^\.*'|grep dot);do mv $f ${f:1};done
cd ..
python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd zlib

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++

rm -f /dev/shm/*
./configure

make -j$(nproc) clean
make -j$(nproc) all
$CXX $CXXFLAGS -std=c++11 -I. ../zlib_uncompress_fuzzer.cc -o $PWD/../binaries/optfuzz_build/$BIN_NAME /workspace/OptFuzzer/libAFLDriver.a ./libz.a

cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build/
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
