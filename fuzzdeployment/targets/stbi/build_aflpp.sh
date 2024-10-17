#!/bin/bash
set -e

# USAFE
VARIANT=$1
BIN_NAME="stbi_read_fuzzer"

cleansource() {
     echo "[!] Cleaning source dir of libxslt"
     rm -rf stb
     git clone https://github.com/nothings/stb.git
     git -C stb checkout 5736b15f7ea0ffb08dd38af21067c314d6a3aae9
}

#XXX: Make sure to not run this command while inside virtualenv 
if [ "$VARIANT" = aflpp ]; then

cleansource
cd stb

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    wget -O ../dict/keyval.dict https://raw.githubusercontent.com/mirrorer/afl/master/dictionaries/gif.dict
fi

mkdir -p ../binaries/aflpp_build

$CXX $CXXFLAGS -std=c++11 -I. \
    tests/stbi_read_fuzzer.c \
    -o ../binaries/aflpp_build/stbi_read_fuzzer $FUZZER_LIB

elif [ "$VARIANT" = cmplog ]; then

cleansource
cd stb
mkdir -p ../binaries/cmplog_build

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

$CXX $CXXFLAGS -std=c++11 -I. \
    tests/stbi_read_fuzzer.c \
    -o ../binaries/cmplog_build/stbi_read_fuzzer $FUZZER_LIB

elif [ "$VARIANT" = optfuzz ]; then

cleansource
cd stb

export ASAN_OPTIONS=detect_leaks=0
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a

rm -f /dev/shm/*
mkdir -p ../binaries/optfuzz_build

$CXX $CXXFLAGS -std=c++11 -I. \
    tests/stbi_read_fuzzer.c \
    -o ../binaries/optfuzz_build/stbi_read_fuzzer $FUZZER_LIB

cp /dev/shm/br_src_map ../binaries/optfuzz_build
cp /dev/shm/strcmp_err_log ../binaries/optfuzz_build

cd ../binaries/optfuzz_build
get-bc $BIN_NAME
llvm-dis-12 $BIN_NAME.bc
python /workspace/fuzzopt-eval/fuzzdeployment/fix_long_fun_name.py $BIN_NAME.ll
mkdir -p cfg_out_$BIN_NAME
cd cfg_out_$BIN_NAME
opt -dot-cfg ../$BIN_NAME\_fix.ll
for f in $(ls -a | grep '^\.*'|grep dot);do mv $f ${f:1};done
cd ..
python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

cleansource
cd stb

export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a

rm -f /dev/shm/*
mkdir -p ../binaries/optfuzz_build

$CXX $CXXFLAGS -std=c++11 -I. \
    tests/stbi_read_fuzzer.c \
    -o ../binaries/optfuzz_build/stbi_read_fuzzer $FUZZER_LIB

cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
	echo "Invalid usage. Use as $0 <aflpp/cmplog/optfuzz>"
fi

cd -


