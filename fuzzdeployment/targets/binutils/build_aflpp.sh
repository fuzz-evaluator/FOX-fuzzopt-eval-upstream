#!/bin/bash
set -e

# USAGE
mkdir -p binaries
VARIANT=$1
BIN_NAMES="nm-new size objdump readelf strip-new"
# BIN_NAMES="size objdump readelf"

cleansource() {
     echo "[!] Cleaning source dir of binutils"
     rm -rf binutils-2.34
     tar -xf binutils-2.34.tar.xz
}

if [ "$VARIANT" = aflpp ]; then

cleansource
rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
cd binutils-2.34
set +e
make distclean
set -e
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi
mkdir -p ../binaries/aflpp_build/nm-new/
mkdir -p ../binaries/aflpp_build/size/
mkdir -p ../binaries/aflpp_build/readelf/
mkdir -p ../binaries/aflpp_build/objdump/
mkdir -p ../binaries/aflpp_build/strip-new/
# ./configure --disable-gdb --disable-libdecnumber --disable-readline --disable-sim
./configure
make -j$(nproc)
cp binutils/nm-new ../binaries/aflpp_build/nm-new/nm-new
cp binutils/size ../binaries/aflpp_build/size/size
cp binutils/readelf ../binaries/aflpp_build/readelf/readelf
cp binutils/objdump ../binaries/aflpp_build/objdump/objdump
cp binutils/strip-new ../binaries/aflpp_build/strip-new/strip-new
elif [ "$VARIANT" = cmplog ]; then

cleansource
rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build
cd binutils-2.34
set +e
make distclean
set -e
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries/cmplog_build/nm-new/
mkdir -p ../binaries/cmplog_build/size/
mkdir -p ../binaries/cmplog_build/readelf/
mkdir -p ../binaries/cmplog_build/objdump/
mkdir -p ../binaries/cmplog_build/strip-new/
# ./configure --disable-gdb --disable-libdecnumber --disable-readline --disable-sim
./configure
make -j$(nproc)

cp binutils/nm-new ../binaries/cmplog_build/nm-new/nm-new
cp binutils/size ../binaries/cmplog_build/size/size
cp binutils/readelf ../binaries/cmplog_build/readelf/readelf
cp binutils/objdump ../binaries/cmplog_build/objdump/objdump
cp binutils/strip-new ../binaries/cmplog_build/strip-new/strip-new
elif [ "$VARIANT" = optfuzz ]; then

cleansource
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
#
cd binutils-2.34
set +e
make distclean
set -e
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
mkdir -p ../binaries/optfuzz_build/nm-new/
mkdir -p ../binaries/optfuzz_build/size/
mkdir -p ../binaries/optfuzz_build/readelf/
mkdir -p ../binaries/optfuzz_build/objdump/
mkdir -p ../binaries/optfuzz_build/strip-new/
rm -f /dev/shm/*
# ./configure --disable-gdb --disable-libdecnumber --disable-readline --disable-sim
./configure
#make clean
make  -j$(nproc)
#
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build
cp binutils/nm-new ../binaries/optfuzz_build/nm-new/
cp binutils/size ../binaries/optfuzz_build/size/
cp binutils/readelf ../binaries/optfuzz_build/readelf/
cp binutils/objdump ../binaries/optfuzz_build/objdump/
cp binutils/strip-new ../binaries/optfuzz_build/strip-new/
# Create auxiliary files
BUILD_DIR=$PWD
for BIN_NAME in $BIN_NAMES; do
    cd $BUILD_DIR/../binaries/optfuzz_build/$BIN_NAME
    get-bc $BIN_NAME
    llvm-dis-15 $BIN_NAME.bc
    # python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
    #python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
    python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/../instrument_meta_data
done


elif [ "$VARIANT" = optfuzz_nogllvm ]; then

cleansource
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
#
cd binutils-2.34
set +e
make distclean
set -e
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
mkdir -p ../binaries/optfuzz_build/nm-new/
mkdir -p ../binaries/optfuzz_build/size/
mkdir -p ../binaries/optfuzz_build/readelf/
mkdir -p ../binaries/optfuzz_build/objdump/
mkdir -p ../binaries/optfuzz_build/strip-new/
rm -f /dev/shm/*
# ./configure --disable-gdb --disable-libdecnumber --disable-readline --disable-sim
./configure
#make clean
make  -j$(nproc)
#
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build
cp binutils/nm-new ../binaries/optfuzz_build/nm-new/
cp binutils/size ../binaries/optfuzz_build/size/
cp binutils/readelf ../binaries/optfuzz_build/readelf/
cp binutils/objdump ../binaries/optfuzz_build/objdump/
cp binutils/strip-new ../binaries/optfuzz_build/strip-new/
# Create auxiliary files
BUILD_DIR=$PWD
for BIN_NAME in $BIN_NAMES; do
    cd $BUILD_DIR/../binaries/optfuzz_build/$BIN_NAME
    python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/../instrument_meta_data
done

else
	echo $1
    echo "Invalid usage. Use as $0 <aflpp/cmplog>"
fi

cd -
