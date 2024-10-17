#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="ffmpeg"

#XXX: Make sure to not run this command while inside virtualenv
if [ "$VARIANT" = aflpp ]; then

cd ffmpeg-6.1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi
mkdir -p ../binaries_noasan/aflpp_build
./configure --pkg-config-flags="--static" --cc=$CC --cxx=$CXX --disable-stripping
make -j$(nproc) clean
make -j$(nproc)
cp ffmpeg ../binaries_noasan/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

cd ffmpeg-6.1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries_noasan/cmplog_build
./configure --pkg-config-flags="--static" --cc=$CC --cxx=$CXX --disable-stripping
make -j$(nproc) clean
make -j$(nproc)
cp ffmpeg ../binaries_noasan/cmplog_build

elif [ "$VARIANT" = optfuzz ]; then

cd ffmpeg-6.1
export AFL_CC=gclang
export AFL_CXX=gclang++
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH
rm -rf ../binaries_noasan/optfuzz_build
mkdir -p ../binaries_noasan/optfuzz_build
rm -f /dev/shm/*
./configure --pkg-config-flags="--static" --cc=$CC --cxx=$CXX --disable-stripping
make -j clean
make -j$(nproc)
cp ffmpeg ../binaries_noasan/optfuzz_build
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries_noasan/optfuzz_build
# Create auxiliary files
cd ../binaries_noasan/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
#python /workspace/fuzzopt-eval/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15_noasan.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

else
    echo "Invalid usage. Use as $0 <aflpp/cmplog>"
fi

cd -
