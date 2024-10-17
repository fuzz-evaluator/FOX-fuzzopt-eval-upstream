#!/bin/bash

if [ ! -d openthread ]; then
    git clone https://github.com/openthread/openthread  
    git -C openthread checkout 25506997f286fdbfa72725f4cee78c922c896255
fi
