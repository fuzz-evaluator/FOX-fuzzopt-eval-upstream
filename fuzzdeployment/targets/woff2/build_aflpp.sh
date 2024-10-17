#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="convert_woff2ttf_fuzzer"

if [ "$VARIANT" = aflpp ]; then

cd woff2 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

rm -rf ../binaries/aflpp_build
mkdir -p ../binaries/aflpp_build

git clean -df
for f in font.cc normalize.cc transform.cc woff2_common.cc woff2_dec.cc \
         woff2_enc.cc glyph.cc table_tags.cc variable_length.cc woff2_out.cc; do
  $CXX $CXXFLAGS -std=c++11 -I ../brotli/dec -I ../brotli/enc -c src/$f &
done

for f in ../brotli/dec/*.c ../brotli/enc/*.cc; do
  $CXX $CXXFLAGS -c $f & 
done

wait

$CXX $CXXFLAGS *.o /workspace/AFLplusplus/utils/aflpp_driver/libAFLDriver.a ../target.cc -I src \
    -o ../binaries/aflpp_build/convert_woff2ttf_fuzzer

elif [ "$VARIANT" = cmplog ]; then

cd woff2 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++

rm -rf ../binaries/cmplog_build
mkdir -p ../binaries/cmplog_build

git clean -df
for f in font.cc normalize.cc transform.cc woff2_common.cc woff2_dec.cc \
         woff2_enc.cc glyph.cc table_tags.cc variable_length.cc woff2_out.cc; do
  $CXX $CXXFLAGS -std=c++11 -I ../brotli/dec -I ../brotli/enc -c src/$f &
done

for f in ../brotli/dec/*.c ../brotli/enc/*.cc; do
  $CXX $CXXFLAGS -c $f & 
done

wait

$CXX $CXXFLAGS *.o /workspace/AFLplusplus/utils/aflpp_driver/libAFLDriver.a ../target.cc -I src \
    -o ../binaries/cmplog_build/convert_woff2ttf_fuzzer

elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
cd woff2 
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

rm -rf ../binaries/optfuzz_build
mkdir -p ../binaries/optfuzz_build
rm -f /dev/shm/*

git clean -df
for f in font.cc normalize.cc transform.cc woff2_common.cc woff2_dec.cc \
         woff2_enc.cc glyph.cc table_tags.cc variable_length.cc woff2_out.cc; do
  $CXX $CXXFLAGS -std=c++11 -I ../brotli/dec -I ../brotli/enc -c src/$f 
done

for f in ../brotli/dec/*.c ../brotli/enc/*.cc; do
  $CXX $CXXFLAGS -c $f 
done

wait

$CXX $CXXFLAGS *.o /workspace/OptFuzzer/libAFLDriver.a ../target.cc -I src \
    -o ../binaries/optfuzz_build/convert_woff2ttf_fuzzer
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build


# Create auxiliary files
cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
cd woff2 
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++

rm -rf ../binaries/optfuzz_build
mkdir -p ../binaries/optfuzz_build
rm -f /dev/shm/*

git clean -df
for f in font.cc normalize.cc transform.cc woff2_common.cc woff2_dec.cc \
         woff2_enc.cc glyph.cc table_tags.cc variable_length.cc woff2_out.cc; do
  $CXX $CXXFLAGS -std=c++11 -I ../brotli/dec -I ../brotli/enc -c src/$f 
done

for f in ../brotli/dec/*.c ../brotli/enc/*.cc; do
  $CXX $CXXFLAGS -c $f 
done

wait

$CXX $CXXFLAGS *.o /workspace/OptFuzzer/libAFLDriver.a ../target.cc -I src \
    -o ../binaries/optfuzz_build/convert_woff2ttf_fuzzer
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build


# Create auxiliary files
cd ../binaries/optfuzz_build/
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data


else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
