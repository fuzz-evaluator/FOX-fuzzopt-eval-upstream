#!/bin/bash
set -e

# USAGE
mkdir -p binaries
VARIANT=$1
BIN_NAME="libpng_read_fuzzer"

cleansource() {
     echo "[!] Cleaning source dir of libpng"
     rm -rf libpng
     ./preinstall.sh
}

if [ "$VARIANT" = aflpp ]; then

cleansource
rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
mkdir -p dict
cd libpng
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    wget --no-check-certificate -qO ../dict/keyval.dict \
        https://raw.githubusercontent.com/google/fuzzing/master/dictionaries/png.dict
fi

cat scripts/pnglibconf.dfa | \
  sed -e "s/option STDIO/option STDIO disabled/" \
      -e "s/option WARNING /option WARNING disabled/" \
      -e "s/option WRITE enables WRITE_INT_FUNCTIONS/option WRITE disabled/" \
> scripts/pnglibconf.dfa.temp
mv scripts/pnglibconf.dfa.temp scripts/pnglibconf.dfa

# build the libpng library.
autoreconf -f -i
./configure --with-libpng-prefix=OSS_FUZZ_
make -j$(nproc) clean
make -j$(nproc) libpng16.la

# build libpng_read_fuzzer.
$CXX $CXXFLAGS -std=c++11 -I. \
     contrib/oss-fuzz/libpng_read_fuzzer.cc \
     -o ../binaries/aflpp_build/libpng_read_fuzzer \
     $FUZZER_LIB .libs/libpng16.a -lz

elif [ "$VARIANT" = cmplog ]; then

cleansource
rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build
cd libpng
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

export AFL_LLVM_CMPLOG=1

cat scripts/pnglibconf.dfa | \
  sed -e "s/option STDIO/option STDIO disabled/" \
      -e "s/option WARNING /option WARNING disabled/" \
      -e "s/option WRITE enables WRITE_INT_FUNCTIONS/option WRITE disabled/" \
> scripts/pnglibconf.dfa.temp
mv scripts/pnglibconf.dfa.temp scripts/pnglibconf.dfa

# build the libpng library.
autoreconf -f -i
./configure --with-libpng-prefix=OSS_FUZZ_
make -j$(nproc) clean
make -j$(nproc) libpng16.la

# build libpng_read_fuzzer.
$CXX $CXXFLAGS -std=c++11 -I. \
     contrib/oss-fuzz/libpng_read_fuzzer.cc \
     -o ../binaries/cmplog_build/libpng_read_fuzzer \
     $FUZZER_LIB .libs/libpng16.a -lz


elif [ "$VARIANT" = optfuzz ]; then

cleansource
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd libpng
export AFL_CC=gclang
export AFL_CXX=gclang++
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH

# Create build dir
rm -f /dev/shm/*
cat scripts/pnglibconf.dfa | \
  sed -e "s/option STDIO/option STDIO disabled/" \
      -e "s/option WARNING /option WARNING disabled/" \
      -e "s/option WRITE enables WRITE_INT_FUNCTIONS/option WRITE disabled/" \
> scripts/pnglibconf.dfa.temp
mv scripts/pnglibconf.dfa.temp scripts/pnglibconf.dfa

# build the libpng library.
autoreconf -f -i
./configure --with-libpng-prefix=OSS_FUZZ_
make -j$(nproc) clean
make -j$(nproc) libpng16.la

# build libpng_read_fuzzer.
$CXX $CXXFLAGS -std=c++11 -I. \
     contrib/oss-fuzz/libpng_read_fuzzer.cc \
     -o ../binaries/optfuzz_build/libpng_read_fuzzer \
     $FUZZER_LIB .libs/libpng16.a -lz

cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build

# Create auxiliary files
cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

cleansource
rm -rf /dev/shm/*
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd libpng
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export AFL_IGNORE_UNKNOWN_ENVS=1

# Create build dir
cat scripts/pnglibconf.dfa | \
  sed -e "s/option STDIO/option STDIO disabled/" \
      -e "s/option WARNING /option WARNING disabled/" \
      -e "s/option WRITE enables WRITE_INT_FUNCTIONS/option WRITE disabled/" \
> scripts/pnglibconf.dfa.temp
mv scripts/pnglibconf.dfa.temp scripts/pnglibconf.dfa

# build the libpng library.
autoreconf -f -i
./configure --with-libpng-prefix=OSS_FUZZ_
make -j$(nproc) clean
make -j$(nproc) libpng16.la

# build libpng_read_fuzzer.
$CXX $CXXFLAGS -std=c++11 -I. \
     contrib/oss-fuzz/libpng_read_fuzzer.cc \
     -o ../binaries/optfuzz_build/libpng_read_fuzzer \
     $FUZZER_LIB .libs/libpng16.a -lz

cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

# Create auxiliary files
cd ../binaries/optfuzz_build/
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
