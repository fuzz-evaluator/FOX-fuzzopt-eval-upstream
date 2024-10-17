#!/bin/bash
set -e

# USAFE
VARIANT=$1
BIN_NAME="curl_fuzzer_http"

#XXX: Make sure to not run this command while inside virtualenv 
if [ "$VARIANT" = aflpp ]; then

export SRCDIR=$PWD/curl
export INSTALLDIR=$PWD/curl_install
export FUZZ_TARGETS=curl_fuzzer_http

if [ -d ${INSTALLDIR} ]; then
  rm -rf ${INSTALLDIR}
  rm -rf curl
  rm -rf curl_fuzzer
  rm -rf openssl
  rm -rf zlib
  rm -rf nghttp2
  ./preinstall.sh
fi

cd curl_fuzzer

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export LIB_FUZZING_ENGINE=/workspace/AFLplusplus/libAFLDriver.a
if [ ! -f ../dict/keyval.dict ]; then
    cp -v ossconfig/http.dict ../dict/keyval.dict
fi

rm -rf ../binaries/aflpp_build
mkdir -p ../binaries/aflpp_build
export MAKEFLAGS+="-j$(nproc)"
export ZLIBSRC=$PWD/../zlib
export OPENSSLSRC=$PWD/../openssl
export NGHTTP2SRC=$PWD/../nghttp2


set -ex

OPTIND=1
CODE_COVERAGE_OPTION=""

while getopts "c" opt
do
	case "$opt" in
		c) CODE_COVERAGE_OPTION="--enable-code-coverage"
           ;;
    esac
done

shift $((OPTIND-1))

if [[ ! -d ${INSTALLDIR} ]]
then
  # Make an install target for curl.
  mkdir -p ${INSTALLDIR}
fi
bash $PWD/scripts/download_zlib.sh $ZLIBSRC
bash $PWD/scripts/download_openssl.sh $OPENSSLSRC
bash $PWD/scripts/download_nghttp2.sh $NGHTTP2SRC

bash $PWD/scripts/install_zlib.sh $ZLIBSRC $INSTALLDIR
bash $PWD/scripts/install_openssl.sh $OPENSSLSRC $INSTALLDIR
bash $PWD/scripts/install_nghttp2.sh $NGHTTP2SRC $INSTALLDIR

if [[ -f ${INSTALLDIR}/lib/libssl.a ]]
then
  SSLOPTION=--with-ssl=${INSTALLDIR}
else
  SSLOPTION=--without-ssl
fi

if [[ -f ${INSTALLDIR}/lib/libnghttp2.a ]]
then
  NGHTTPOPTION=--with-nghttp2=${INSTALLDIR}
else
  NGHTTPOPTION=--without-nghttp2
fi

pushd ${SRCDIR}

# Build the library.
./buildconf
./configure --prefix=${INSTALLDIR} --disable-shared --enable-debug \
            --enable-maintainer-mode --disable-symbol-hiding --enable-ipv6 \
            --enable-websockets --with-random=/dev/null \
            ${SSLOPTION} \
            ${NGHTTPOPTION} \
            ${CODE_COVERAGE_OPTION}

make V=1
make install

# Make any explicit folders which are post install
UTFUZZDIR=${INSTALLDIR}/utfuzzer
mkdir -p ${UTFUZZDIR}

# Copy header files.
cp -v lib/curl_fnmatch.h ${UTFUZZDIR}

popd

# Build the fuzzers.
./buildconf || exit 2
./configure ${CODE_COVERAGE_OPTION} || exit 3
make || exit 4
make check || exit 5

for TARGET in $FUZZ_TARGETS
do
  cp -v ${TARGET} ../binaries/aflpp_build
done

elif [ "$VARIANT" = cmplog ]; then

export SRCDIR=$PWD/curl
export INSTALLDIR=$PWD/curl_install
export FUZZ_TARGETS=curl_fuzzer_http

if [ -d ${INSTALLDIR} ]; then
  rm -rf ${INSTALLDIR}
  rm -rf curl
  rm -rf openssl
  rm -rf zlib
  rm -rf nghttp2
  rm -rf curl_fuzzer
  ./preinstall.sh
fi

cd curl_fuzzer

export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
export LIB_FUZZING_ENGINE=/workspace/AFLplusplus/libAFLDriver.a

rm -rf ../binaries/cmplog_build
mkdir -p ../binaries/cmplog_build
export MAKEFLAGS+="-j$(nproc)"
export ZLIBSRC=$PWD/../zlib
export OPENSSLSRC=$PWD/../openssl
export NGHTTP2SRC=$PWD/../nghttp2

set -ex

OPTIND=1
CODE_COVERAGE_OPTION=""

while getopts "c" opt
do
	case "$opt" in
		c) CODE_COVERAGE_OPTION="--enable-code-coverage"
           ;;
    esac
