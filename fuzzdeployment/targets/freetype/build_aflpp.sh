#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME=ftfuzzer

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
rm -f ./dict/keyval.dict
mkdir -p dict

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export AFL_LLVM_DICT2FILE=$PWD/dict/keyval.dict

cd freetype2
git clean -df


mkdir -p ../binaries/aflpp_build
./autogen.sh
./configure --with-harfbuzz=no --with-bzip2=no --with-png=no --without-zlib --disable-shared
make -j$(nproc) clean
make -j$(nproc) all
$CXX -std=c++11 -I include -I . src/tools/ftfuzzer/ftfuzzer.cc objs/.libs/libfreetype.a /workspace/AFLplusplus/libAFLDriver.a -L /usr/local/lib -larchive -o ftfuzzer
cp ftfuzzer ../binaries/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd freetype2 
git clean -df
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries/cmplog_build
./autogen.sh
./configure --with-harfbuzz=no --with-bzip2=no --with-png=no --without-zlib --disable-shared
make -j$(nproc) clean
make -j$(nproc) all
$CXX -std=c++11 -I include -I . src/tools/ftfuzzer/ftfuzzer.cc objs/.libs/libfreetype.a /workspace/AFLplusplus/libAFLDriver.a -L /usr/local/lib -larchive -o ftfuzzer
cp ftfuzzer ../binaries/cmplog_build

elif [ "$VARIANT" = optfuzz ]; then

rm -rf /dev/shm/*
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd freetype2 

git clean -df
export AFL_CC=gclang
export AFL_CXX=gclang++
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH

mkdir -p ../binaries/optfuzz_build
rm -f /dev/shm/*
./autogen.sh
./configure --with-harfbuzz=no --with-bzip2=no --with-png=no --without-zlib --disable-shared
make -j$(nproc) clean
make -j$(nproc)
$CXX -std=c++11 -I include -I . src/tools/ftfuzzer/ftfuzzer.cc objs/.libs/libfreetype.a /workspace/OptFuzzer/libAFLDriver.a -L /usr/local/lib -larchive -o ftfuzzer
cp $BIN_NAME ../binaries/optfuzz_build
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd freetype2
git clean -df
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export AFL_IGNORE_UNKNOWN_ENVS=1

./autogen.sh
./configure --with-harfbuzz=no --with-bzip2=no --with-png=no --without-zlib --disable-shared
make -j$(nproc) clean
make -j$(nproc)

$CXX -std=c++11 -I include -I . src/tools/ftfuzzer/ftfuzzer.cc objs/.libs/libfreetype.a /workspace/OptFuzzer/libAFLDriver.a -L /usr/local/lib -larchive -o ftfuzzer

cp $BIN_NAME ../binaries/optfuzz_build
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build/

python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
