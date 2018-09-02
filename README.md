# Posit Arithmetic Accelerator on FPGA (Apache Arrow, CAPI SNAP)
This repository consists of a hardware design for accelerating vector arithmetic operations for the posit number format.

Both the hardware description of the accelerator as well as a C++ software library is provided. The library can be used in order to easily pass vectors to the FPGA and perform the selected operation on it.

Currently, the following vector operations are supported:
* Vector aggregation (vector dot product, vector sum)
* Vector (scalar) addition
* Vector (scalar) subtraction
* Vector (scalar) multiplication

## Requirements
### CMake 3.3.1+
Available at https://cmake.org/download/, or perhaps through the OS package manager
### Boost C++
For some accuracy measurements I am using the Boost C++ library (version 1.67, but perhaps later versions also work).

A quick tutorial on how to install it can be found at https://www.boost.org/doc/libs/1_67_0/more/getting_started/unix-variants.html.
Perhaps it is also available through the package manager.

### Apache Arrow C++ library
The following instructions are extracted from https://github.com/apache/arrow/tree/master/cpp

#### Dependencies (for Ubuntu/Debian)
```
sudo apt-get install cmake libboost-dev libboost-filesystem-dev libboost-system-dev
```
#### Build
```
git clone https://github.com/apache/arrow.git arrow
git checkout f8cd36a # To ensure compatibility
cd arrow/cpp
mkdir release
cd release
cmake .. -DCMAKE_BUILD_TYPE=Release
make unittest
sudo make install
```
### CAPI SNAP
```
git clone https://github.com/open-power/snap.git snap
git checkout 0313b46 # To ensure compatibility
```
Set the `SNAP_ROOT` environment variable, i.e. by putting this in a `.bashrc` file:
```
export SNAP_ROOT=<PATH_TO_SNAP_FOLDER>
```
Then
```
cd snap
make snap_config
make software
```
### Fletcher Runtime Library
```
git clone https://github.com/lvandam/fletcher.git fletcher
cd fletcher/runtime
mkdir build && cd build
cmake .. -DPLATFORM_SNAP=ON
make
sudo make install
```

### Accelerator Driver Library

#### Compile & Install
```
cd sw
mkdir -p build && cd build
cmake ..
make
sudo make install
```

## FPGA setup
```
sudo capi-flash-script.sh bitfiles/XXXX.bin
```

## Usage
Build and run one of the example programs located in `examples/`.
Make sure to set the parameters in `src/defines.hpp` according to the posit configuration used!
```
cd examples/gram
mkdir -p build && cd build
cmake ..
make
./gram
```
