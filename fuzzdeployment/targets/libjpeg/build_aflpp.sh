#!/bin/bash
set -e

# USAGE
mkdir -p binaries
VARIANT=$1
BIN_NAME="libjpeg_turbo_fuzzer" # The name of the binary that is being tested


if [ "$VARIANT" = aflpp ]; then


rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
cd libjpeg-turbo 
git clean -df
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p ../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

autoreconf -fiv
./configure
make -j $(nproc)

$CXX $CXXFLAGS -std=c++11 ../libjpeg_turbo_fuzzer.cc -I . \
    .libs/libturbojpeg.a $FUZZER_LIB -o ../binaries/aflpp_build/libjpeg_turbo_fuzzer

elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd libjpeg-turbo 
git clean -df
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

autoreconf -fiv
./configure
make -j $(nproc)

$CXX $CXXFLAGS -std=c++11 ../libjpeg_turbo_fuzzer.cc -I . \
    .libs/libturbojpeg.a $FUZZER_LIB -o ../binaries/cmplog_build/libjpeg_turbo_fuzzer


elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
# Compile the target
cd libjpeg-turbo 
git clean -df
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH
rm -f /dev/shm/*

autoreconf -fiv
./configure
make -j $(nproc)

$CXX $CXXFLAGS -std=c++11 ../libjpeg_turbo_fuzzer.cc -I . \
    .libs/libturbojpeg.a $FUZZER_LIB -o ../binaries/optfuzz_build/libjpeg_turbo_fuzzer

cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build


# Create auxiliary files
cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf /dev/shm/*
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

# Compile the target
cd libjpeg-turbo 
git clean -df
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export AFL_IGNORE_UNKNOWN_ENVS=1

autoreconf -fiv
./configure
make -j $(nproc)

$CXX $CXXFLAGS -std=c++11 ../libjpeg_turbo_fuzzer.cc -I . \
    .libs/libturbojpeg.a $FUZZER_LIB -o ../binaries/optfuzz_build/libjpeg_turbo_fuzzer

cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build/
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
