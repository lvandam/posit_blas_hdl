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

cpp_dec_float_50 decimal_accuracy(cpp_dec_float_50 exact, cpp_dec_float_50 computed);

// void writeBenchmark(PairHMMFloat<cpp_dec_float_50> &pairhmm_dec50, PairHMMFloat<float> &pairhmm_float,
//                     PairHMMPosit &pairhmm_posit, DebugValues<posit<NBITS, ES>> &hw_debug_values,
//                     std::string filename = "pairhmm_values.txt", bool printDate = true, bool overwrite = false);

int roundToMultiple(int toRound, int multiple);

#endif //__UTILS_H
