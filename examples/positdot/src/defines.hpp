#ifndef __DEFINES_H
#define __DEFINES_H

#include <posit/posit>

using namespace std;
using namespace sw::unum;

// POSIT CONFIGURATION
#define NBITS 32
#define ES 3

// For value debugging
struct Entry {
    string name;
    cpp_dec_float_100 value;
};

struct find_entry {
    string name;

    find_entry(string name) : name(name) {}

    bool operator()(const Entry &m) const {
        return m.name == name;
    }
};

template <typename T>
std::string to_string_precision(const T a_value, const int n = 20)
{
    std::ostringstream out;
    out << std::setprecision(n) << a_value;
    return out.str();
}

#endif
