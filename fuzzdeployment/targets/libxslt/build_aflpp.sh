#!/bin/bash
set -e

# USAFE
VARIANT=$1
BIN_NAME="xpath"

cleansource() {
     echo "[!] Cleaning source dir of libxslt"
     cd libxml2
     git clean -xdf
     cd ..
     cd libxslt
     git clean -xdf
     cd ..
}

#XXX: Make sure to not run this command while inside virtualenv 
if [ "$VARIANT" = aflpp ]; then

cleansource
cd libxslt

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a
export ACLOCAL_PATH='/usr/share/aclocal/'

if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p ../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

rm -rf ../binaries/aflpp_build
mkdir -p ../binaries/aflpp_build

CRYPTO_CONF=--without-crypto
CRYPTO_LIBS=

cd ../libxml2
./autogen.sh \
    --disable-shared \
    --without-c14n \
    --without-legacy \
    --without-push \
    --without-python \
    --without-reader \
    --without-regexps \
    --without-sax1 \
    --without-schemas \
    --without-schematron \
    --without-valid \
    --without-writer \
    --without-zlib \
    --without-lzma
make -j$(nproc) V=1

cd ../libxslt
./autogen.sh \
    --with-libxml-src=../libxml2 \
    --disable-shared \
    --without-python \
    $CRYPTO_CONF \
    --without-debug \
    --without-debugger \
    --without-profiler
make -j$(nproc) V=1

for file in xpath fuzz; do
    # Compile as C
    $CC $CFLAGS \
        -I. -I../libxml2/include \
        -c tests/fuzz/$file.c \
        -o tests/fuzz/$file.o
done

for fuzzer in xpath ; do
    # Link with $CXX
    $CXX $CXXFLAGS \
        tests/fuzz/$fuzzer.o tests/fuzz/fuzz.o \
	-o ../binaries/aflpp_build/$fuzzer \
        $FUZZER_LIB \
        libexslt/.libs/libexslt.a libxslt/.libs/libxslt.a \
        ../libxml2/.libs/libxml2.a \
        $CRYPTO_LIBS
done

# Copy over the xpath.xml since it's used by the harness as part of initialization
cp ./tests/fuzz/xpath.xml ../binaries/aflpp_build

elif [ "$VARIANT" = cmplog ]; then

cleansource
cd libxslt
rm -rf ../binaries/cmplog_build
mkdir -p ../binaries/cmplog_build

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a
export ACLOCAL_PATH='/usr/share/aclocal/'

CRYPTO_CONF=--without-crypto
CRYPTO_LIBS=


cd ../libxml2
./autogen.sh \
    --disable-shared \
    --without-c14n \
    --without-legacy \
    --without-push \
    --without-python \
    --without-reader \
    --without-regexps \
    --without-sax1 \
    --without-schemas \
    --without-schematron \
    --without-valid \
    --without-writer \
    --without-zlib \
    --without-lzma
make -j$(nproc) V=1

cd ../libxslt
./autogen.sh \
    --with-libxml-src=../libxml2 \
    --disable-shared \
    --without-python \
    $CRYPTO_CONF \
    --without-debug \
    --without-debugger \
    --without-profiler
make -j$(nproc) V=1

for file in xpath fuzz; do
    # Compile as C
    $CC $CFLAGS \
        -I. -I../libxml2/include \
        -c tests/fuzz/$file.c \
        -o tests/fuzz/$file.o
done

for fuzzer in xpath; do
    # Link with $CXX
    $CXX $CXXFLAGS \
        tests/fuzz/$fuzzer.o tests/fuzz/fuzz.o \
	-o ../binaries/cmplog_build/$fuzzer \
        $FUZZER_LIB \
        libexslt/.libs/libexslt.a libxslt/.libs/libxslt.a \
        ../libxml2/.libs/libxml2.a \
        $CRYPTO_LIBS
done

# Copy over the xpath.xml since it's used by the harness as part of initialization
cp ./tests/fuzz/xpath.xml ../binaries/cmplog_build

elif [ "$VARIANT" = optfuzz ]; then

cleansource
cd libxslt

export ASAN_OPTIONS=detect_leaks=0
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export ACLOCAL_PATH='/usr/share/aclocal/'

