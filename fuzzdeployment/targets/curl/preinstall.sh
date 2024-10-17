#!/bin/bash

if [ ! -d curl ]; then
	git clone https://github.com/curl/curl.git
	git -C curl checkout -f a20f74a16ae1e89be170eeaa6059b37e513392a4 
fi

if [ ! -d curl_fuzzer ]; then
	git clone https://github.com/curl/curl-fuzzer.git curl_fuzzer
	git -C curl_fuzzer checkout -f dd486c1e5910e722e43c451d4de928ac80f5967d
fi

sudo ./curl_fuzzer/scripts/ossfuzzdeps.sh

