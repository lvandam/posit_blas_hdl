#ifndef __UTILS_H
#define __UTILS_H

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <posit/posit>

#include "debug_values.hpp"
#include "defines.hpp"

using namespace std;
using namespace sw::unum;

cpp_dec_float_100 decimal_accuracy(cpp_dec_float_100 exact, cpp_dec_float_100 computed);

void writeBenchmark(DebugValues<posit<NBITS, ES> > &hw_debug_values, DebugValues<posit<NBITS, ES> > &sw_debug_values, DebugValues<float> &float_debug_values,
    DebugValues<cpp_dec_float_100> &dec_debug_values, std::string filename);

#endif //__UTILS_H
