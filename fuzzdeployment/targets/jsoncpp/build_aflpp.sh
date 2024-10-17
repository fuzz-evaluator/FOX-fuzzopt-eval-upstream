#!/bin/bash
set -e

# USAFE
VARIANT=$1
BIN_NAME="jsoncpp_fuzzer"

cleansource() {
	echo "[!] Cleaning source dir of jsoncpp"
	rm -rf jsoncpp
	./preinstall.sh
}


#XXX: Make sure to not run this command while inside virtualenv 
if [ "$VARIANT" = aflpp ]; then

cleansource
cd jsoncpp

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

if [ ! -f $PWD/../dict/keyval.dict ]; then
	cp src/test_lib_json/fuzz.dict ../dict/keyval.dict
fi

mkdir -p ../binaries/aflpp_build

mkdir -p build
cd build
cmake -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
      -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF -DJSONCPP_WITH_TESTS=OFF \
      -DBUILD_SHARED_LIBS=OFF -G "Unix Makefiles" ..
make

$CXX $CXXFLAGS -I../include $FUZZER_LIB \
    ../src/test_lib_json/fuzz.cpp -o ../../binaries/aflpp_build/jsoncpp_fuzzer \
    lib/libjsoncpp.a

elif [ "$VARIANT" = cmplog ]; then

cleansource
cd jsoncpp

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export FUZZER_LIB=/workspace/AFLplusplus/libAFLDriver.a

mkdir -p ../binaries/cmplog_build

mkdir -p build
cd build

cmake -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
      -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF -DJSONCPP_WITH_TESTS=OFF \
      -DBUILD_SHARED_LIBS=OFF -G "Unix Makefiles" ..
make

$CXX $CXXFLAGS -I../include $FUZZER_LIB \
    ../src/test_lib_json/fuzz.cpp -o ../../binaries/cmplog_build/jsoncpp_fuzzer \
    lib/libjsoncpp.a


elif [ "$VARIANT" = optfuzz ]; then

cleansource
cd jsoncpp

export ASAN_OPTIONS=detect_leaks=0
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a

rm -f /dev/shm/*
mkdir -p ../binaries/optfuzz_build

mkdir -p build
cd build

cmake -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
      -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF -DJSONCPP_WITH_TESTS=OFF \
      -DBUILD_SHARED_LIBS=OFF -G "Unix Makefiles" ..

make

$CXX $CXXFLAGS -I../include $FUZZER_LIB \
    ../src/test_lib_json/fuzz.cpp -o ../../binaries/optfuzz_build/jsoncpp_fuzzer \
    lib/libjsoncpp.a

cd ..

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

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

cleansource
rm -rf /dev/shm/*
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd jsoncpp

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export FUZZER_LIB=/workspace/OptFuzzer/libAFLDriver.a


mkdir -p build
cd build

cmake -DCMAKE_CXX_COMPILER=$CXX -DCMAKE_CXX_FLAGS="$CXXFLAGS" \
      -DJSONCPP_WITH_POST_BUILD_UNITTEST=OFF -DJSONCPP_WITH_TESTS=OFF \
      -DBUILD_SHARED_LIBS=OFF -G "Unix Makefiles" ..

make

$CXX $CXXFLAGS -I../include $FUZZER_LIB \
    ../src/test_lib_json/fuzz.cpp -o ../../binaries/optfuzz_build/jsoncpp_fuzzer \
    lib/libjsoncpp.a

cp /dev/shm/instrument_meta_data ../../binaries/optfuzz_build

cd ../../binaries/optfuzz_build

python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
	echo "Invalid usage. Use as $0 <aflpp/cmplog/optfuzz>"
fi

cd -


