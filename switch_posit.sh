#!/bin/bash

ES=$1 # Exponent bits

cd hw && rm posit_package.vhd && rm -rf posit_rtl
ln -s ../posit_conf/posit_package_es$1.vhd posit_package.vhd
ln -s ../posit/es$1/ posit_rtl

cd ../sw
sed -i "s/define ES ./define ES $1/g" src/defines.hpp
mkdir -p build && cd build && cmake .. -DRUNTIME_PLATFORM=2 -DENABLE_DEBUG=ON && make
