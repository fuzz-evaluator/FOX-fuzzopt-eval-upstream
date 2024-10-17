#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="hb-shape-fuzzer"

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
cd harfbuzz 
git clean -df
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export CFLAGS="$CFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"
export CXXFLAGS="$CXXFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"
export LIB_FUZZING_ENGINE=/workspace/AFLplusplus/libAFLDriver.a

# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

build=/tmp/build
rm -rf $build

meson --default-library=static --wrap-mode=nodownload \
      -Dexperimental_api=true \
      -Dfuzzer_ldflags="$(echo $LIB_FUZZING_ENGINE)" \
      $build \
  || (cat build/meson-logs/meson-log.txt && false)

ninja -v -j$(nproc) -C $build test/fuzzing/hb-shape-fuzzer
mv $build/test/fuzzing/hb-shape-fuzzer ../binaries/aflpp_build
# 
elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build
cd harfbuzz
git clean -df
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
./autogen.sh
make clean
cd ./src/hb-ucdn && make clean && CCLD=$CXX $CXXFLAGS make
cd ../../
CCLD="$CXX $CXXFLAGS" ./configure --enable-static --disable-shared --with-glib=no --with-cairo=no
make -j`nproc` -C src fuzzing 

mkdir -p ../binaries/cmplog_build
$CXX $CXXFLAGS -std=c++11 -I src/ test/fuzzing/hb-fuzzer.cc src/.libs/libharfbuzz-fuzzing.a /workspace/AFLplusplus/libAFLDriver.a -o $PWD/../binaries/cmplog_build/hb-fuzzer

elif [ "$VARIANT" = optfuzz ]; then

mkdir -p ./binaries/optfuzz_build

cd harfbuzz
git clean -df
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export CFLAGS="$CFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"
export CXXFLAGS="$CXXFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"
export LIB_FUZZING_ENGINE=/workspace/OptFuzzer/libAFLDriver.a

rm -f /dev/shm/*

build=/tmp/build
rm -rf $build

meson --default-library=static --wrap-mode=nodownload \
      -Dexperimental_api=true \
      -Dfuzzer_ldflags="$(echo $LIB_FUZZING_ENGINE)" \
      $build \
  || (cat build/meson-logs/meson-log.txt && false)

ninja -v -j$(nproc) -C $build test/fuzzing/hb-shape-fuzzer
mv $build/test/fuzzing/hb-shape-fuzzer ../binaries/optfuzz_build

cp /dev/shm/br_src_map ../binaries/optfuzz_build
cp /dev/shm/strcmp_err_log ../binaries/optfuzz_build
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
python /workspace/fuzzopt-eval/fuzzdeployment/fix_long_fun_name.py $BIN_NAME.ll
mkdir -p cfg_out_$BIN_NAME
cd cfg_out_$BIN_NAME
opt -dot-cfg ../$BIN_NAME\_fix.ll
for f in $(ls -a | grep '^\.*'|grep dot);do mv $f ${f:1};done
cd ..
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_refactor.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $BIN_NAME instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

mkdir -p ./binaries/optfuzz_build

cd harfbuzz
git clean -df
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export CFLAGS="$CFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"
export CXXFLAGS="$CXXFLAGS -fno-sanitize=vptr -DHB_NO_VISIBILITY"
export LIB_FUZZING_ENGINE=/workspace/OptFuzzer/libAFLDriver.a

rm -f /dev/shm/*

build=/tmp/build
rm -rf $build

meson --default-library=static --wrap-mode=nodownload \
      -Dexperimental_api=true \
      -Dfuzzer_ldflags="$(echo $LIB_FUZZING_ENGINE)" \
      $build \
  || (cat build/meson-logs/meson-log.txt && false)

ninja -v -j$(nproc) -C $build test/fuzzing/hb-shape-fuzzer
mv $build/test/fuzzing/hb-shape-fuzzer ../binaries/optfuzz_build

cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build/
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $BIN_NAME
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
