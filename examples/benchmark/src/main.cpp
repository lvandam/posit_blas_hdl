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

#include <posit/posit>
// Posit Arithmetic FPGA accelerator library
#include <positarith.h>

#include "main.hpp"
#include "defines.hpp"

using namespace std;
using namespace sw::unum;

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
void normalizeVector(valarray<float>& vec) {
    float sum;
    for(float& el : vec) {
        sum += el * el;
    }
    float sq = sqrt((float)sum);
    for(float& el : vec) {
        el = el / sq;
    }
}

vector<posit<NBITS, ES> > sumProj(vector<vector<posit<NBITS,ES> > >& v, vector<vector<posit<NBITS,ES> > >& u, int i) {
        int k = 0;
        vector<posit<NBITS,ES> > result(u[0].size());

        // cout << "i = " << i << "  " << endl;

        while (k < i)
        {
            cout << k << ", " << endl;
                posit<NBITS,ES> dot_u_u;
                vector_dot(u[k], u[k], dot_u_u);
                // cout << "dot_u_u = " << dot_u_u << endl;

                posit<NBITS,ES> dot_v_u;
                vector_dot(v[i], u[k], dot_v_u);
                // cout << "v["<<i<<"] = "; printVector(v[i]);
                // cout << "u["<<k<<"] = "; printVector(u[k]);
                // cout << "dot_v_u = " << dot_v_u << endl;

                posit<NBITS,ES> factor = dot_v_u / dot_u_u;
                // cout << "factor = " << factor << endl;

                vector<posit<NBITS,ES> > factor_u;
                vector_mult(u[k], factor, factor_u);
                // cout << "factor_u = ";
                // printVector(factor_u);

                vector_add(result, factor_u, result);
                // cout << "result = ";
                // printVector(result);

                k++;
        }
        cout << endl;

        return result;
}

valarray<float> sumProj(valarray<valarray<float>> v, valarray<valarray<float>> u, int i) {
    int k = 0;
    valarray<float> result(v[0].size());

    while (k < i)
    {
        // cout << k << ", " << endl;
        float dot_u_u = (u[k] * u[k]).sum();
        // cout << "dot_u_u = " << dot_u_u << endl;

        float dot_v_u = (v[i] * u[k]).sum();
        // cout << "v["<<i<<"] = "; printVector(v[i]);
        // cout << "u["<<k<<"] = "; printVector(u[k]);
        // cout << "dot_v_u = " << dot_v_u << endl;

        float factor = dot_v_u / dot_u_u;
        // cout << "factor = " << factor << endl;

        valarray<float> factor_u = factor * u[k];
        // cout << "factor_u = ";
        // printVector(factor_u);

        result += factor * u[k];
        // cout << "result = ";
        // printVector(result);

        k++;
    }

    return result;
}

valarray<posit<NBITS,ES>> sumProj(valarray<valarray<posit<NBITS,ES>>> v, valarray<valarray<posit<NBITS,ES>>> u, int i) {
    int k = 0;
    valarray<posit<NBITS,ES>> result(v[0].size());

    while (k < i)
    {
        // cout << k << ", " << endl;
        posit<NBITS,ES> dot_u_u = (u[k] * u[k]).sum();
        // cout << "dot_u_u = " << dot_u_u << endl;

        posit<NBITS,ES> dot_v_u = (v[i] * u[k]).sum();
        // cout << "v["<<i<<"] = "; printVector(v[i]);
        // cout << "u["<<k<<"] = "; printVector(u[k]);
        // cout << "dot_v_u = " << dot_v_u << endl;

        posit<NBITS,ES> factor = dot_v_u / dot_u_u;
        // cout << "factor = " << factor << endl;

        valarray<posit<NBITS,ES>> factor_u = factor * u[k];
        // cout << "factor_u = ";
        // printVector(factor_u);

        result += factor * u[k];
        // cout << "result = ";
        // printVector(result);

        k++;
    }

    return result;
}

