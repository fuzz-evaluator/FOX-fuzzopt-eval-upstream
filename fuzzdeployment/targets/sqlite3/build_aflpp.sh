#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="ossfuzz"

cleansource() {
     echo "[!] Cleaning source dir of sqlite3"
     rm -rf sqlite3 
     tar -xf sqlite3.tar.gz
     mv sqlite sqlite3
}

if [ "$VARIANT" = aflpp ]; then

# cleansource
rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# export AFL_LLVM_ALLOWLIST="../../allowlist.txt"

# If a dict has not been generated, generate it
if [ ! -f ./dict/keyval.dict ]; then
    mkdir -p $PWD/dict
    export AFL_LLVM_DICT2FILE=$PWD/dict/keyval.dict
fi

export CFLAGS="$CFLAGS -DSQLITE_MAX_LENGTH=128000000 \
               -DSQLITE_MAX_SQL_LENGTH=128000000 \
               -DSQLITE_MAX_MEMORY=25000000 \
               -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
               -DSQLITE_DEBUG=1 \
               -DSQLITE_MAX_PAGE_COUNT=16384"             

cd sqlite3 
rm -rf bld && mkdir bld
cd bld
../configure
make clean
make -j$(nproc)
make sqlite3.c

$CC $CFLAGS -I. -c \
    ../test/ossfuzz.c -o ../test/ossfuzz.o

$CXX $CXXFLAGS \
    ../test/ossfuzz.o -o ../../binaries/aflpp_build/ossfuzz \
    /workspace/AFLplusplus/libAFLDriver.a ./sqlite3.o -pthread -ldl -lz

elif [ "$VARIANT" = cmplog ]; then

# cleansource
rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++

export CFLAGS="$CFLAGS -DSQLITE_MAX_LENGTH=128000000 \
               -DSQLITE_MAX_SQL_LENGTH=128000000 \
               -DSQLITE_MAX_MEMORY=25000000 \
               -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
               -DSQLITE_DEBUG=1 \
               -DSQLITE_MAX_PAGE_COUNT=16384"             
cd sqlite3
rm -rf bld && mkdir bld
cd bld
../configure
make clean
make -j$(nproc)
make sqlite3.c

$CC $CFLAGS -I. -c \
    ../test/ossfuzz.c -o ../test/ossfuzz.o

$CXX $CXXFLAGS \
    ../test/ossfuzz.o -o ../../binaries/cmplog_build/ossfuzz \
    /workspace/AFLplusplus/libAFLDriver.a ./sqlite3.o -pthread -ldl -lz

elif [ "$VARIANT" = gcov ]; then

export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export CFLAGS+="-fprofile-arcs -ftest-coverage"
export CXXFLAGS+="-fprofile-arcs -ftest-coverage"
export LDFLAGS+="--coverage"
export CFLAGS="$CFLAGS -DSQLITE_MAX_LENGTH=128000000 \
               -DSQLITE_MAX_SQL_LENGTH=128000000 \
               -DSQLITE_MAX_MEMORY=25000000 \
               -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
               -DSQLITE_DEBUG=1 \
               -DSQLITE_MAX_PAGE_COUNT=16384"             
cd sqlite3_gcov
rm -rf bld && mkdir bld
cd bld
../configure
make clean
make -j$(nproc)
make sqlite3.c

$CC $CFLAGS -I. -c \
    ../test/ossfuzz.c -o ../test/ossfuzz.o

$CXX $CXXFLAGS \
    ../test/ossfuzz.o -o ./ossfuzz \
    /workspace/AFLplusplus/libAFLDriver.a ./sqlite3.o -pthread -ldl -lz


elif [ "$VARIANT" = optfuzz ]; then

# cleansource
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export CFLAGS="$CFLAGS -DSQLITE_MAX_LENGTH=128000000 \
               -DSQLITE_MAX_SQL_LENGTH=128000000 \
               -DSQLITE_MAX_MEMORY=25000000 \
               -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
               -DSQLITE_DEBUG=1 \
               -DSQLITE_MAX_PAGE_COUNT=16384"             
cd sqlite3
rm -rf bld && mkdir bld
cd bld
../configure
rm -f /dev/shm/*
make clean
make -j$(nproc)
make sqlite3.c

$CC $CFLAGS -I. -c \
    ../test/ossfuzz.c -o ../test/ossfuzz.o

$CXX $CXXFLAGS \
    ../test/ossfuzz.o -o ../../binaries/optfuzz_build/ossfuzz \
    /workspace/OptFuzzer/libAFLDriver.a ./sqlite3.o -pthread -ldl -lz

cp /dev/shm/br_src_map ../../binaries/optfuzz_build
cp /dev/shm/strcmp_err_log ../../binaries/optfuzz_build

# Create auxiliary files
cd ../../binaries/optfuzz_build/
get-bc $BIN_NAME
llvm-dis-12 $BIN_NAME.bc
python /workspace/fuzzopt-eval/fuzzdeployment/fix_long_fun_name.py $BIN_NAME.ll
mkdir -p cfg_out_$BIN_NAME
cd cfg_out_$BIN_NAME
opt -dot-cfg ../$BIN_NAME\_fix.ll
for f in $(ls -a | grep '^\.*'|grep dot);do mv $f ${f:1};done
cd ..
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

# cleansource
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export CFLAGS="$CFLAGS -DSQLITE_MAX_LENGTH=128000000 \
               -DSQLITE_MAX_SQL_LENGTH=128000000 \
               -DSQLITE_MAX_MEMORY=25000000 \
               -DSQLITE_PRINTF_PRECISION_LIMIT=1048576 \
               -DSQLITE_DEBUG=1 \
               -DSQLITE_MAX_PAGE_COUNT=16384"             
cd sqlite3
rm -rf bld && mkdir bld
cd bld
../configure
rm -f /dev/shm/*
make clean
make -j$(nproc)
make sqlite3.c

$CC $CFLAGS -I. -c \
    ../test/ossfuzz.c -o ../test/ossfuzz.o

$CXX $CXXFLAGS \
    ../test/ossfuzz.o -o ../../binaries/optfuzz_build/ossfuzz \
    /workspace/OptFuzzer/libAFLDriver.a ./sqlite3.o -pthread -ldl -lz

cp /dev/shm/instrument_meta_data ../../binaries/optfuzz_build

# Create auxiliary files
cd ../../binaries/optfuzz_build/
python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
