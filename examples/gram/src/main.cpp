#include <cstdint>
#include <memory>
#include <vector>
#include <string>
#include <numeric>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <omp.h>

#include <posit/posit>
// Posit Arithmetic FPGA accelerator library
#include <positarith.h>

#include "main.hpp"
#include "defines.hpp"

using namespace std;
using namespace sw::unum;

/*
From https://stackoverflow.com/questions/12254720/gram-schmidt-orthogonalization-incorrect-implementation

The Gram-Schmidt Orthogonalization algorithm is as follows:

    Given a set of n linearly independent vectors Beta = {e_1, e_2, ..., e_n},
    the algorithm produces a set Beta' = {e_1', e_2', ..., e_n'} such that
    dot(e_i', e_j') = 0 whenever i != j.

    A. Set e_1' = e_1
    B. Begin with the index i = 2 and k = 1
    C. Subtract the projection of e, onto the vectors e_1', e_2', ..., e_(i-1)'
       from e_i, and store the result in e_i', That is,

                             dot(e_i, e_k')
       e_i' = e_i - sum_over(-------------- e_k')
                                e_k'^2

    D. If i < n, increment i and loop back to step C.
*/

vector<posit<NBITS, ES>> sum_over_e(vector<vector<posit<NBITS,ES>>>& e, vector<vector<posit<NBITS,ES>>>& e_prime, int i)
{
    int k = 0;
    vector<posit<NBITS,ES>> result(e_prime[0].size());

    while (k < i - 1)
    {
        posit<NBITS,ES> e_prime_k_squared;
        vector_dot(e_prime[k], e_prime[k], e_prime_k_squared);

        posit<NBITS,ES> dot_e_e_prime;
        vector_dot(e[i], e_prime[k], dot_e_e_prime);

        posit<NBITS,ES> factor = dot_e_e_prime / e_prime_k_squared;

        vector<posit<NBITS,ES>> factor_e_prime;
        vector_mult(e_prime[k], factor, factor_e_prime);

        vector_add(result, factor_e_prime, result);

        k++;
    }

    return result;
}

int main(int argc, char ** argv)
{
    int n = 3; // Number of vectors

    vector<vector<posit<NBITS, ES>>> e(3);
    vector<vector<posit<NBITS, ES>>> e_prime(3);

    // e.resize(n); e_prime.resize(n);

    // Fill the vectors
    for(int i = 0; i < 3; i++) {
        vector<posit<NBITS,ES>> vec = {1, 0, 1};
        e[i] = vec;
    }

    e_prime[0] = e[0];

    int i = 0;
    do {
        vector<posit<NBITS,ES>> sum = sum_over_e(e, e_prime, i);
        vector_sub(e[i], sum, e_prime[i]);
        i++;
    } while(i < n);

    for (int i = 0; i < n; i++)
    {
        cout << "Vector e_prime_" << i+1 << ": < "
        << e_prime[i][0] << ", "
        << e_prime[i][1] << ", "
        << e_prime[i][2] << " >" << endl;
    }













    // cout << endl << "=== VECTOR DOT PRODUCT ===" << endl;
    // test_dot_product(50);
    //
    // cout << endl << "=== VECTOR ADD ===" << endl;
    // test_add(50);
    //
    // cout << endl << "=== VECTOR ADD SCALAR ===" << endl;
    // test_add_scalar(50);
    //
    // cout << endl << "=== VECTOR SUBTRACT ===" << endl;
    // test_subtract(50);
    //
    // cout << endl << "=== VECTOR SUBTRACT SCALAR ===" << endl;
    // test_subtract_scalar(50);
    //
    // cout << endl << "=== VECTOR SUM ===" << endl;
    // test_sum(50);

    return 0;
}

void test_dot_product(int length) {
    // Vector Dot Product
    std::vector<posit<32,2>> vec1, vec2;
    posit<32,2> result;

    for(int i = 0; i < length; i++) {
        vec1.push_back(1);
        vec2.push_back(i);
    }

    float res = 0;
    for(int i = 0; i < length; i++) {
        res = res + i;
    }
    cout << "Result float: " << res << endl;

    double t_fpga;
    t_fpga = vector_dot(vec1, vec2, result);

    cout << "Posit Result: " << pretty_print(result) << endl;
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_add(int length) {
    // Vector Add
    std::vector<posit<32,2>> vec1, vec2;
    std::vector<posit<32,2>> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
        vec2.push_back(i);
    }

    double t_fpga;
    t_fpga = vector_add(vec1, vec2, result);

    cout << "Posit Result: " << endl;
    for(posit<32,2>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_add_scalar(int length) {
    // Vector Add Scalar
    std::vector<posit<32,2>> vec1;
    std::vector<posit<32,2>> result;
    posit<32,2> scalar;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }

    scalar = 5;

    double t_fpga;
    t_fpga = vector_add(vec1, scalar, result);

    cout << "Posit Result: " << endl;
    for(posit<32,2>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_subtract(int length) {
    // Vector Subtract
    std::vector<posit<32,2>> vec1, vec2;
    std::vector<posit<32,2>> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
        vec2.push_back(i);
    }

    double t_fpga;
    t_fpga = vector_sub(vec1, vec2, result);

    cout << "Posit Result: " << endl;
    for(posit<32,2>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_subtract_scalar(int length) {
    // Vector Subtract Scalar
    std::vector<posit<32,2>> vec1;
    std::vector<posit<32,2>> result;
    posit<32,2> scalar;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }

    scalar = 5;

    double t_fpga;
    t_fpga = vector_sub(vec1, scalar, result);

    cout << "Posit Result: " << endl;
    for(posit<32,2>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_sum(int length) {
    // Vector Sum
    std::vector<posit<32,2>> vec1;
    posit<32,2> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }

    double t_fpga;
    t_fpga = vector_sum(vec1, result);

    cout << "Posit Result: " << pretty_print(result) << endl;
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}