rm -f /dev/shm/*

rm -rf ../binaries/optfuzz_build
mkdir -p ../binaries/optfuzz_build

CRYPTO_CONF=--without-crypto
CRYPTO_LIBS=

cd ../libxml2
./autogen.sh \
    --disable-shared \
    --without-c14n \
    --without-legacy \
    --without-push \
    --without-python \
    --without-reader \
    --without-regexps \
    --without-sax1 \
    --without-schemas \
    --without-schematron \
    --without-valid \
    --without-writer \
    --without-zlib \
    --without-lzma
make -j$(nproc) V=1

cd ../libxslt
./autogen.sh \
    --with-libxml-src=../libxml2 \
    --disable-shared \
    --without-python \
    $CRYPTO_CONF \
    --without-debug \
    --without-debugger \
    --without-profiler
make -j$(nproc) V=1

for file in xpath fuzz; do
    # Compile as C
    $CC $CFLAGS \
        -I. -I../libxml2/include \
        -c tests/fuzz/$file.c \
        -o tests/fuzz/$file.o
done

for fuzzer in xpath; do
    # Link with $CXX
    $CXX $CXXFLAGS \
        tests/fuzz/$fuzzer.o tests/fuzz/fuzz.o \
	-o ../binaries/optfuzz_build/$fuzzer \
        $FUZZER_LIB \
        libexslt/.libs/libexslt.a libxslt/.libs/libxslt.a \
        ../libxml2/.libs/libxml2.a \
        $CRYPTO_LIBS
done

cp /dev/shm/br_src_map ../binaries/optfuzz_build
cp /dev/shm/strcmp_err_log ../binaries/optfuzz_build

cd ../binaries/optfuzz_build
get-bc $BIN_NAME
llvm-dis-12 $BIN_NAME.bc
python /workspace/fuzzopt-eval/fuzzdeployment/fix_long_fun_name.py $BIN_NAME.ll
mkdir -p cfg_out_$BIN_NAME
cd cfg_out_$BIN_NAME
opt -dot-cfg ../$BIN_NAME\_fix.ll
for f in $(ls -a | grep '^\.*'|grep dot);do mv $f ${f:1};done
cd ..
python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME

# Copy over the xpath.xml since it's used by the harness as part of initialization
cp ./tests/fuzz/xpath.xml ../binaries/optfuzz_build 

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

cleansource
rm -rf /dev/shm/*
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd libxslt

export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export ACLOCAL_PATH='/usr/share/aclocal/'

CRYPTO_CONF=--without-crypto
CRYPTO_LIBS=

cd ../libxml2
./autogen.sh \
    --disable-shared \
    --without-c14n \
    --without-legacy \
    --without-push \
    --without-python \
    --without-reader \
    --without-regexps \
    --without-sax1 \
    --without-schemas \
    --without-schematron \
    --without-valid \
    --without-writer \
    --without-zlib \
    --without-lzma
make -j$(nproc) V=1

cd ../libxslt
./autogen.sh \
    --with-libxml-src=../libxml2 \
    --disable-shared \
    --without-python \
    $CRYPTO_CONF \
    --without-debug \
    --without-debugger \
    --without-profiler
make -j$(nproc) V=1

for file in xpath fuzz; do
    # Compile as C
    $CC $CFLAGS \
        -I. -I../libxml2/include \
        -c tests/fuzz/$file.c \
        -o tests/fuzz/$file.o
done

for fuzzer in xpath; do
    # Link with $CXX
    $CXX $CXXFLAGS \
        tests/fuzz/$fuzzer.o tests/fuzz/fuzz.o \
	-o ../binaries/optfuzz_build/$fuzzer \
        $FUZZER_LIB \
        libexslt/.libs/libexslt.a libxslt/.libs/libxslt.a \
        ../libxml2/.libs/libxml2.a \
        $CRYPTO_LIBS
done

# Copy over the xpath.xml since it's used by the harness as part of initialization
cp ./tests/fuzz/xpath.xml ../binaries/optfuzz_build

cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data


else 
	echo "Invalid usage. Use as $0 <aflpp/cmplog/optfuzz>"
fi

cd -


