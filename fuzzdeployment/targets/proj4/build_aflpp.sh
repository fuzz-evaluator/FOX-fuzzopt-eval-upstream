#!/bin/bash
set -e

# USAFE
VARIANT=$1
BIN_NAME="proj_crs_to_crs_fuzzer"

#XXX: Make sure to not run this command while inside virtualenv 
if [ "$VARIANT" = aflpp ]; then

if [ -d $PWD/PROJ ]; then
    rm -rf PROJ
    ./preinstall.sh
fi

cd PROJ

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a
export ACLOCAL_PATH="/usr/share/aclocal"

if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

cd curl
autoreconf -i
./configure --disable-shared --with-openssl --prefix=$PWD/../install
make clean -s
make -j$(nproc) -s
make install
cd ..
# 
cd libtiff
./autogen.sh
./configure --disable-shared --prefix=$PWD/../install
make -j$(nproc)
make install
cd ..
# 

mkdir -p ../binaries/aflpp_build

mkdir -p build
cd build
cmake .. -DBUILD_SHARED_LIBS:BOOL=OFF \
        -DCURL_INCLUDE_DIR:PATH="$PWD/../install/include" \
        -DCURL_LIBRARY_RELEASE:FILEPATH="$PWD/../install/lib/libcurl.a" \
        -DTIFF_INCLUDE_DIR:PATH="$PWD/../install/include" \
        -DTIFF_LIBRARY_RELEASE:FILEPATH="$PWD/../install/lib/libtiff.a" \
        -DCMAKE_INSTALL_PREFIX=$PWD/../install \
        -DBUILD_APPS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF
make clean -s
make -j$(nproc) -s
make install
cd ..

EXTRA_LIBS="-lpthread -Wl,-Bstatic -lsqlite3 -L$PWD/install/lib -ltiff -lcurl -lssl -lcrypto -lz -Wl,-Bdynamic"


echo $PWD
$CXX $CXXFLAGS -std=c++11 -fvisibility=hidden -llzma -Isrc -Iinclude \
        test/fuzzers/proj_crs_to_crs_fuzzer.cpp -o ../binaries/aflpp_build/$BIN_NAME \
        $FUZZER_LIB "build/lib/libproj.a" $EXTRA_LIBS

echo "[libfuzzer]" > ../binaries/aflpp_build/proj_crs_to_crs_fuzzer.options
echo "max_len = 10000" >> ../binaries/aflpp_build/proj_crs_to_crs_fuzzer.options

elif [ "$VARIANT" = cmplog ]; then

if [ -d $PWD/PROJ ]; then
    rm -rf PROJ
    ./preinstall.sh
fi

cd PROJ

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a
export ACLOCAL_PATH="/usr/share/aclocal"

cd curl
autoreconf -i
./configure --disable-shared --with-openssl --prefix=$PWD/../install
make clean -s
make -j$(nproc) -s
make install
cd ..

cd libtiff
./autogen.sh
./configure --disable-shared --prefix=$PWD/../install
make -j$(nproc)
make install
cd ..

mkdir -p ../binaries/cmplog_build

mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS:BOOL=OFF \
        -DCURL_INCLUDE_DIR:PATH="$PWD/../install/include" \
        -DCURL_LIBRARY_RELEASE:FILEPATH="$PWD/../install/lib/libcurl.a" \
        -DTIFF_INCLUDE_DIR:PATH="$PWD/../install/include" \
        -DTIFF_LIBRARY_RELEASE:FILEPATH="$PWD/../install/lib/libtiff.a" \
        -DCMAKE_INSTALL_PREFIX=src/install \
        -DBUILD_APPS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF
make clean -s
make -j$(nproc) -s
make install
cd ..

export EXTRA_LIBS="-lpthread -Wl,-Bstatic -lsqlite3 -L$PWD/install/lib -ltiff -lcurl -lssl -lcrypto -lz -Wl,-Bdynamic"

$CXX $CXXFLAGS -std=c++11 -fvisibility=hidden -llzma -Isrc -Iinclude \
        test/fuzzers/proj_crs_to_crs_fuzzer.cpp -o ../binaries/cmplog_build/$BIN_NAME \
        $FUZZER_LIB "build/lib/libproj.a" $EXTRA_LIBS

echo "[libfuzzer]" > ../binaries/cmplog_build/proj_crs_to_crs_fuzzer.options
echo "max_len = 10000" >> ../binaries/cmplog_build/proj_crs_to_crs_fuzzer.options

elif [ "$VARIANT" = optfuzz ]; then

if [ -d $PWD/PROJ ]; then
    rm -rf PROJ
    ./preinstall.sh
fi
cd PROJ

