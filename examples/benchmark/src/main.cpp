#include <cstdint>
#include <memory>
#include <vector>
#include <string>
#include <numeric>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <omp.h>
#include <valarray>
#include <boost/range/combine.hpp>
#include <boost/multiprecision/cpp_dec_float.hpp>

#include <posit/posit>
// Posit Arithmetic FPGA accelerator library
#include <positarith.h>

#include "main.hpp"
#include "defines.hpp"
#include "utils.hpp"

using namespace std;
using namespace sw::unum;
using boost::multiprecision::cpp_dec_float_100;

void normalizeVector(vector<posit<NBITS,ES>>& vec) {
    posit<NBITS,ES> sum;
    for(posit<NBITS,ES>& el : vec) {
        sum += el * el;
    }
    double sq = sqrt((double)sum);
    for(posit<NBITS,ES>& el : vec) {
        el = el / sq;
    }
}

template<typename T>
void normalizeVector(valarray<T>& vec) {
    T sum;
    for(T& el : vec) {
        sum += el * el;
    }
    T sq = sqrt((T)sum);
    for(T& el : vec) {
        el = el / sq;
    }
}

vector<posit<NBITS, ES> > sumProj(vector<vector<posit<NBITS,ES> > >& v, vector<vector<posit<NBITS,ES> > >& u, int i) {
        int k = 0;
        vector<posit<NBITS,ES> > result(u[0].size());

        while (k < i)
        {
                posit<NBITS,ES> dot_u_u;
                vector_dot(u[k], u[k], dot_u_u);

                posit<NBITS,ES> dot_v_u;
                vector_dot(v[i], u[k], dot_v_u);

                posit<NBITS,ES> factor = dot_v_u / dot_u_u;

                vector<posit<NBITS,ES> > factor_u;
                vector_mult(u[k], factor, factor_u);
                vector_add(result, factor_u, result);

                k++;
        }

        return result;
}

template<typename T>
valarray<T> sumProj(valarray<valarray<T>> v, valarray<valarray<T>> u, int i) {
    int k = 0;
    valarray<T> result(v[0].size());

    while (k < i)
    {
        T dot_u_u = (u[k] * u[k]).sum();
        T dot_v_u = (v[i] * u[k]).sum();
        T factor = dot_v_u / dot_u_u;
        valarray<T> factor_u = factor * u[k];
        result += factor * u[k];
        k++;
    }

    return result;
}

// valarray<posit<NBITS,ES>> sumProj(valarray<valarray<posit<NBITS,ES>>> v, valarray<valarray<posit<NBITS,ES>>> u, int i) {
//     int k = 0;
//     valarray<posit<NBITS,ES>> result(v[0].size());
//
//     while (k < i)
//     {
//         posit<NBITS,ES> dot_u_u = (u[k] * u[k]).sum();
//         posit<NBITS,ES> dot_v_u = (v[i] * u[k]).sum();
//         posit<NBITS,ES> factor = dot_v_u / dot_u_u;
//         valarray<posit<NBITS,ES>> factor_u = factor * u[k];
//         result += factor * u[k];
//
//         k++;
//     }
//
//     return result;
// }

int main(int argc, char ** argv)
{
    vector<int> lengths = {10, 20, 30, 40, 50, 100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 10000, 20000, 30000, 40000, 50000, 100000, 200000, 300000, 400000, 500000, 1000000};

    std::string t_dot, t_sum, t_add, t_add_scalar, t_subtract, t_subtract_scalar, t_mult, t_mult_scalar;

    // for(int length : lengths) {
    //     t_dot = test_dot_product(length);
    //     t_sum = test_sum(length);
    //     t_add = test_add(length);
    //     t_add_scalar = test_add_scalar(length);
    //     t_subtract = test_subtract(length);
    //     t_subtract_scalar = test_subtract_scalar(length);
    //     t_mult = test_mult(length);
    //     t_mult_scalar = test_mult_scalar(length);
    //
    //     ofstream outfile("positarith_es" + std::to_string(ES) + "_" + std::to_string(length) + ".txt", ios::out);
    //     outfile << t_dot << endl;
    //     outfile << t_sum << endl;
    //     outfile << t_add << endl;
    //     outfile << t_add_scalar << endl;
    //     outfile << t_subtract << endl;
    //     outfile << t_subtract_scalar << endl;
    //     outfile << t_mult << endl;
    //     outfile << t_mult_scalar << endl;
    //     outfile.close();
    // }

    vector<int> vectors_vec = {2, 5, 10, 50, 100};
    vector<int> gram_length = {10, 20, 30, 40, 50, 100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 10000, 20000, 30000, 40000, 50000, 100000};

    std::string t_gram;

    for(int vectors : vectors_vec) {
        for(int length : gram_length) {
            t_gram = test_gram(3, length);

            ofstream outfile("positarith_gram_es" + std::to_string(ES) + "_" + std::to_string(vectors) + "_" + std::to_string(length) + ".txt", ios::out);
            outfile << t_gram << endl;
            outfile.close();
        }
    }

    return 0;
}

