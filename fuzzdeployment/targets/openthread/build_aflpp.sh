#!/bin/bash
set -e

# USAGE
VARIANT=$1
# BIN_NAMES="ip6-send-fuzzer radio-receive-done-fuzzer"
BIN_NAMES="ot-ip6-send-fuzzer"

# Need to do this because seemingly checkout + clean does not
# complete remove all build artifacts
cleansource() {
    rm -rf openthread
    git clone https://github.com/openthread/openthread  
    git -C openthread checkout 25506997f286fdbfa72725f4cee78c922c896255
    sed -i 's/\(-Wdocumentation\)//g' openthread/third_party/mbedtls/repo/library/CMakeLists.txt
    sed -i 's/\(-Werror\)//g' openthread/third_party/mbedtls/repo/CMakeLists.txt
}

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
cleansource
cd openthread 
./bootstrap

# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p ../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++

cd openthread 
rm -f /dev/shm/*

tests/fuzz/oss-fuzz-build

cp tests/fuzz/ip6-send-fuzzer ../binaries/aflpp_build/
cp tests/fuzz/radio-receive-done-fuzzer ../binaries/aflpp_build/


elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build
cleansource
cd openthread 
./bootstrap

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++

cd openthread 
rm -f /dev/shm/*

tests/fuzz/oss-fuzz-build

cp tests/fuzz/ip6-send-fuzzer ../binaries/cmplog_build/
cp tests/fuzz/radio-receive-done-fuzzer ../binaries/cmplog_build/

elif [ "$VARIANT" = optfuzz ]; then

export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export CFLAGS="-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument -O3"
export CXXFLAGS="-DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION -pthread -Wl,--no-as-needed -Wl,-ldl -Wl,-lm -Wno-unused-command-line-argument -stdlib=libc++ -O3"
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
cleansource
cd openthread 
rm -f /dev/shm/*

tests/fuzz/oss-fuzz-build

cp tests/fuzz/ip6-send-fuzzer ../binaries/optfuzz_build/
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build

BUILD_DIR=$PWD
for BIN_NAME in $BIN_NAMES; do
    # Create auxiliary files
    cd  $BUILD_DIR/../binaries/optfuzz_build/
    get-bc $BIN_NAME
    llvm-dis-15 $BIN_NAME.bc
    # python /workspace/fuzzopt-eval/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
    # python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
    # python /workspace/OptFuzzer/gen_graph_dev_refactor.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME instrument_meta_data
    python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data
done

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
cleansource
cd openthread 
rm -f /dev/shm/*

export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export CFLAGS=""
export CXXFLAGS=""
export OUT=$PWD/out
export LIB_FUZZING_ENGINE=/workspace/OptFuzzer/libAFLDriver.a 
mkdir $OUT
bash tests/fuzz/oss-fuzz-build

cp $OUT/ot-ip6-send-fuzzer ../binaries/optfuzz_build/
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

BUILD_DIR=$PWD
for BIN_NAME in $BIN_NAMES; do
    # Create auxiliary files
    cd  $BUILD_DIR/../binaries/optfuzz_build/
    # get-bc $BIN_NAME
    # llvm-dis-15 $BIN_NAME.bc
    # python /workspace/fuzzopt-eval/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
    # python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
    # python /workspace/OptFuzzer/gen_graph_dev_refactor.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME instrument_meta_data
    python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data
done

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