int main(int argc, char ** argv)
{
    vector<int> lengths = {10, 20, 30, 40, 50, 100, 200, 300, 400, 500, 1000, 2000, 3000, 4000, 5000, 10000, 20000, 30000, 40000, 50000, 100000, 200000, 300000, 400000, 500000, 1000000};

    std::string t_dot, t_sum, t_add, t_add_scalar, t_subtract, t_subtract_scalar, t_mult, t_mult_scalar;

    for(int length : lengths) {
        t_dot = test_dot_product(length);
        t_sum = test_sum(length);
        t_add = test_add(length);
        t_add_scalar = test_add_scalar(length);
        t_subtract = test_subtract(length);
        t_subtract_scalar = test_subtract_scalar(length);
        t_mult = test_mult(length);
        t_mult_scalar = test_mult_scalar(length);

        ofstream outfile("positarith_es" + std::to_string(ES) + "_" + std::to_string(length) + ".txt", ios::out);
        outfile << t_dot << endl;
        outfile << t_sum << endl;
        outfile << t_add << endl;
        outfile << t_add_scalar << endl;
        outfile << t_subtract << endl;
        outfile << t_subtract_scalar << endl;
        outfile << t_mult << endl;
        outfile << t_mult_scalar << endl;
        outfile.close();
    }

    vector<int> gram_length = {10, 20, 30, 40, 50, 100, 200, 300, 400, 500};

    std::string t_gram;

    for(int length : gram_length) {
        t_gram = test_gram(3, length);

        ofstream outfile("positarith_gram_es" + std::to_string(ES) + "_3_" + std::to_string(length) + ".txt", ios::out);
        outfile << t_gram << endl;
        outfile.close();
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

    start = omp_get_wtime();
    float res_f = 0;
    std::vector<float> vec1_f, vec2_f;
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(1);
        vec2_f.push_back(i);
    }
    for(int i = 0; i < length; i++) {
        res_f = res_f + vec1_f[i] * vec2_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    return to_string(t_fpga) + "," + to_string(t_sw) + "," + to_string(t_float);
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

    start = omp_get_wtime();
    std::vector<float> vec1_f, vec2_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
        vec2_f.push_back(i);
    }
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] * vec2_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    return to_string(t_fpga) + "," + to_string(t_sw) + "," + to_string(t_float);
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

    start = omp_get_wtime();
    std::vector<float> vec1_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
    }
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] + 5.0;
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    return to_string(t_fpga) + "," + to_string(t_sw) + "," + to_string(t_float);
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

    start = omp_get_wtime();
    std::vector<float> vec1_f, vec2_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
        vec2_f.push_back(i);
    }
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] - vec2_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    return to_string(t_fpga) + "," + to_string(t_sw) + "," + to_string(t_float);
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

    start = omp_get_wtime();
    std::vector<float> vec1_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
    }
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] - 5.0;
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    return to_string(t_fpga) + "," + to_string(t_sw) + "," + to_string(t_float);
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

    start = omp_get_wtime();
    std::vector<float> vec1_f;
    float res_f = 0.0;
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
    }
    for(int i = 0; i < length; i++) {
        res_f = res_f + vec1_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    return to_string(t_fpga) + "," + to_string(t_sw) + "," + to_string(t_float);
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

    start = omp_get_wtime();
    std::vector<float> vec1_f, vec2_f;
    std::vector<float> res_f;
    res_f.resize(length);
    for(int i = 0; i < length; i++) {
        vec1_f.push_back(i);
        vec2_f.push_back(i);
    }
    for(int i = 0; i < length; i++) {
        res_f[i] = vec1_f[i] * vec2_f[i];
    }
    stop = omp_get_wtime();
    t_float = stop - start;

    return to_string(t_fpga) + "," + to_string(t_sw) + "," + to_string(t_float);
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

    return to_string(t_fpga) + "," + to_string(t_sw) + "," + to_string(t_float);
}

std::string test_gram(int n, int m) {
    int i;
    double stop, start;
    double t_sw, t_fpga, t_float;

    // Gram Matrix Test
    vector<vector<posit<NBITS, ES> > > v(n);
    vector<vector<posit<NBITS, ES> > > u(n); // Orthogonal set

    for(i = 0; i < n; i++) {
        u[i].resize(m);
    }

    // Fill vectors
    for(i = 0; i < n; i++) {
        vector<posit<NBITS, ES>> vec(m);
        for(int j = 0; j < m; j++) {
            vec[j] = sqrt(2)/2;
        }
        v[i] = vec;
    }

    // Start
    start = omp_get_wtime();
    u[0] = v[0];
    i = 0;
    do {
            vector<posit<NBITS,ES> > sum = sumProj(v, u, i);
            vector_sub(v[i], sum, u[i]);
            i++;
    } while(i < n);
    stop = omp_get_wtime();
    t_fpga = stop - start;

    // POSIT SW
    valarray<valarray<posit<NBITS,ES> > > v_posit(n);
    valarray<valarray<posit<NBITS,ES> > > u_posit(n);

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

    return to_string(t_fpga) + "," + to_string(t_sw) + "," + to_string(t_float);
}