done

shift $((OPTIND-1))

if [[ ! -d ${INSTALLDIR} ]]
then
  # Make an install target for curl.
  mkdir -p ${INSTALLDIR}
fi
bash $PWD/scripts/download_zlib.sh $ZLIBSRC
bash $PWD/scripts/download_openssl.sh $OPENSSLSRC
bash $PWD/scripts/download_nghttp2.sh $NGHTTP2SRC

bash $PWD/scripts/install_zlib.sh $ZLIBSRC $INSTALLDIR
bash $PWD/scripts/install_openssl.sh $OPENSSLSRC $INSTALLDIR
bash $PWD/scripts/install_nghttp2.sh $NGHTTP2SRC $INSTALLDIR

if [[ -f ${INSTALLDIR}/lib/libssl.a ]]
then
  SSLOPTION=--with-ssl=${INSTALLDIR}
else
  SSLOPTION=--without-ssl
fi

if [[ -f ${INSTALLDIR}/lib/libnghttp2.a ]]
then
  NGHTTPOPTION=--with-nghttp2=${INSTALLDIR}
else
  NGHTTPOPTION=--without-nghttp2
fi

pushd ${SRCDIR}

# Build the library.
./buildconf
./configure --prefix=${INSTALLDIR} --disable-shared --enable-debug \
            --enable-maintainer-mode --disable-symbol-hiding --enable-ipv6 \
            --enable-websockets --with-random=/dev/null \
            ${SSLOPTION} \
            ${NGHTTPOPTION} \
            ${CODE_COVERAGE_OPTION}

make V=1
make install

# Make any explicit folders which are post install
UTFUZZDIR=${INSTALLDIR}/utfuzzer
mkdir -p ${UTFUZZDIR}

# Copy header files.
cp -v lib/curl_fnmatch.h ${UTFUZZDIR}

popd

# Build the fuzzers.
./buildconf || exit 2
./configure ${CODE_COVERAGE_OPTION} || exit 3
make || exit 4
make check || exit 5

for TARGET in $FUZZ_TARGETS
do
  cp -v ${TARGET} ../binaries/cmplog_build
done

elif [ "$VARIANT" = optfuzz ]; then 

export SRCDIR=$PWD/curl
export INSTALLDIR=$PWD/curl_install
export FUZZ_TARGETS=curl_fuzzer_http

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

if [ -d ${INSTALLDIR} ]; then
  rm -rf ${INSTALLDIR}
  rm -rf curl
  rm -rf openssl
  rm -rf zlib
  rm -rf nghttp2
  rm -rf curl_fuzzer
  ./preinstall.sh
fi

cd curl_fuzzer

export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export LIB_FUZZING_ENGINE=/workspace/OptFuzzer/libAFLDriver.a
export AFL_LLVM_LOG_PATH=$PWD/../meta/
export AFL_IGNORE_UNKNOWN_ENVS=1
rm -rf $AFL_LLVM_LOG_PATH
mkdir $AFL_LLVM_LOG_PATH

