#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="fuzz_both"

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build

cd libpcap
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi
git clean -d -f -x # Equivalent of make clean
mkdir build
cd build
rm -f /dev/shm/*
cmake -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DDISABLE_DBUS=1 .. 
make -j$(nproc) 

$CC $CFLAGS -I.. -c ../testprogs/fuzz/fuzz_both.c -o fuzz_both.o
$CXX $CXXFLAGS fuzz_both.o -o fuzz_both libpcap.a /workspace/AFLplusplus/utils/aflpp_driver/libAFLDriver.a  

mkdir -p ../../binaries/aflpp_build

cp fuzz_both ../../binaries/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build 
cd libpcap 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++

mkdir -p ../binaries/cmplog_build
git clean -d -f -x # Equivalent of make clean
mkdir build
cd build
rm -f /dev/shm/*
cmake -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DDISABLE_DBUS=1 .. 
make -j$(nproc) 

$CC $CFLAGS -I.. -c ../testprogs/fuzz/fuzz_both.c -o fuzz_both.o
$CXX $CXXFLAGS fuzz_both.o -o fuzz_both libpcap.a /workspace/AFLplusplus/utils/aflpp_driver/libAFLDriver.a  

mkdir -p ../../binaries/cmplog_build

cp fuzz_both ../../binaries/cmplog_build

elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
cd libpcap 
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
git clean -d -f -x # Equivalent of make clean
mkdir build
cd build
rm -f /dev/shm/*
cmake -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DDISABLE_DBUS=1 .. 
make -j$(nproc) 

$CC $CFLAGS -I.. -c ../testprogs/fuzz/fuzz_both.c -o fuzz_both.o
$CXX $CXXFLAGS fuzz_both.o -o fuzz_both libpcap.a /workspace/AFLplusplus/utils/aflpp_driver/libAFLDriver.a  
mkdir -p ../../binaries/optfuzz_build

cp fuzz_both ../../binaries/optfuzz_build
cp /dev/shm/strcmp_err_log ../../binaries/optfuzz_build
# 
# 
# # Create auxiliary files
cd ../../binaries/optfuzz_build/
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

cd libpcap
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
git clean -d -f -x # Equivalent of make clean
mkdir build
cd build
cmake -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX -DDISABLE_DBUS=1 ..
make -j$(nproc)

$CC $CFLAGS -I.. -c ../testprogs/fuzz/fuzz_both.c -o fuzz_both.o
$CXX $CXXFLAGS fuzz_both.o -o fuzz_both libpcap.a /workspace/AFLplusplus/utils/aflpp_driver/libAFLDriver.a

cp $BIN_NAME ../../binaries/optfuzz_build
cp /dev/shm/instrument_meta_data ../../binaries/optfuzz_build

cd ../../binaries/optfuzz_build/

python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
