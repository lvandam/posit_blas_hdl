#ifndef __DEFINES_H
#define __DEFINES_H

#include <posit/posit>

using namespace std;
using namespace sw::unum;

// POSIT CONFIGURATION
#define NBITS 32
#define ES 2

#ifndef DEBUG_PRECISION
#define DEBUG_PRECISION 40
#endif // DEBUG_PRECISION

// The error margin allowed
#define ERROR_MARGIN             0.0000001
#define ERR_LOWER                1.0f - ERROR_MARGIN
#define ERR_UPPER                1.0f + ERROR_MARGIN

// Debug printf macro
#ifdef DEBUG
#define DEBUG_PRINT(...)    do { fprintf(stderr, __VA_ARGS__); } while (0)
#define BENCH_PRINT(...)    do { } while (0)
#else
#define DEBUG_PRINT(...)    do { } while (0)
#define BENCH_PRINT(...)    do { fprintf(stderr, __VA_ARGS__); } while (0)
#endif

typedef union union_32 {
    float f; // as float
    uint32_t b;    // as binary
    unsigned char x[sizeof(float)]; // as bytes
} t_32;

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

template<size_t nbits>
std::string hexstring(bitblock<nbits> bits) {
    char str[8];
    const char *hexits = "0123456789ABCDEF";
    unsigned int max = 8;
    for (unsigned int i = 0; i < max; i++) {
        unsigned int hexit = (bits[3] << 3) + (bits[2] << 2) + (bits[1] << 1) + bits[0];
        str[max - 1 - i] = hexits[hexit];
        bits >>= 4;
    }
    return std::string(str);
}

template<size_t nbits, size_t es>
uint32_t to_uint(posit<nbits, es> number) {
    return (uint32_t) number.collect().to_ulong();
}

#endif //__DEFINES_H