rm -f /dev/shm/*
mkdir -p ../binaries/optfuzz_build
export MAKEFLAGS+="-j$(nproc)"
export ZLIBSRC=$PWD/../zlib
export OPENSSLSRC=$PWD/../openssl
export NGHTTP2SRC=$PWD/../nghttp2
set -ex

OPTIND=1
CODE_COVERAGE_OPTION=""

while getopts "c" opt
do
	case "$opt" in
		c) CODE_COVERAGE_OPTION="--enable-code-coverage"
           ;;
    esac
done

shift $((OPTIND-1))

if [[ ! -d ${INSTALLDIR} ]]
then
  # Make an install target for curl.
  mkdir -p ${INSTALLDIR}
fi

bash $PWD/scripts/download_zlib.sh $ZLIBSRC
bash $PWD/scripts/download_openssl.sh $OPENSSLSRC
bash $PWD/scripts/download_nghttp2.sh $NGHTTP2SRC

bash $PWD/scripts/install_zlib.sh $ZLIBSRC $INSTALLDIR
bash $PWD/scripts/install_openssl.sh $OPENSSLSRC $INSTALLDIR
bash $PWD/scripts/install_nghttp2.sh $NGHTTP2SRC $INSTALLDIR
if [[ -f ${INSTALLDIR}/lib/libssl.a ]]
then
  SSLOPTION=--with-ssl=${INSTALLDIR}
else
  SSLOPTION=--without-ssl
fi

if [[ -f ${INSTALLDIR}/lib/libnghttp2.a ]]
then
  NGHTTPOPTION=--with-nghttp2=${INSTALLDIR}
else
  NGHTTPOPTION=--without-nghttp2
fi

pushd ${SRCDIR}

# Build the library.
./buildconf
./configure --prefix=${INSTALLDIR} --disable-shared --enable-debug --enable-maintainer-mode \
            --disable-symbol-hiding --enable-ipv6 --enable-websockets --with-random=/dev/null --disable-shared \
            ${SSLOPTION} \
            ${NGHTTPOPTION} \
            ${CODE_COVERAGE_OPTION}

make V=1
make install

# Make any explicit folders which are post install
UTFUZZDIR=${INSTALLDIR}/utfuzzer
mkdir -p ${UTFUZZDIR}

# Copy header files.
cp -v lib/curl_fnmatch.h ${UTFUZZDIR}

popd

# Build the fuzzers.
./buildconf || exit 2
./configure ${CODE_COVERAGE_OPTION} || exit 3
make || exit 4
make check || exit 5

for TARGET in $FUZZ_TARGETS
do
  cp -v ${TARGET} ../binaries/optfuzz_build
done

cp $AFL_LLVM_LOG_PATH/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
# python /workspace/fuzzopt-eval/fuzzdeployment/OptFuzzer_refactor/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_refactor.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME instrument_meta_data
python /workspace/OptFuzzer/gen_graph_dev_no_dot_15.py $BIN_NAME.ll $BIN_NAME $PWD/instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

export SRCDIR=$PWD/curl
export INSTALLDIR=$PWD/curl_install
export FUZZ_TARGETS=curl_fuzzer_http

rm -rf /dev/shm/*
rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

if [ -d ${INSTALLDIR} ]; then
  rm -rf ${INSTALLDIR}
  rm -rf curl
  rm -rf openssl
  rm -rf zlib
  rm -rf nghttp2
  rm -rf curl_fuzzer
  ./preinstall.sh
fi

cd curl_fuzzer

export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
export LIB_FUZZING_ENGINE=/workspace/OptFuzzer/libAFLDriver.a
export AFL_IGNORE_UNKNOWN_ENVS=1

export MAKEFLAGS+="-j$(nproc)"
export ZLIBSRC=$PWD/../zlib
export OPENSSLSRC=$PWD/../openssl
export NGHTTP2SRC=$PWD/../nghttp2
set -ex

OPTIND=1
CODE_COVERAGE_OPTION=""

while getopts "c" opt
do
	case "$opt" in
		c) CODE_COVERAGE_OPTION="--enable-code-coverage"
           ;;
    esac
done

shift $((OPTIND-1))

if [[ ! -d ${INSTALLDIR} ]]
then
  # Make an install target for curl.
  mkdir -p ${INSTALLDIR}
fi

bash $PWD/scripts/download_zlib.sh $ZLIBSRC
bash $PWD/scripts/download_openssl.sh $OPENSSLSRC
bash $PWD/scripts/download_nghttp2.sh $NGHTTP2SRC

bash $PWD/scripts/install_zlib.sh $ZLIBSRC $INSTALLDIR
bash $PWD/scripts/install_openssl.sh $OPENSSLSRC $INSTALLDIR
bash $PWD/scripts/install_nghttp2.sh $NGHTTP2SRC $INSTALLDIR
if [[ -f ${INSTALLDIR}/lib/libssl.a ]]
then
  SSLOPTION=--with-ssl=${INSTALLDIR}
else
  SSLOPTION=--without-ssl
fi

if [[ -f ${INSTALLDIR}/lib/libnghttp2.a ]]
then
  NGHTTPOPTION=--with-nghttp2=${INSTALLDIR}
else
  NGHTTPOPTION=--without-nghttp2
fi

pushd ${SRCDIR}

# Build the library.
./buildconf
./configure --prefix=${INSTALLDIR} --disable-shared --enable-debug --enable-maintainer-mode \
            --disable-symbol-hiding --enable-ipv6 --enable-websockets --with-random=/dev/null --disable-shared \
            ${SSLOPTION} \
            ${NGHTTPOPTION} \
            ${CODE_COVERAGE_OPTION}

make V=1
make install

# Make any explicit folders which are post install
UTFUZZDIR=${INSTALLDIR}/utfuzzer
mkdir -p ${UTFUZZDIR}

# Copy header files.
cp -v lib/curl_fnmatch.h ${UTFUZZDIR}

popd

# Build the fuzzers.
./buildconf || exit 2
./configure ${CODE_COVERAGE_OPTION} || exit 3
make || exit 4
make check || exit 5

for TARGET in $FUZZ_TARGETS
do
  cp -v ${TARGET} ../binaries/optfuzz_build
done

cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build

cd ../binaries/optfuzz_build

python /workspace/OptFuzzer/gen_graph_no_gllvm_15.py $BIN_NAME $PWD/instrument_meta_data

else 
	echo "Invalid usage. Use as $0 <aflpp/cmplog/optfuzz>"
fi

cd -
