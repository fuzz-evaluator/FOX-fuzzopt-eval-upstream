#!/bin/bash
set -e

# USAGE
VARIANT=$1
BIN_NAME="fuzz-link-parser"

if [ "$VARIANT" = aflpp ]; then

rm -rf ./binaries/aflpp_build
mkdir -p ./binaries/aflpp_build
cd systemd 
git clean -df 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
# If a dict has not been generated, generate it
if [ ! -f $PWD/../dict/keyval.dict ]; then
    mkdir -p $PWD/../dict
    export AFL_LLVM_DICT2FILE=$PWD/../dict/keyval.dict
fi

mkdir -p ../binaries/aflpp_build
./build.sh
cp out/fuzz-link-parser ../binaries/aflpp_build
cp out/src/shared/*.so ../binaries/aflpp_build
cd ../binaries/aflpp_build
patchelf --set-rpath $PWD fuzz-link-parser


elif [ "$VARIANT" = cmplog ]; then

rm -rf ./binaries/cmplog_build
mkdir -p ./binaries/cmplog_build

cd systemd
git clean -df 
export ASAN_OPTIONS=detect_leaks=0
export AFL_USE_ASAN=1
export AFL_LLVM_CMPLOG=1
export CC=/workspace/AFLplusplus/afl-clang-fast
export CXX=/workspace/AFLplusplus/afl-clang-fast++
mkdir -p ../binaries/cmplog_build
./build.sh
cp out/fuzz-link-parser ../binaries/cmplog_build
cp out/src/shared/*.so ../binaries/cmplog_build
cd ../binaries/cmplog_build
patchelf --set-rpath $PWD fuzz-link-parser

elif [ "$VARIANT" = optfuzz ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build
# 
cd systemd
git clean -df
export AFL_CC=gclang
export AFL_CXX=gclang++
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
rm -f /dev/shm/*
./build.sh
cp out/fuzz-link-parser ../binaries/optfuzz_build
cp out/src/shared/*.so ../binaries/optfuzz_build
cd ../binaries/optfuzz_build
patchelf --set-rpath $PWD fuzz-link-parser
cd -
# 
# # Create auxiliary files
cd ../binaries/optfuzz_build/
cp /dev/shm/instrument_meta_data .
get-bc $BIN_NAME
llvm-dis-15 $BIN_NAME.bc
python /workspace/fuzzopt-eval/fuzzdeployment/fix_long_fun_name.py $BIN_NAME.ll
mkdir -p cfg_out_$BIN_NAME
cd cfg_out_$BIN_NAME
opt -dot-cfg ../$BIN_NAME\_fix.ll
for f in $(ls -a | grep '^\.*'|grep dot);do mv $f ${f:1};done
cd ..
# python /workspace/fuzzopt-eval/fuzzdeployment/gen_graph_dev_orig.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME
# python /workspace/OptFuzzer/gen_graph_dev_check.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME
python /workspace/OptFuzzer/gen_graph_dev_refactor.py $BIN_NAME\_fix.ll cfg_out_$BIN_NAME $PWD/$BIN_NAME instrument_meta_data

elif [ "$VARIANT" = optfuzz_nogllvm ]; then

rm -rf ./binaries/optfuzz_build
mkdir -p ./binaries/optfuzz_build

cd systemd
git clean -df
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
export CC=/workspace/OptFuzzer/afl-clang-fast
export CXX=/workspace/OptFuzzer/afl-clang-fast++
./build.sh
cp out/fuzz-link-parser ../binaries/optfuzz_build
cp out/src/shared/*.so ../binaries/optfuzz_build

cd ../binaries/optfuzz_build
patchelf --set-rpath $PWD fuzz-link-parser
cd -

cp /dev/shm/instrument_meta_data ../binaries/optfuzz_build/

cd ../binaries/optfuzz_build/

AFL_DEBUG=1 ./fuzz-link-parser > afl_debug_out 2>&1 &
sleep 1
kill -9 `pidof fuzz-link-parser`
VAR1=`awk '/Done __sanitizer_cov_trace_pc_guard_init: __afl_final_loc =/ {print $NF; exit}' afl_debug_out`
python /workspace/OptFuzzer/gen_graph_no_gllvm_15_systemd.py libsystemd-shared-251.so instrument_meta_data 6 0
VAR2=`cat max_border_edge_id_6`
python /workspace/OptFuzzer/gen_graph_no_gllvm_15_systemd.py fuzz-link-parser instrument_meta_data $VAR1 $VAR2

cat border_edges_cache_6 border_edges_cache_$VAR1 > border_edges_cache
cat br_node_id_2_cmp_type_6 br_node_id_2_cmp_type_$VAR1 > br_node_id_2_cmp_type
cat border_edges_6 border_edges_$VAR1 > border_edges
cp max_border_edge_id_$VAR1 max_border_edge_id
cp max_br_dist_edge_id_$VAR1 max_br_dist_edge_id

else 
    echo "Invalid usage. Use as $0 <aflpp/cmplog>" 
fi

cd -