export ASAN_OPTIONS=detect_leaks=0
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export ACLOCAL_PATH="/usr/share/aclocal"
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH

rm -f /dev/shm/*

cd curl
autoreconf -i
./configure --disable-shared --with-openssl --prefix=$PWD/../install
make clean -s
make -j$(nproc) -s
make install
cd ..

cd libtiff
./autogen.sh
./configure --disable-shared --prefix=$PWD/../install
make -j$(nproc)
make install
cd ..

mkdir -p ../binaries/optfuzz_build

mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS:BOOL=OFF \
        -DCMAKE_INSTALL_PREFIX=src/install \
        -DBUILD_APPS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        -DCURL_INCLUDE_DIR:PATH="$PWD/../install/include" \
        -DCURL_LIBRARY_RELEASE:FILEPATH="$PWD/../install/lib/libcurl.a" \
        -DTIFF_INCLUDE_DIR:PATH="$PWD/../install/include" \
        -DTIFF_LIBRARY_RELEASE:FILEPATH="$PWD/../install/lib/libtiff.a" 
make clean -s
make -j$(nproc) -s
make install
cd ..

export EXTRA_LIBS="-lpthread -Wl,-Bstatic -lsqlite3 -L$PWD/install/lib -ltiff -lcurl -lssl -lcrypto -lz -Wl,-Bdynamic"

build_fuzzer()
{
    fuzzerName=$1
    sourceFilename=$2
    shift
    shift
    echo "Building fuzzer $fuzzerName"
    $CXX $CXXFLAGS -std=c++11 -fvisibility=hidden -llzma -Isrc -Iinclude \
        $sourceFilename $* -o ../binaries/optfuzz_build/$fuzzerName \
        $FUZZER_LIB "$PWD/build/lib/libproj.a" $EXTRA_LIBS
    cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build
}

build_fuzzer proj_crs_to_crs_fuzzer test/fuzzers/proj_crs_to_crs_fuzzer.cpp

echo "[libfuzzer]" > ../binaries/optfuzz_build/proj_crs_to_crs_fuzzer.options
echo "max_len = 10000" >> ../binaries/optfuzz_build/proj_crs_to_crs_fuzzer.options


cd ../binaries/optfuzz_build
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME instrument_meta_data
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

if [ -d $PWD/PROJ ]; then
    rm -rf PROJ
    ./preinstall.sh
fi

rm -f /dev/shm/*
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build


cd PROJ

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a
export ACLOCAL_PATH="/usr/share/aclocal"
export AFL_IGNORE_UNKNOWN_ENVS=1


cd curl
autoreconf -i
./configure --disable-shared --with-openssl --prefix=$PWD/../install
make clean -s
make -j$(nproc) -s
make install
cd ..

cd libtiff
./autogen.sh
./configure --disable-shared --prefix=$PWD/../install
make -j$(nproc)
make install
cd ..

mkdir build
cd build
cmake .. -DBUILD_SHARED_LIBS:BOOL=OFF \
        -DCMAKE_INSTALL_PREFIX=src/install \
        -DBUILD_APPS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        -DCURL_INCLUDE_DIR:PATH="$PWD/../install/include" \
        -DCURL_LIBRARY_RELEASE:FILEPATH="$PWD/../install/lib/libcurl.a" \
        -DTIFF_INCLUDE_DIR:PATH="$PWD/../install/include" \
        -DTIFF_LIBRARY_RELEASE:FILEPATH="$PWD/../install/lib/libtiff.a" 
make clean -s
make -j$(nproc) -s
make install
cd ..

export EXTRA_LIBS="-lpthread -Wl,-Bstatic -lsqlite3 -L$PWD/install/lib -ltiff -lcurl -lssl -lcrypto -lz -Wl,-Bdynamic"

build_fuzzer()
{
    fuzzerName=$1
    sourceFilename=$2
    shift
    shift
    echo "Building fuzzer $fuzzerName"
    $CXX $CXXFLAGS -std=c++11 -fvisibility=hidden -llzma -Isrc -Iinclude \
        $sourceFilename $* -o ../binaries/optfuzz_build/$fuzzerName \
        $FUZZER_LIB "$PWD/build/lib/libproj.a" $EXTRA_LIBS
    cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build
}

build_fuzzer proj_crs_to_crs_fuzzer test/fuzzers/proj_crs_to_crs_fuzzer.cpp

echo "[libfuzzer]" > ../binaries/optfuzz_build/proj_crs_to_crs_fuzzer.options
echo "max_len = 10000" >> ../binaries/optfuzz_build/proj_crs_to_crs_fuzzer.options


cd ../binaries/optfuzz_build

python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
	echo "Invalid usage. Use as $0 <aflpp/cmplog/optfuzz>"
fi

cd -

