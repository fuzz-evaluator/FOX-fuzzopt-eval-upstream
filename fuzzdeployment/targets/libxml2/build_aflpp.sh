#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="xmllint"

cleansource() {
     echo "[!] Cleaning source dir of libxml2"
     rm -rf libxml2-2.11.5
     tar -xf libxml2-2.11.5.tar.xz
}

if [ "$VARIANT" = aflpp ]; then

cleansource
rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build

cd libxml2-2.11.5
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p ../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi
mkdir -p ../binaries/aflpp_build
./configure --disable-shared
make -j$(nproc) clean
make -j$(nproc)
cp xmllint ../binaries/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

cleansource
rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd libxml2-2.11.5
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries/cmplog_build
./configure --disable-shared
make -j$(nproc) clean
make -j$(nproc)
cp xmllint ../binaries/cmplog_build

elif [ "$VARIANT" = optfuzz ]; then

cleansource
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd libxml2-2.11.5
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
mkdir -p ../binaries/optfuzz_build
./configure --disable-shared
make -j clean
make -j$(nproc)
cp xmllint ../binaries/optfuzz_build
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build
# Create auxiliary files
cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
#python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

cleansource
rm -rf /dev/shm/*
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd libxml2-2.11.5
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export AFL_IGNORE_UNKNOWN_ENVS=1

./configure --disable-shared
make -j clean
make -j$(nproc)

cp $BIN_NAME ../binaries/optfuzz_build
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build/
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else
    echo "Invalid usage. Use as $0 <aflpp/cmplog>"
fi

cd -
