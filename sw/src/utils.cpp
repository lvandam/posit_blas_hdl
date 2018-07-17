#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include <chrono>
#include <ctime>
#include <iostream>
#include <cmath>
#include <cfloat>

#include <posit/posit>
#include <boost/range/combine.hpp>
#include <boost/multiprecision/cpp_dec_float.hpp>

#include "defines.hpp"
#include "utils.hpp"

using namespace std;
using namespace sw::unum;
using boost::multiprecision::cpp_dec_float_50;

cpp_dec_float_50 decimal_accuracy(cpp_dec_float_50 exact, cpp_dec_float_50 computed) {
        if (boost::math::isnan(exact) || boost::math::isnan(computed) ||
            (boost::math::sign(exact) != boost::math::sign(computed))) {
                return std::numeric_limits<cpp_dec_float_50>::quiet_NaN();
        } else if (exact == computed) {
                return std::numeric_limits<cpp_dec_float_50>::infinity();
        } else if ((exact == std::numeric_limits<cpp_dec_float_50>::infinity() &&
                    computed != std::numeric_limits<cpp_dec_float_50>::infinity()) ||
                   (exact != std::numeric_limits<cpp_dec_float_50>::infinity() &&
                    computed == std::numeric_limits<cpp_dec_float_50>::infinity()) || (exact == 0 && computed != 0) ||
                   (exact != 0 && computed == 0)) {
                return -std::numeric_limits<cpp_dec_float_50>::infinity();
        } else {
                return -log10(abs(log10(computed / exact)));
        }
}

// void writeBenchmark(PairHMMFloat<cpp_dec_float_50> &pairhmm_dec50, PairHMMFloat<float> &pairhmm_float,
//                     PairHMMPosit &pairhmm_posit, DebugValues<posit<NBITS, ES> > &hw_debug_values, std::string filename,
//                     bool printDate, bool overwrite) {
//         time_t t = chrono::system_clock::to_time_t(chrono::system_clock::now());
//
//         ofstream outfile(filename, ios::out);
//         if (printDate)
//                 outfile << endl << ctime(&t) << endl << "===================" << endl;
//
//         auto dec_values = pairhmm_dec50.debug_values.items;
//         auto float_values = pairhmm_float.debug_values.items;
//         auto posit_values = pairhmm_posit.debug_values.items;
//         auto hw_values = hw_debug_values.items;
//
//         outfile << "name,dE_f,dE_p,dE_hw,log(abs(dE_f)),log(abs(dE_p)),log(abs(dE_hw)),E,E_f,E_p,E_hw,da_F,da_P,da_HW"
//                 << endl;
//         for (int i = 0; i < dec_values.size(); i++) {
//                 cpp_dec_float_50 E, E_f, E_p, E_hw, dE_f, dE_p, dE_hw;
//                 cpp_dec_float_50 da_F, da_P, da_HW; // decimal accuracies
//
//                 string name = dec_values[i].name;
//                 E = dec_values[i].value;
//
//                 auto E_f_entry = std::find_if(float_values.begin(), float_values.end(), find_entry(name));
//                 E_f = E_f_entry->value;
//
//                 auto E_p_entry = std::find_if(posit_values.begin(), posit_values.end(), find_entry(name));
//                 E_p = E_p_entry->value;
//
//                 auto E_hw_entry = std::find_if(hw_values.begin(), hw_values.end(), find_entry(name));
//                 E_hw = E_hw_entry->value;
//
//                 if (name != E_f_entry->name || name != E_p_entry->name || name != E_hw_entry->name) {
//                         cout << "Error: mismatching names! Could not find name '" << E_f_entry->name << endl;
//                 }
//
//                 da_F = decimal_accuracy(E, E_f);
//                 da_P = decimal_accuracy(E, E_p);
//                 da_HW = decimal_accuracy(E, E_hw);
//
//                 if (E == 0) {
//                         dE_f = 0;
//                         dE_p = 0;
//                         dE_hw = 0;
//                 } else {
//                         dE_f = (E_f - E) / E;
//                         dE_p = (E_p - E) / E;
//                         dE_hw = (E_hw - E) / E;
//                 }
//
//                 // Relative error values
//                 outfile << setprecision(50) << fixed << name << ","
//                         << dE_f << "," << dE_p << "," << dE_hw << ","
//                         << log10(abs(dE_f)) << "," << log10(abs(dE_p)) << "," << log10(abs(dE_hw)) << ","
//                         << E << "," << E_f << "," << E_p << "," << E_hw << ","
//                         << da_F << "," << da_P << "," << da_HW << endl;
//         }
//         outfile.close();
// }

int roundToMultiple(int toRound, int multiple) {
    toRound += multiple / 2;
    return toRound - (toRound%multiple);
}
