#!/bin/bash

cd $(dirname `readlink -f "$0"`)

[ ! -d ./build ] && mkdir ./build
cd ./build && cmake .. && make && ./test-main


