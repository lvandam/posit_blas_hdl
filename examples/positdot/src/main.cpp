#include <cstdint>
#include <memory>
#include <vector>
#include <string>
#include <numeric>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <omp.h>
#include <stdio.h>
#include <valarray>
#include <boost/range/combine.hpp>
#include <boost/multiprecision/cpp_dec_float.hpp>

#include <boost/numeric/mtl/mtl.hpp>
#include <boost/numeric/itl/itl.hpp>

#include <posit/posit>
// Posit Arithmetic FPGA accelerator library
#include <positarith.h>

#include "main.hpp"
#include "defines.hpp"
#include "utils.hpp"
#include "blas.hpp"
#include "vector_utils.hpp"
#include "matrix_utils.hpp"

using namespace std;
using namespace sw::unum;
using boost::multiprecision::cpp_dec_float_100;

posit<NBITS, ES> random_number(float offset, float dev) {
    float num_float;
    posit<NBITS, 2> num_posit_2;
    posit<NBITS, 3> num_posit_3;

    do {
        num_float = offset + (rand() * dev / RAND_MAX);
        num_posit_2 = num_float;
        num_posit_3 = num_float;
    } while (num_posit_2 != num_float || num_posit_3 != num_float);

    return posit<NBITS, ES>(num_float);
}

int main(int argc, char ** argv)
{
    vector<int> lengths = {10, 20, 30, 40, 50, 100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 10000, 20000, 30000, 40000, 50000, 100000, 200000, 300000, 400000, 500000};

    std::string s_dot;
    for(int length : lengths) {
        s_dot = test_dot_product(length);

        ofstream outfile("positarith_dot_es" + std::to_string(ES) + "_" + std::to_string(length) + ".txt", ios::out);
        outfile << s_dot << endl;
        outfile.close();

        remove("top.wdb");
    }

    return 0;
}

std::string test_dot_product(int length) {
    double t_fpga, t_sw, t_float;
    double stop, start;
    int i;
    cpp_dec_float_100 da_sw = 0.0, da_hw = 0.0, da_float = 0.0;

    // Test data set
    std::vector<posit<NBITS,ES>> vec1, vec2;
    // vec1.resize(length); vec2.resize(length);
    for(int i = 0; i < length; i++) {
        posit<NBITS,ES> pos1, pos2;
        pos1 = random_number(0.0, 1.0);
        pos2 = random_number(0.0, 1.0);

        vec1.push_back(pos1);
        vec2.push_back(pos2);
    }

    // Posit HW calculation
    posit<NBITS,ES> res_hw = 0;
    // t_fpga = vector_dot(vec1, vec2, res_hw);

    // Posit SW calculation
    posit<NBITS,ES> res_sw = 0.0;
    start = omp_get_wtime();
    // for(i = 0; i < length; i++) {
    //     res_sw += vec1[i] * vec2[i];
    // }
    res_sw = sw::hprblas::dot(length, vec1, 1, vec2, 1);
    stop = omp_get_wtime();
    t_sw = stop - start;

    // Float calculation
    float res_float = 0.0;
    start = omp_get_wtime();
    #pragma omp parallel private(i) num_threads(8)
    {
        #pragma omp for reduction(+:res_float)
        for(i = 0; i < length; i++) {
            res_float += (float)vec1[i] * (float)vec2[i];
        }
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    // Reference calculation
    cpp_dec_float_100 res_dec = 0.0;
    for(int i = 0; i < length; i++) {
        res_dec += (cpp_dec_float_100)((long double)vec1[i]) * (cpp_dec_float_100)((long double)vec2[i]);
    }

    // Calculate decimal accuracy
    da_float = decimal_accuracy(res_dec, (cpp_dec_float_100)res_float);
    da_sw = decimal_accuracy(res_dec, (cpp_dec_float_100)((long double)res_sw));
    da_hw = decimal_accuracy(res_dec, (cpp_dec_float_100)((long double)res_hw));

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float) + "," + to_string_precision(da_hw) + "," + to_string_precision(da_sw) + "," + to_string_precision(da_float);
}
