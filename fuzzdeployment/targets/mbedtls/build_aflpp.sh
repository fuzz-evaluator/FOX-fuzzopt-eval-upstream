#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="fuzz_dtlsclient"

cleansource() {
    rm -rf mbedtls
    git clone https://github.com/Mbed-TLS/mbedtls.git mbedtls
    git -C mbedtls checkout 169d9e6eb4096cb48aa25651f42b276089841087
    cd mbedtls && pip install -r scripts/basic.requirements.txt
    sed -i 's/\(-Wdocumentation\)//g' library/CMakeLists.txt
    cd -
}

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
cleansource
cd mbedtls 
git clean -dfx 
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
perl scripts/config.pl set MBEDTLS_PLATFORM_TIME_ALT
mkdir build
cd build
cmake -DENABLE_TESTING=OFF ..
# build including fuzzers
make -j$(nproc) all
cp ./programs/fuzz/$BIN_NAME ../../binaries/aflpp_build


elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build
cleansource
cd mbedtls 
git clean -dfx 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries/cmplog_build
perl scripts/config.pl set MBEDTLS_PLATFORM_TIME_ALT
mkdir build
cd build
cmake -DENABLE_TESTING=OFF ..
# build including fuzzers
make -j$(nproc) all
cp ./programs/fuzz/$BIN_NAME ../../binaries/cmplog_build

elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd mbedtls
git clean -dfx
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
rm -f /dev/shm/*
perl scripts/config.pl set MBEDTLS_PLATFORM_TIME_ALT
mkdir build
cd build
cmake -DENABLE_TESTING=OFF ..
# build including fuzzers
make -j$(nproc) all
cp ./programs/fuzz/$BIN_NAME ../../binaries/optfuzz_build

cp /dev/shm/instrument_meta_data ../../binaries/optfuzz_build

# Create auxiliary files
cd ../../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
python /workspace/fuzzopt-eval/fuzzdeployment/fix_long_fun_name.py $BIN_NAME.ll
mkdir -p cfg_out_$BIN_NAME
cd cfg_out_$BIN_NAME
opt -dot-cfg ../$BIN_NAME\_fix.ll
for f in $(ls -a | grep '^\.*'|grep dot);do mv $f ${f:1};done
cd ..
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_refactor.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cleansource
cd mbedtls
git clean -dfx
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
rm -f /dev/shm/*

perl scripts/config.pl set MBEDTLS_PLATFORM_TIME_ALT
mkdir build
cd build
cmake -DENABLE_TESTING=OFF ..
# build including fuzzers
make -j$(nproc) all
cp ./programs/fuzz/$BIN_NAME ../../binaries/optfuzz_build

cp /dev/shm/instrument_meta_data ../../binaries/optfuzz_build

# Create auxiliary files
cd ../../binaries/optfuzz_build/
# get-bc $BIN_NAME
# llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
#python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
