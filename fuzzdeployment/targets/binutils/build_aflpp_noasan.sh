#!/bin/bash
set -e

# USAGE
mkdir -p binaries_noasan
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
rm -rf ./binaries_noasan/aflpp_build
mkdir -p ./binaries_noasan/aflpp_build
cd binutils-2.34
set +e
make distclean
set -e
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi
mkdir -p ../binaries_noasan/aflpp_build/nm-new/
mkdir -p ../binaries_noasan/aflpp_build/size/
mkdir -p ../binaries_noasan/aflpp_build/readelf/
mkdir -p ../binaries_noasan/aflpp_build/objdump/
mkdir -p ../binaries_noasan/aflpp_build/strip-new/
# ./configure --disable-gdb --disable-libdecnumber --disable-readline --disable-sim
./configure
make -j$(nproc)
cp binutils/nm-new ../binaries_noasan/aflpp_build/nm-new/nm-new
cp binutils/size ../binaries_noasan/aflpp_build/size/size
cp binutils/readelf ../binaries_noasan/aflpp_build/readelf/readelf
cp binutils/objdump ../binaries_noasan/aflpp_build/objdump/objdump
cp binutils/strip-new ../binaries_noasan/aflpp_build/strip-new/strip-new
elif [ "$VARIANT" = cmplog ]; then

cleansource
rm -rf ./binaries_noasan/cmplog_build
mkdir -p ./binaries_noasan/cmplog_build
cd binutils-2.34
set +e
make distclean
set -e
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries_noasan/cmplog_build/nm-new/
mkdir -p ../binaries_noasan/cmplog_build/size/
mkdir -p ../binaries_noasan/cmplog_build/readelf/
mkdir -p ../binaries_noasan/cmplog_build/objdump/
mkdir -p ../binaries_noasan/cmplog_build/strip-new/
# ./configure --disable-gdb --disable-libdecnumber --disable-readline --disable-sim
./configure
make -j$(nproc)

cp binutils/nm-new ../binaries_noasan/cmplog_build/nm-new/nm-new
cp binutils/size ../binaries_noasan/cmplog_build/size/size
cp binutils/readelf ../binaries_noasan/cmplog_build/readelf/readelf
cp binutils/objdump ../binaries_noasan/cmplog_build/objdump/objdump
cp binutils/strip-new ../binaries_noasan/cmplog_build/strip-new/strip-new
elif [ "$VARIANT" = optfuzz ]; then

cleansource
rm -rf ./binaries_noasan/optfuzz_build
mkdir -p ./binaries_noasan/optfuzz_build
#
cd binutils-2.34
set +e
make distclean
set -e
export AFL_CC=gclang
export AFL_CXX=gclang++
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH
mkdir -p ../binaries_noasan/optfuzz_build/nm-new/
mkdir -p ../binaries_noasan/optfuzz_build/size/
mkdir -p ../binaries_noasan/optfuzz_build/readelf/
mkdir -p ../binaries_noasan/optfuzz_build/objdump/
mkdir -p ../binaries_noasan/optfuzz_build/strip-new/
rm -f /dev/shm/*
# ./configure --disable-gdb --disable-libdecnumber --disable-readline --disable-sim
./configure
#make clean
make  -j$(nproc)
#
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries_noasan/optfuzz_build
cp binutils/nm-new ../binaries_noasan/optfuzz_build/nm-new/
cp binutils/size ../binaries_noasan/optfuzz_build/size/
cp binutils/readelf ../binaries_noasan/optfuzz_build/readelf/
cp binutils/objdump ../binaries_noasan/optfuzz_build/objdump/
cp binutils/strip-new ../binaries_noasan/optfuzz_build/strip-new/
# Create auxiliary files
BUILD_DIR=$PWD
for BIN_NAME in $BIN_NAMES; do
    cd $BUILD_DIR/../binaries_noasan/optfuzz_build/$BIN_NAME
    get-bc $BIN_NAME
    llvm-dis-15 $BIN_NAME.bc
    # python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
    #python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
    python /workspace/OptFuzzer/gen_graph_dev_no_dot_15_noasan.py $BIN_NAME.ll $BIN_NAME $PWD/../instrument_meta_data
done

else
	echo $1
    echo "Invalid usage. Use as $0 <aflpp/cmplog>"
fi

cd -
