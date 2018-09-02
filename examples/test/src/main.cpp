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

int main(int argc, char ** argv)
{
    cout << endl << "=== VECTOR DOT PRODUCT ===" << endl;
    test_dot_product(50);

    cout << endl << "=== VECTOR SUM ===" << endl;
    test_sum(50);

    cout << endl << "=== VECTOR ADD ===" << endl;
    test_add(50);

    cout << endl << "=== VECTOR ADD SCALAR ===" << endl;
    test_add_scalar(50);

    cout << endl << "=== VECTOR SUBTRACT ===" << endl;
    test_subtract(50);

    cout << endl << "=== VECTOR SUBTRACT SCALAR ===" << endl;
    test_subtract_scalar(50);

    cout << endl << "=== VECTOR MULT ===" << endl;
    test_mult(50);

    cout << endl << "=== VECTOR MULT SCALAR ===" << endl;
    test_mult_scalar(50);

    return 0;
}

void test_dot_product(int length) {
    // Vector Dot Product
    std::vector<posit<NBITS,ES>> vec1, vec2;
    posit<NBITS,ES> result;

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
    std::vector<posit<NBITS,ES>> vec1, vec2;
    std::vector<posit<NBITS,ES>> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
        vec2.push_back(i);
    }

    double t_fpga;
    t_fpga = vector_add(vec1, vec2, result);

    cout << "Posit Result: " << endl;
    for(posit<NBITS,ES>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_add_scalar(int length) {
    // Vector Add Scalar
    std::vector<posit<NBITS,ES>> vec1;
    std::vector<posit<NBITS,ES>> result;
    posit<NBITS,ES> scalar;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }

    scalar = 5;

    double t_fpga;
    t_fpga = vector_add(vec1, scalar, result);

    cout << "Posit Result: " << endl;
    for(posit<NBITS,ES>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_subtract(int length) {
    // Vector Subtract
    std::vector<posit<NBITS,ES>> vec1, vec2;
    std::vector<posit<NBITS,ES>> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
        vec2.push_back(i);
    }

    double t_fpga;
    t_fpga = vector_sub(vec1, vec2, result);

    cout << "Posit Result: " << endl;
    for(posit<NBITS,ES>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_subtract_scalar(int length) {
    // Vector Subtract Scalar
    std::vector<posit<NBITS,ES>> vec1;
    std::vector<posit<NBITS,ES>> result;
    posit<NBITS,ES> scalar;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }

    scalar = 5;

    double t_fpga;
    t_fpga = vector_sub(vec1, scalar, result);

    cout << "Posit Result: " << endl;
    for(posit<NBITS,ES>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_sum(int length) {
    // Vector Sum
    std::vector<posit<NBITS,ES>> vec1;
    posit<NBITS,ES> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }

    double t_fpga;
    t_fpga = vector_sum(vec1, result);

    cout << "Posit Result: " << pretty_print(result) << endl;
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_mult(int length) {
    // Vector Multiplication
    std::vector<posit<NBITS,ES>> vec1, vec2;
    std::vector<posit<NBITS,ES>> result;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
        vec2.push_back(i);
    }

    double t_fpga;
    t_fpga = vector_mult(vec1, vec2, result);

    cout << "Posit Result: " << endl;
    for(posit<NBITS,ES>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}

void test_mult_scalar(int length) {
    // Vector Multiplication Scalar
    std::vector<posit<NBITS,ES>> vec1;
    std::vector<posit<NBITS,ES>> result;
    posit<NBITS,ES> scalar;

    for(int i = 0; i < length; i++){
        vec1.push_back(i);
    }

    scalar = 5;

    double t_fpga;
    t_fpga = vector_mult(vec1, scalar, result);

    cout << "Posit Result: " << endl;
    for(posit<NBITS,ES>& el : result) {
        cout << pretty_print(el) << endl;
    }
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;
}
