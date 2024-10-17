#!/bin/bash
set -e

# USAGE
mkdir -p binaries_noasan
VARIANT=$1
BIN_NAME="pdftotext"

cleansource() {
     echo "[!] Cleaning source dir of xpdf"
     rm -rf xpdf-4.04
     tar -xf xpdf-4.04.tar.gz
}

if [ "$VARIANT" = aflpp ]; then

cleansource
rm -rf ./binaries_noasan/aflpp_build
mkdir -p ./binaries_noasan/aflpp_build

# Refresh dict
mkdir -p ./dict
rm -f ./dict/keyval.dict

export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export AFL_LLVM_DICT2FILE=$PWD/dict/keyval.dict

# Make build
# If a dict has not been generated, generate it
if [ ! -f $PWD/../../dict/keyval.dict ]; then
    mkdir -p $PWD/../../dict
fi

cd ./xpdf-4.04
cmake -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX . 
make -j`nproc`
cp xpdf/$BIN_NAME ../binaries_noasan/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

cleansource
rm -rf ./binaries_noasan/cmplog_build
mkdir -p ./binaries_noasan/cmplog_build

export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export AFL_LLVM_CMPLOG=1

cd ./xpdf-4.04
cmake -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX . 
make -j`nproc`
cp xpdf/$BIN_NAME ../binaries_noasan/cmplog_build/

elif [ "$VARIANT" = optfuzz ]; then

cleansource
rm -rf ./binaries_noasan/optfuzz_build
mkdir -p ./binaries_noasan/optfuzz_build

export AFL_CC=gclang
export AFL_CXX=gclang++
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH
# 
cd ./xpdf-4.04
cmake -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX . 
make -j`nproc`
cp xpdf/$BIN_NAME ../binaries_noasan/optfuzz_build/
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

cd -
