/**
    @author Laurens van Dam
    @date 19/02/2018
    @copyright 2018 All rights reserved.
**/

#ifndef PAIRHMM_DEBUG_VALUES_HPP
#define PAIRHMM_DEBUG_VALUES_HPP

#include <iostream>
#include <fstream>
#include <iomanip>
#include <vector>
#include <chrono>
#include <ctime>
#include <cstdarg>
#include <boost/multiprecision/cpp_dec_float.hpp>

#include "defines.hpp"

using namespace std;
using boost::multiprecision::cpp_dec_float_100;

template<class T>
class DebugValues {
public:
    std::vector<Entry> items;

    DebugValues() = default;

    void debugValue(T value, const char *format, ...) {
        char buf[1024];

        va_list arglist;
        va_start(arglist, format);
        vsprintf(buf, format, arglist);
        va_end(arglist);

        Entry entry;
        entry.name = string(buf);

        entry.value = static_cast<cpp_dec_float_100>(value);
        items.push_back(entry);

#ifdef DEBUG_VALUES
        cout << buf << " = " << fixed << setprecision(DEBUG_PRECISION) << value << endl;
#endif
    }

    void printDebugValues() {
        for (auto el : items) {
            cout << setw(20) << el.name << " = " << fixed << setprecision(DEBUG_PRECISION) << el.value << endl;
        }
    }

    void exportDebugValues(string filename) {
        time_t t = chrono::system_clock::to_time_t(chrono::system_clock::now());

        ofstream outfile(filename, ios::out | ios::app);
        outfile << endl << ctime(&t) << endl << "===================" << endl;

        for (auto el : items) {
            outfile << el.name << "," << fixed << setprecision(DEBUG_PRECISION) << el.value << endl;
        }

        outfile.close();
    }

    std::vector<std::string> getNames() {
        std::vector<std::string> result;
        for (auto el : items) {
            result.push_back(el.name);
        }
        return result;
    }

    std::vector<cpp_dec_float_100> getValues() {
        std::vector<cpp_dec_float_100> result;
        for (auto el : items) {
            result.push_back(el.value);
        }
        return result;
    }
};


#endif //PAIRHMM_DEBUG_VALUES_HPP
