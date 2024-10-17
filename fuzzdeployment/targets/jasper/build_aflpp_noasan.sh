#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="jasper"

cleansource() {
     echo "[!] Cleaning source dir of libarchive"
     rm -rf jasper-4.1.2
     tar -xf jasper-4.1.2.tar.gz
}

if [ "$VARIANT" = aflpp ]; then

cleansource

rm -rf ./binaries_noasan/aflpp_build
mkdir -p ./binaries_noasan/aflpp_build

cd jasper-4.1.2
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export SOURCE_DIR=$PWD
export BUILD_DIR=$PWD/../build
export INSTALL_DIR=$PWD/../install
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
rm -rf $INSTALL_DIR
mkdir $INSTALL_DIR
if [ ! -f $PWD/../dict/keyval.dict ]; then
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi
cmake -H$SOURCE_DIR -B$BUILD_DIR -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DJAS_ENABLE_SHARED=false
cmake --build $BUILD_DIR
mkdir -p ../binaries_noasan/aflpp_build
cp $BUILD_DIR/src/app/$BIN_NAME ../binaries_noasan/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

cleansource

rm -rf ./binaries_noasan/cmplog_build
mkdir -p ./binaries_noasan/cmplog_build

cd jasper-4.1.2
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries_noasan/cmplog_build
export SOURCE_DIR=$PWD
export BUILD_DIR=$PWD/../build
export INSTALL_DIR=$PWD/../install
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
rm -rf $INSTALL_DIR
mkdir $INSTALL_DIR
cmake -H$SOURCE_DIR -B$BUILD_DIR -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DJAS_ENABLE_SHARED=false
cmake --build $BUILD_DIR
cp $BUILD_DIR/src/app/$BIN_NAME ../binaries_noasan/cmplog_build

elif [ "$VARIANT" = optfuzz ]; then

cleansource

rm -rf ./binaries_noasan/optfuzz_build
mkdir -p ./binaries_noasan/optfuzz_build

cd jasper-4.1.2
export AFL_CC=gclang
export AFL_CXX=gclang++
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH
export SOURCE_DIR=$PWD
export BUILD_DIR=$PWD/../build
export INSTALL_DIR=$PWD/../install
rm -rf $BUILD_DIR
mkdir $BUILD_DIR
rm -rf $INSTALL_DIR
mkdir $INSTALL_DIR
cmake -H$SOURCE_DIR -B$BUILD_DIR -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DJAS_ENABLE_SHARED=false
cmake --build $BUILD_DIR
cp $BUILD_DIR/src/app/$BIN_NAME ../binaries_noasan/optfuzz_build
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries_noasan/optfuzz_build
# Create auxiliary files
cd ../binaries_noasan/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
#python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15_noasan.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

else
    echo "Invalid usage. Use as $0 <aflpp/cmplog>"
fi
