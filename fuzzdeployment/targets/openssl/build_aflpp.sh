#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="x509"

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build

cd openssl 
git clean -df

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

./config --debug enable-fuzz-libfuzzer -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION no-shared enable-tls1_3 enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method enable-nextprotoneg enable-weak-ssl-ciphers --with-fuzzer-lib=/workspace/AFLplusplus/libAFLDriver.a $CFLAGS -fno-sanitize=alignment -no-asm

make clean -j$(nproc)
make -j$(nproc) LDCMD="$CXX $CXXFLAGS"
cp ./fuzz/$BIN_NAME ../binaries/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd openssl 
git clean -df

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export AFL_LLVM_CMPLOG=1
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

./config --debug enable-fuzz-libfuzzer -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION no-shared enable-tls1_3 enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method enable-nextprotoneg enable-weak-ssl-ciphers --with-fuzzer-lib=/workspace/AFLplusplus/libAFLDriver.a $CFLAGS -fno-sanitize=alignment -no-asm

make clean -j$(nproc)
make -j$(nproc) LDCMD="$CXX $CXXFLAGS"
cp ./fuzz/$BIN_NAME ../binaries/cmplog_build

elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd openssl
git clean -df
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH

mkdir -p ../binaries/optfuzz_build
rm -f /dev/shm/*

./config --debug enable-fuzz-libfuzzer -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION no-shared enable-tls1_3 enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method enable-nextprotoneg enable-weak-ssl-ciphers --with-fuzzer-lib=/workspace/OptFuzzer/libAFLDriver.a $CFLAGS -fno-sanitize=alignment -no-asm

make clean -j$(nproc)
make -j$(nproc) LDCMD="$CXX $CXXFLAGS"
cp ./fuzz/$BIN_NAME ../binaries/optfuzz_build
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build

# Create auxiliary files
cd ../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_refactor.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME instrument_meta_data
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd openssl
git clean -df

export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export WITH_FUZZER_LIB="$FUZZER_LIB"

mkdir -p ../binaries/optfuzz_build
rm -f /dev/shm/*

./config --debug enable-fuzz-libfuzzer -DPEDANTIC -DFUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION no-shared enable-tls1_3 enable-rc5 enable-md2 enable-ec_nistp_64_gcc_128 enable-ssl3 enable-ssl3-method enable-nextprotoneg enable-weak-ssl-ciphers --with-fuzzer-lib=/workspace/OptFuzzer/libAFLDriver.a $CFLAGS -fno-sanitize=alignment -no-asm

make -j$(nproc) LDCMD="$CXX $CXXFLAGS"
cp ./fuzz/$BIN_NAME ../binaries/optfuzz_build
cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

# Create auxiliary files
cd ../binaries/optfuzz_build/
# get-bc $BIN_NAME
# llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
#python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