std::string test_dot_product(int length) {
    double t_fpga, t_sw, t_float;
    double stop, start;
    // Vector Dot Product
    std::vector<posit<NBITS,ES>> vec1, vec2;
    posit<NBITS,ES> result;

    for(int i = 0; i < length; i++) {
        vec1.push_back(1);
        vec2.push_back(i);
    }
    t_fpga = vector_dot(vec1, vec2, result);

    start = omp_get_wtime();
    posit<NBITS,ES> res = 0;
    for(int i = 0; i < length; i++) {
        res = res + vec1[i] * vec2[i];
    }
    stop = omp_get_wtime();
    t_sw = stop - start;

    float res_f = 0;
    std::vector<float> vec1_f, vec2_f;
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(1);
        vec2_f.push_back(i);
    }
    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        res_f = res_f + vec1_f[i] * vec2_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    // std::vector<cpp_dec_float_100> vec1_dec, vec2_dec;
    // for(int i = 0; i < length; i++) {
    //     vec1_dec.push_back(1);
    //     vec2_dec.push_back(i);
    // }
    // for(int i = 0; i < length; i++) {
    //     res_dec = res_dec + vec1_dec[i] * vec2_dec[i];
    // }

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float);
}

std::string test_add(int length) {
    double t_fpga, t_sw, t_float;
    double stop, start;
    // Vector Add
    std::vector<posit<NBITS,ES>> vec1, vec2;
    std::vector<posit<NBITS,ES>> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
        vec2.push_back(i);
    }
    t_fpga = vector_add(vec1, vec2, result);

    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        result[i] = vec1[i] * vec2[i];
    }
    stop = omp_get_wtime();
    t_sw = stop - start;

    std::vector<float> vec1_f, vec2_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
        vec2_f.push_back(i);
    }
    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] * vec2_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    // std::vector<cpp_dec_float_100> vec1_dec, vec2_dec;
    // std::vector<cpp_dec_float_100> res_dec;
    // res_dec.resize(length);
    // for(int i = 0; i < length; i++) {
    //     vec1_dec.push_back(i);
    //     vec2_dec.push_back(i);
    // }
    // for(int i = 0; i < length; i++) {
    //     res_dec[i] = vec1_dec[i] * vec2_dec[i];
    // }

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float);
}

std::string test_add_scalar(int length) {
    double t_fpga, t_sw, t_float;
    double stop, start;
    // Vector Add Scalar
    std::vector<posit<NBITS,ES>> vec1;
    std::vector<posit<NBITS,ES>> result;
    posit<NBITS,ES> scalar;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }
    scalar = 5;
    t_fpga = vector_add(vec1, scalar, result);

    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        result[i] = vec1[i] + scalar;
    }
    stop = omp_get_wtime();
    t_sw = stop - start;

    std::vector<float> vec1_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
    }
    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] + 5.0;
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    // std::vector<cpp_dec_float_100> vec1_dec;
    // std::vector<cpp_dec_float_100> res_dec;
    // res_dec.resize(length);
    // for(int i = 0; i < length; i++) {
    //     vec1_dec.push_back(i);
    // }
    // for(int i = 0; i < length; i++) {
    //     res_dec[i] = vec1_dec[i] + 5.0;
    // }

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float);
}

std::string test_subtract(int length) {
    double t_fpga, t_sw, t_float;
    double stop, start;
    // Vector Subtract
    std::vector<posit<NBITS,ES>> vec1, vec2;
    std::vector<posit<NBITS,ES>> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
        vec2.push_back(i);
    }
    t_fpga = vector_sub(vec1, vec2, result);

    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        result[i] = vec1[i] - vec2[i];
    }
    stop = omp_get_wtime();
    t_sw = stop - start;

    std::vector<float> vec1_f, vec2_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
        vec2_f.push_back(i);
    }
    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] - vec2_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    // std::vector<cpp_dec_float_100> vec1_dec, vec2_dec;
    // std::vector<cpp_dec_float_100> res_dec;
    // res_dec.resize(length);
    // for(int i = 0; i < length; i++) {
    //     vec1_dec.push_back(i);
    //     vec2_dec.push_back(i);
    // }
    // for(int i = 0; i < length; i++) {
    //     res_dec[i] = vec1_dec[i] - vec2_dec[i];
    // }

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float);
}

