#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="tcpdump"

cleansource() {
     echo "[!] Cleaning source dir of tcpdump"
     rm -rf tcpdump-4.99.4
     tar -xf tcpdump-4.99.4.tar.gz
}
if [ "$VARIANT" = aflpp ]; then

cleansource
rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
cd tcpdump-4.99.4
# cd tcpdump-4.9.2
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi
./configure
make -j$(nproc) clean
make -j$(nproc)
# make install
cp $BIN_NAME ../binaries/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

cleansource
rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd tcpdump-4.99.4
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries/cmplog_build
./configure --disable-shared
make -j$(nproc) clean
make -j$(nproc)
cp $BIN_NAME ../binaries/cmplog_build

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

cleansource
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
#
cd tcpdump-4.99.4
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
mkdir -p ../binaries/optfuzz_build
./configure
make -j$(nproc) clean
make -j$(nproc)
cp $BIN_NAME ../binaries/optfuzz_build
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build
#
# # Create auxiliary files
cd ../binaries/optfuzz_build/
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz ]; then

cleansource
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
#
cd tcpdump-4.99.4
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
./configure
make -j$(nproc) clean
make -j$(nproc)
cp $BIN_NAME ../binaries/optfuzz_build
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build
#
# # Create auxiliary files
cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
#python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data
else
    echo "Invalid usage. Use as $0 <aflpp/cmplog>"
fi

cd -
