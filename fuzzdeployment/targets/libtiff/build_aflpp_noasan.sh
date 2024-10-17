#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAMES="tiff2pdf tiff2ps tiffcrop"

cleansource() {
     echo "[!] Cleaning source dir of libtiff"
     rm -rf libtiff-v4.5.0
     tar -xf libtiff-v4.5.0.tar.gz
}

#XXX: Make sure to not run this command while inside virtualenv
if [ "$VARIANT" = aflpp ]; then

cleansource
rm -rf ./binaries_noasan/aflpp_build
mkdir -p ./binaries_noasan/aflpp_build
cd libtiff-v4.5.0
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi
mkdir -p ../binaries_noasan/aflpp_build/tiff2pdf
mkdir -p ../binaries_noasan/aflpp_build/tiff2ps
mkdir -p ../binaries_noasan/aflpp_build/tiffcrop
./autogen.sh
./configure --disable-shared
make -j$(nproc) clean
make -j$(nproc)
cp tools/tiff2pdf ../binaries_noasan/aflpp_build/tiff2pdf
cp tools/tiff2ps ../binaries_noasan/aflpp_build/tiff2ps
cp tools/tiffcrop ../binaries_noasan/aflpp_build/tiffcrop

elif [ "$VARIANT" = cmplog ]; then

cleansource

mkdir -p ./binaries_noasan/cmplog_build
rm -rf ./binaries_noasan/cmplog_build
cd libtiff-v4.5.0
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries_noasan/cmplog_build/tiff2pdf
mkdir -p ../binaries_noasan/cmplog_build/tiff2ps
mkdir -p ../binaries_noasan/cmplog_build/tiffcrop
./autogen.sh
./configure --disable-shared
make -j$(nproc) clean
make -j$(nproc)
cp tools/tiff2pdf ../binaries_noasan/cmplog_build/tiff2pdf
cp tools/tiff2ps ../binaries_noasan/cmplog_build/tiff2ps
cp tools/tiffcrop ../binaries_noasan/cmplog_build/tiffcrop
elif [ "$VARIANT" = optfuzz ]; then

cleansource

rm -rf ./binaries_noasan/optfuzz_build
mkdir -p ./binaries_noasan/optfuzz_build

cd libtiff-v4.5.0
export AFL_CC=gclang
export AFL_CXX=gclang++
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH
mkdir -p ../binaries_noasan/optfuzz_build/tiff2pdf
mkdir -p ../binaries_noasan/optfuzz_build/tiff2ps
mkdir -p ../binaries_noasan/optfuzz_build/tiffcrop
./autogen.sh
./configure --disable-shared
make clean
make -j$(nproc)
cp tools/tiff2pdf ../binaries_noasan/optfuzz_build/tiff2pdf
cp tools/tiff2ps ../binaries_noasan/optfuzz_build/tiff2ps
cp tools/tiffcrop ../binaries_noasan/optfuzz_build/tiffcrop
cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries_noasan/optfuzz_build
# Create auxiliary files
cd ../binaries_noasan/optfuzz_build/tiff2pdf
for BIN_NAME in $BIN_NAMES; do
  cd ../$BIN_NAME
  get-bc $BIN_NAME
  llvm-dis-15 $BIN_NAME.bc
  python /workspace/OptFuzzer/gen_graph_dev_no_dot_15_noasan.py $BIN_NAME.ll $BIN_NAME $PWD/../instrument_meta_data
done

else
    echo "Invalid usage. Use as $0 <aflpp/cmplog>"
fi

cd -