std::string test_subtract_scalar(int length) {
    double t_fpga, t_sw, t_float;
    double stop, start;
    // Vector Subtract Scalar
    std::vector<posit<NBITS,ES>> vec1;
    std::vector<posit<NBITS,ES>> result;
    posit<NBITS,ES> scalar;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }
    scalar = 5;
    t_fpga = vector_sub(vec1, scalar, result);

    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        result[i] = vec1[i] - scalar;
    }
    stop = omp_get_wtime();
    t_sw = stop - start;

    std::vector<float> vec1_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
    }
    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] - 5.0;
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    // std::vector<cpp_dec_float_100> vec1_dec;
    // std::vector<cpp_dec_float_100> res_dec;
    // res_dec.resize(length);
    // for(int i = 0; i < length; i++) {
    //     vec1_dec.push_back(i);
    // }
    // for(int i = 0; i < length; i++) {
    //     res_dec[i] = vec1_dec[i] - 5.0;
    // }

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float);
}

std::string test_sum(int length) {
    double t_fpga, t_sw, t_float;
    double stop, start;
    // Vector Sum
    std::vector<posit<NBITS,ES>> vec1;
    posit<NBITS,ES> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }
    t_fpga = vector_sum(vec1, result);

    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        result = result + vec1[i];
    }
    stop = omp_get_wtime();
    t_sw = stop - start;

    std::vector<float> vec1_f;
    float res_f = 0.0;
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
    }
    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        res_f = res_f + vec1_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    // std::vector<cpp_dec_float_100> vec1_dec;
    // cpp_dec_float_100 res_dec = 0.0;
    // for(int i = 0; i < length; i++) {
    //     vec1_dec.push_back(i);
    // }
    // for(int i = 0; i < length; i++) {
    //     res_dec = res_dec + vec1_dec[i];
    // }

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float);
}

std::string test_mult(int length) {
    double t_fpga, t_sw, t_float;
    double stop, start;
    // Vector Multiplication
    std::vector<posit<NBITS,ES>> vec1, vec2;
    std::vector<posit<NBITS,ES>> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
        vec2.push_back(i);
    }
    t_fpga = vector_mult(vec1, vec2, result);

    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        result[i] = vec1[i] * vec2[i];
    }
    stop = omp_get_wtime();
    t_sw = stop - start;

    std::vector<float> vec1_f, vec2_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
        vec2_f.push_back(i);
    }
    start = omp_get_wtime();
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] * vec2_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    // std::vector<cpp_dec_float_100> vec1_dec, vec2_dec;
    // std::vector<cpp_dec_float_100> res_dec;
    // res_dec.resize(length);
    // for(int i = 0; i < length; i++) {
    //     vec1_dec.push_back(i);
    //     vec2_dec.push_back(i);
    // }
    // for(int i = 0; i < length; i++) {
    //     res_dec[i] = vec1_dec[i] * vec2_dec[i];
    // }

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float);
}

std::string test_mult_scalar(int length) {
    double t_fpga, t_sw, t_float;
    double start, stop;
    // Vector Multiplication Scalar
    std::vector<posit<NBITS,ES>> vec1;
    std::vector<posit<NBITS,ES>> result;
    posit<NBITS,ES> scalar;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }
    scalar = 5;
    t_fpga = vector_mult(vec1, scalar, result);

    start = omp_get_wtime();
    for(int i = 0; i < length; i++){
        result[i] = vec1[i] * scalar;
    }
    stop = omp_get_wtime();
    t_sw = stop - start;

    std::vector<float> vec_f;
    std::vector<float> result_f;
    result_f.resize(length);
    for(int i = 0; i < length; i++){
        vec_f.push_back(i);
    }
    start = omp_get_wtime();
    for(int i = 0; i < length; i++){
        result_f[i] = vec_f[i] * 5.0;
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    // std::vector<cpp_dec_float_100> vec_dec;
    // std::vector<cpp_dec_float_100> result_dec;
    // result_dec.resize(length);
    // for(int i = 0; i < length; i++){
    //     vec_dec.push_back(i);
    // }
    // for(int i = 0; i < length; i++){
    //     result_dec[i] = vec_dec[i] * 5.0;
    // }

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float);
}


template<typename T>
cpp_dec_float_100 aggregateGram(vector<vector<T > >& u) {
    cpp_dec_float_100 a = 0.0;
    for(vector<T>& u_vec : u) {
        a += (cpp_dec_float_100)u_vec.sum();
    }
    return a;
}

