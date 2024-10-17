#!/bin/bash

if [ ! -d lcms ]; then
    git clone https://github.com/mm2/Little-CMS.git lcms
    cd lcms && git checkout f0d9632 && cd - 
fi
