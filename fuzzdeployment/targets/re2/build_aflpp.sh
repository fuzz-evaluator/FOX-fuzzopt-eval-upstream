#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="fuzzer"

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
cd re2
git clean -df 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

mkdir -p ../binaries/aflpp_build
make clean
make -j$(nproc)
$CXX $CXXFLAGS ../target.cc -I . obj/libre2.a -lpthread /workspace/AFLplusplus/libAFLDriver.a -o ../binaries/aflpp_build/fuzzer 


elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd re2
git clean -df 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries/cmplog_build
make clean
make -j$(nproc)
$CXX $CXXFLAGS ../target.cc -I . obj/libre2.a -lpthread /workspace/AFLplusplus/libAFLDriver.a -o ../binaries/cmplog_build/fuzzer 

elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd re2
git clean -df
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH
rm -f /dev/shm/*
make clean
make -j$(nproc)
$CXX $CXXFLAGS ../target.cc -I . obj/libre2.a -lpthread /workspace/OptFuzzer/libAFLDriver.a -o ../binaries/optfuzz_build/fuzzer 
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build

# Create auxiliary files
cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd re2
git clean -df
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
rm -f /dev/shm/*
make clean
make -j$(nproc)
$CXX $CXXFLAGS ../target.cc -I . obj/libre2.a -lpthread /workspace/OptFuzzer/libAFLDriver.a -o ../binaries/optfuzz_build/fuzzer 
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

# Create auxiliary files
cd ../binaries/optfuzz_build/
# get-bc $BIN_NAME
# llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
