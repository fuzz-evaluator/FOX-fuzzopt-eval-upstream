#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="cms_transform_fuzzer"

#XXX: Make sure to not run this command while inside virtualenv 
if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build

cd lcms 
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
./autogen.sh
./configure --disable-shared
rm -f /dev/shm/*
make clean
make -j$(nproc)

$CXX $CXXFLAGS ../cms_transform_fuzzer.cc -I include/ src/.libs/liblcms2.a /workspace/AFLplusplus/libAFLDriver.a -o $BIN_NAME  

cp $BIN_NAME ../binaries/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd lcms 
git clean -df

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries/cmplog_build
./autogen.sh
./configure --disable-shared 
make -j$(nproc) clean
make -j$(nproc) 

$CXX $CXXFLAGS ../cms_transform_fuzzer.cc -I include/ src/.libs/liblcms2.a /workspace/AFLplusplus/libAFLDriver.a -o $BIN_NAME  

cp $BIN_NAME ../binaries/cmplog_build

elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd lcms 
git clean -df
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
#XXX: Experimental flag to see if opt can be parallelized
export WLLVM_BC_STORE=/workspace/fuzzopt-eval/fuzzdeployment/targets/lcms/binaries/optfuzz_build/bc_store
mkdir -p $WLLVM_BC_STORE
./autogen.sh
./configure --disable-shared
rm -f /dev/shm/*
make clean
make -j$(nproc)

$CXX $CXXFLAGS ../cms_transform_fuzzer.cc -I include/ src/.libs/liblcms2.a /workspace/OptFuzzer/libAFLDriver.a -o $BIN_NAME  

cp $BIN_NAME ../binaries/optfuzz_build
cp /dev/shm/br_src_map ../binaries/optfuzz_build
cp /dev/shm/strcmp_err_log ../binaries/optfuzz_build

# Create auxiliary files
cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
python /workspace/fuzzopt-eval/fuzzdeployment/fix_long_fun_name.py $BIN_NAME.ll
# mkdir -p cfg_out_$BIN_NAME
# cd cfg_out_$BIN_NAME
# opt -dot-cfg ../$BIN_NAME\_fix.ll
# for f in $(ls -a | grep '^\.*'|grep dot);do mv $f ${f:1};done
# cd ..
# # python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
