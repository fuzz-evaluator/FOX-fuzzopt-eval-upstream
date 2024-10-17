#!/bin/bash
set -e

# USAFE
VARIANT=$1
BIN_NAME="xml"

cleansource() {
     echo "[!] Cleaning source dir of libpng"
     rm -rf libxml2
     git clone https://gitlab.gnome.org/GNOME/libxml2.git
     git -C libxml2 checkout c7260a47f19e01f4f663b6a56fbdc2dafd8a6e7e
}

#XXX: Make sure to not run this command while inside virtualenv 
if [ "$VARIANT" = aflpp ]; then

cleansource
cd libxml2

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p ../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi
mkdir -p ../binaries/aflpp_build

export CFLAGS="$CFLAGS -fsanitize=unsigned-integer-overflow -fno-sanitize-recover=unsigned-integer-overflow"
export CXXFLAGS="$CXXFLAGS -fsanitize=unsigned-integer-overflow -fno-sanitize-recover=unsigned-integer-overflow"

export V=1

./autogen.sh \
    --disable-shared \
    --without-debug \
    --without-ftp \
    --without-http \
    --without-legacy \
    --without-python
make -j$(nproc)

cd fuzz
make clean-corpus
make fuzz.o

make xml.o

$CXX $CXXFLAGS \
    xml.o fuzz.o \
    -o ../../binaries/aflpp_build/xml \
    $FUZZER_LIB \
    ../.libs/libxml2.a -Wl,-Bstatic -lz -llzma -Wl,-Bdynamic

elif [ "$VARIANT" = cmplog ]; then

cleansource
cd libxml2

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a
mkdir -p ../binaries/cmplog_build
export CFLAGS="$CFLAGS -fsanitize=unsigned-integer-overflow -fno-sanitize-recover=unsigned-integer-overflow"
export CXXFLAGS="$CXXFLAGS -fsanitize=unsigned-integer-overflow -fno-sanitize-recover=unsigned-integer-overflow"

export V=1

./autogen.sh \
    --disable-shared \
    --without-debug \
    --without-ftp \
    --without-http \
    --without-legacy \
    --without-python
make -j$(nproc)

cd fuzz
make clean-corpus
make fuzz.o

make xml.o

$CXX $CXXFLAGS \
    xml.o fuzz.o \
    -o ../../binaries/cmplog_build/xml \
    $FUZZER_LIB \
    ../.libs/libxml2.a -Wl,-Bstatic -lz -llzma -Wl,-Bdynamic

elif [ "$VARIANT" = optfuzz ]; then

cleansource
cd libxml2

export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export ACLOCAL_PATH='/usr/share/aclocal/'
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
export CFLAGS="$CFLAGS -fsanitize=unsigned-integer-overflow -fno-sanitize-recover=unsigned-integer-overflow"
export CXXFLAGS="$CXXFLAGS -fsanitize=unsigned-integer-overflow -fno-sanitize-recover=unsigned-integer-overflow"

rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH


mkdir -p ../binaries/optfuzz_build

export V=1

./autogen.sh \
    --disable-shared \
    --without-debug \
    --without-ftp \
    --without-http \
    --without-legacy \
    --without-python
make -j$(nproc)

cd fuzz
make clean-corpus
make fuzz.o

make xml.o

$CXX $CXXFLAGS \
    xml.o fuzz.o \
    -o ../../binaries/optfuzz_build/xml \
    $FUZZER_LIB \
    ../.libs/libxml2.a -Wl,-Bstatic -lz -llzma -Wl,-Bdynamic

cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../../binaries/optfuzz_build

cd ../../binaries/optfuzz_build
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

cleansource
cd libxml2

rm -rf /dev/shm/*
rm -rf ../binaries/optfuzz_build
mkdir -p ../binaries/optfuzz_build

export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export ACLOCAL_PATH='/usr/share/aclocal/'
export AFL_IGNORE_UNKNOWN_ENVS=1
export CFLAGS="$CFLAGS -fsanitize=unsigned-integer-overflow -fno-sanitize-recover=unsigned-integer-overflow"
export CXXFLAGS="$CXXFLAGS -fsanitize=unsigned-integer-overflow -fno-sanitize-recover=unsigned-integer-overflow"


export V=1

./autogen.sh \
    --disable-shared \
    --without-debug \
    --without-ftp \
    --without-http \
    --without-legacy \
    --without-python
make -j$(nproc)

cd fuzz
make clean-corpus
make fuzz.o

make xml.o

$CXX $CXXFLAGS \
    xml.o fuzz.o \
    -o ../../binaries/optfuzz_build/xml \
    $FUZZER_LIB \
    ../.libs/libxml2.a -Wl,-Bstatic -lz -llzma -Wl,-Bdynamic

cp /dev/shm/instrument_meta_data ../../binaries/optfuzz_build

cd ../../binaries/optfuzz_build
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
	echo "Invalid usage. Use as $0 <aflpp/cmplog/optfuzz>"
fi

cd -