template<typename T>
cpp_dec_float_100 aggregateGram(valarray<valarray<T > >& u) {
    cpp_dec_float_100 a = 0.0;
    for(valarray<T>& u_vec : u) {
        a += (cpp_dec_float_100)u_vec.sum();
    }
    return a;
}

std::string test_gram(int n, int m) {
    int i;
    double stop, start;
    double t_sw = 0.0, t_fpga = 0.0, t_float = 0.0;
    cpp_dec_float_100 a_dec = 0.0, a_sw = 0.0, a_fpga = 0.0, a_float = 0.0;
    cpp_dec_float_100 da_sw = 0.0, da_hw = 0.0, da_float = 0.0;

    // Gram Matrix Test

    // POSIT FPGA
    vector<vector<posit<NBITS, ES> > > v(n);
    vector<vector<posit<NBITS, ES> > > u(n); // Orthogonal set

    for(i = 0; i < n; i++) {
        u[i].resize(m);
    }

    // // Fill vectors
    // for(i = 0; i < n; i++) {
    //     vector<posit<NBITS, ES>> vec(m);
    //     for(int j = 0; j < m; j++) {
    //         vec[j] = sqrt(2)/2;
    //     }
    //     v[i] = vec;
    // }
    //
    // // Start
    // start = omp_get_wtime();
    // u[0] = v[0];
    // i = 0;
    // do {
    //         vector<posit<NBITS,ES> > sum = sumProj(v, u, i);
    //         vector_sub(v[i], sum, u[i]);
    //         i++;
    // } while(i < n);
    // stop = omp_get_wtime();
    // t_fpga = stop - start;
    //
    // a_fpga = aggregateGram(u);

    // POSIT SW
    valarray<valarray<posit<NBITS,ES> > > v_posit(n);
    valarray<valarray<posit<NBITS,ES> > > u_posit(n);
    u_posit.resize(n);
    // Fill vectors
    for(i = 0; i < n; i++) {
        valarray<posit<NBITS,ES>> vec(m);
        for(int j = 0; j < m; j++) {
            vec[j] = sqrt(2)/2;
        }
        v_posit[i] = vec;
    }

    for(i = 0; i < n; i++) {
        u_posit[i].resize(m);
    }

    start = omp_get_wtime();
    u_posit[0] = v_posit[0];
    i = 0;
    do {
            valarray<posit<NBITS,ES>> sum = sumProj(v_posit, u_posit, i);
            u_posit[i] = v_posit[i] - sum;
            i++;
    } while(i < n);
    stop = omp_get_wtime();
    t_sw = stop - start;

    a_sw = aggregateGram(u_posit);

    // FLOAT
    valarray<valarray<float > > v_float(n);
    valarray<valarray<float > > u_float(n);

    // Fill vectors
    for(i = 0; i < n; i++) {
        valarray<float> vec(m);
        for(int j = 0; j < m; j++) {
            vec[j] = sqrt(2)/2;
        }
        v_float[i] = vec;
    }

    for(i = 0; i < n; i++) {
        u_float[i].resize(m);
    }

    start = omp_get_wtime();
    u_float[0] = v_float[0];
    i = 0;
    do {
            valarray<float> sum = sumProj(v_float, u_float, i);
            u_float[i] = v_float[i] - sum;
            i++;
    } while(i < n);
    stop = omp_get_wtime();
    t_float = stop - start;

    a_float = aggregateGram(u_float);

    // cpp_dec_float_100
    valarray<valarray<cpp_dec_float_100 > > v_dec(n);
    valarray<valarray<cpp_dec_float_100 > > u_dec(n);

    // Fill vectors
    for(i = 0; i < n; i++) {
        valarray<cpp_dec_float_100> vec(m);
        for(int j = 0; j < m; j++) {
            vec[j] = sqrt(2)/2;
        }
        v_dec[i] = vec;
    }

    for(i = 0; i < n; i++) {
        u_dec[i].resize(m);
    }

    u_dec[0] = v_dec[0];
    i = 0;
    do {
            valarray<cpp_dec_float_100> sum = sumProj(v_dec, u_dec, i);
            u_dec[i] = v_dec[i] - sum;
            i++;
    } while(i < n);

    a_dec = aggregateGram(u_dec);

    // Calculate decimal accuracy
    da_hw = decimal_accuracy(a_dec, a_fpga);
    da_sw = decimal_accuracy(a_dec, a_sw);
    da_float = decimal_accuracy(a_dec, a_float);

    return to_string_precision(t_fpga) + "," + to_string_precision(t_sw) + "," + to_string_precision(t_float) + "," + to_string_precision(da_hw) + "," + to_string_precision(da_sw) + "," + to_string_precision(da_float);
}
