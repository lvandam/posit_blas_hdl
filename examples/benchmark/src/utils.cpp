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
using boost::multiprecision::cpp_dec_float_100;

cpp_dec_float_100 decimal_accuracy(cpp_dec_float_100 exact, cpp_dec_float_100 computed) {
        if (boost::math::isnan(exact) || boost::math::isnan(computed) ||
            (boost::math::sign(exact) != boost::math::sign(computed))) {
                return std::numeric_limits<cpp_dec_float_100>::quiet_NaN();
        } else if (exact == computed) {
                return std::numeric_limits<cpp_dec_float_100>::infinity();
        } else if ((exact == std::numeric_limits<cpp_dec_float_100>::infinity() &&
                    computed != std::numeric_limits<cpp_dec_float_100>::infinity()) ||
                   (exact != std::numeric_limits<cpp_dec_float_100>::infinity() &&
                    computed == std::numeric_limits<cpp_dec_float_100>::infinity()) || (exact == 0 && computed != 0) ||
                   (exact != 0 && computed == 0)) {
                return -std::numeric_limits<cpp_dec_float_100>::infinity();
        } else {
                return -log10(abs(log10(computed / exact)));
        }
}

void writeBenchmark(DebugValues<posit<NBITS, ES> > &hw_debug_values, DebugValues<posit<NBITS, ES> > &sw_debug_values, DebugValues<float> &float_debug_values,
                    DebugValues<cpp_dec_float_100> &dec_debug_values, std::string filename) {
        ofstream outfile(filename, ios::out);

        auto dec_values = dec_debug_values.items;
        auto hw_values = hw_debug_values.items;
        auto sw_values = sw_debug_values.items;
        auto float_values = float_debug_values.items;

        outfile << "name,dE_f,dE_sw,dE_hw,log(abs(dE_f)),log(abs(dE_sw)),log(abs(dE_hw)),E,E_f,E_sw,E_hw,da_F,da_SW,da_HW" << endl;
        for (int i = 0; i < dec_values.size(); i++) {
                cpp_dec_float_100 E, E_f, E_p, E_hw, E_sw, dE_f, dE_p, dE_hw, dE_sw;
                cpp_dec_float_100 da_F, da_HW, da_SW; // decimal accuracies

                string name = dec_values[i].name;
                E = dec_values[i].value;

                auto E_f_entry = std::find_if(float_values.begin(), float_values.end(), find_entry(name));
                E_f = E_f_entry->value;

                auto E_hw_entry = std::find_if(hw_values.begin(), hw_values.end(), find_entry(name));
                E_hw = E_hw_entry->value;

                auto E_sw_entry = std::find_if(sw_values.begin(), sw_values.end(), find_entry(name));
                E_sw = E_sw_entry->value;

                if (name != E_f_entry->name || name != E_sw_entry->name || name != E_hw_entry->name) {
                        cout << "Error: mismatching names! Could not find name '" << E_f_entry->name << endl;
                }

                cout << "Decimal accuracy..." << endl;
                da_F = decimal_accuracy(E, E_f);
                da_HW = decimal_accuracy(E, E_hw);
                da_SW = decimal_accuracy(E, E_sw);

                if (E == 0) {
                        dE_f = 0;
                        dE_sw = 0;
                        dE_hw = 0;
                } else {
                        dE_f = (E_f - E) / E;
                        dE_sw = (E_sw - E) / E;
                        dE_hw = (E_hw - E) / E;
                }

                cout << "Writing out..." << endl;

                // Relative error values
                outfile << name << ",";
                outfile << setprecision(100) << fixed << dE_f << "," << dE_sw << "," << dE_hw << "," << flush;
                outfile << setprecision(100) << fixed << log10(abs(dE_f)) << "," << log10(abs(dE_sw)) << "," << log10(abs(dE_hw)) << "," << flush;
                outfile << setprecision(100) << fixed << E << "," << E_f << "," << E_sw << "," << E_hw << "," << flush;
                outfile << setprecision(100) << fixed << da_F << "," << da_SW << "," << da_HW << endl << flush;
        }
        cout << "Closing file..." << endl;
        outfile.close();
}
