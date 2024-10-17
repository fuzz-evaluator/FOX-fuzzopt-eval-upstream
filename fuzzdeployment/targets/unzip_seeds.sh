#!/bin/bash
dirs=(
    "./openssl"
    "./sqlite3"
    "./systemd"
    "./bloaty"
    "./vorbis"
    "./harfbuzz"
    "./mbedtls"
    "./libxml2_xml"
    "./libjpeg"
    "./libpng_read_fuzzer"
    "./openh264"
    "./woff2"
    "./libxslt"
)

for dir in "${dirs[@]}"; do
    for file in "$dir/seeds_fuzzbench."*; do
        if [[ -e "$file" ]]; then
            target_dir="$dir"
            mkdir -p "$target_dir"

            case "$file" in
                *.tar.gz)
                    tar -xzf "$file" -C "$target_dir"
                    ;;
                *.zip)
                    unzip -o "$file" -d "$target_dir/seeds_fuzzbench"
                    ;;
            esac
        fi
    done
done
