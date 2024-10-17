#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="decoder_fuzzer"

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
cd openh264
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

make clean
make -j$(nproc) USE_ASM=No BUILDTYPE=Debug libraries
$CXX $CXXFLAGS -o ../binaries/aflpp_build/decoder_fuzzer -I./codec/api/wels -I./codec/console/common/inc -I./codec/common/inc -L. /workspace/AFLplusplus/libAFLDriver.a ../decoder_fuzzer.cpp libopenh264.a

elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd openh264 
git clean -df 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++

make clean
make -j$(nproc) USE_ASM=No BUILDTYPE=Debug libraries
$CXX $CXXFLAGS -o ../binaries/cmplog_build/decoder_fuzzer -I./codec/api/wels -I./codec/console/common/inc -I./codec/common/inc -L. /workspace/AFLplusplus/libAFLDriver.a ../decoder_fuzzer.cpp libopenh264.a

elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd openh264
git clean -df
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
rm -f /dev/shm/*
make clean
make -j$(nproc) USE_ASM=No BUILDTYPE=Debug libraries
$CXX $CXXFLAGS -o ../binaries/optfuzz_build/decoder_fuzzer -I./codec/api/wels -I./codec/console/common/inc -I./codec/common/inc -L. /workspace/OptFuzzer/libAFLDriver.a ../decoder_fuzzer.cpp libopenh264.a

cp /dev/shm/br_src_map ../binaries/optfuzz_build
cp /dev/shm/strcmp_err_log ../binaries/optfuzz_build

# Create auxiliary files
cd ../binaries/optfuzz_build/
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
mkdir -p ./binaries/optfuzz_build

cd openh264
git clean -df
# export AFL_CC=gclang
# export AFL_CXX=gclang++
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
# export AFL_LLVM_LOG_PATH=$PWD/../meta/
# export AFL_IGNORE_UNKNOWN_ENVS=1
# rm -rf $AFL_LLVM_LOG_PATH
# mkdir $AFL_LLVM_LOG_PATH
# Create build dir
rm -f /dev/shm/*
make clean
make -j$(nproc) USE_ASM=No BUILDTYPE=Debug libraries
$CXX $CXXFLAGS -o ../binaries/optfuzz_build/decoder_fuzzer -I./codec/api/wels -I./codec/console/common/inc -I./codec/common/inc -L. /workspace/OptFuzzer/libAFLDriver.a ../decoder_fuzzer.cpp libopenh264.a

# cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

# Create auxiliary files
cd ../binaries/optfuzz_build/
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
