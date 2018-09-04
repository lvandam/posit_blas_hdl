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

void printVector(vector<posit<NBITS,ES>>& vec) {
    cout << "< ";
    for (vector<posit<NBITS,ES>>::const_iterator i = vec.begin(); i != vec.end(); ++i) {
        std::cout << *i << ", ";
    }
    cout << ">" << endl;
}

void printVector(valarray<float>& vec) {
    cout << "< ";
    for(float& el : vec) {
        cout << el << ", ";
    }
    cout << ">" << endl;
}

void printMatrix(vector<vector<posit<NBITS,ES>>>& matrix) {
    for (int i = 0; i < matrix.size(); i++)
    {
            cout << "< ";
            for(int j = 0; j < matrix[i].size(); j++) {
                    cout << matrix[i][j];
                    if(j < matrix[i].size() - 1)
                        cout << ", ";
            }
            cout << " >" << endl;
    }
}

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

vector<posit<NBITS, ES> > sumProj(vector<vector<posit<NBITS,ES> > >& v, vector<vector<posit<NBITS,ES> > >& u, int i)
{
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

valarray<float> sumProj(valarray<valarray<float>> v, valarray<valarray<float>> u, int i)
{
    int k = 0;
    valarray<float> result(3);

    while (k < i)
    {
        cout << k << ", " << endl;
        float dot_u_u = (u[k] * u[k]).sum();
        cout << "dot_u_u = " << dot_u_u << endl;

        float dot_v_u = (v[i] * u[k]).sum();
        cout << "v["<<i<<"] = "; printVector(v[i]);
        cout << "u["<<k<<"] = "; printVector(u[k]);
        cout << "dot_v_u = " << dot_v_u << endl;

        float factor = dot_v_u / dot_u_u;
        cout << "factor = " << factor << endl;

        valarray<float> factor_u = factor * u[k];
        cout << "factor_u = ";
        printVector(factor_u);

        result += factor * u[k];
        cout << "result = ";
        printVector(result);

        k++;
    }

    return result;
}

int main(int argc, char ** argv)
{
        if(argc < 3)
        {
                cout << "Usage: ./posit_gram <# vectors> <vector length>" << endl;
                exit(1);
        }
        int n = stoi(argv[1]); // Number of vectors
        int m = stoi(argv[2]); // Vector dimension

        if(n > m) {
            cout << "Number of vectors should be smaller than vector dimension" << endl;
            exit(1);
        }

        vector<vector<posit<NBITS, ES> > > v(n);
        vector<vector<posit<NBITS, ES> > > u(n); // Orthogonal set

        for(int i = 0; i < n; i++) {
            u[i].resize(m);
        }

        // v[0] = {sqrt(2)/2, sqrt(2)/2,  0};
        // v[1] = {       -1,         1, -1};
        // v[2] = {        0,        -2, -2};

        // Fill vectors
        for(int i = 0; i < n; i++) {
            vector<posit<NBITS, ES>> vec(m);
            for(int j = 0; j < m; j++) {
                vec[j] = sqrt(2)/2;
            }
            v[i] = vec;
        }

        u[0] = v[0];
        int i = 0;
        do {
                vector<posit<NBITS,ES> > sum = sumProj(v, u, i);
                vector_sub(v[i], sum, u[i]);
                // normalizeVector(u[i]);
                i++;
        } while(i < n);

        // Printing results
        printMatrix(u);

        // cout << "FLOAT:" << endl;
        // // FLOAT
        // {
        //     valarray<valarray<float > > v(3);
        //     valarray<valarray<float > > u(3);
        //
        //     v[0] = {sqrt(2)/2, sqrt(2)/2,  0};
        //     v[1] = {       -1,         1, -1};
        //     v[2] = {        0,        -2, -2};
        //
        //     for(int i = 0; i < n; i++) {
        //         u[i].resize(m);
        //     }
        //
        //     u[0] = v[0];
        //
        //     int i = 0;
        //     do {
        //             valarray<float > sum = sumProj(v, u, i);
        //             u[i] = v[i] - sum;
        //             normalizeVector(u[i]);
        //             i++;
        //     } while(i < n);
        //
        //     for (int i = 0; i < n; i++)
        //     {
        //             cout << "< ";
        //             for(int j = 0; j < m; j++) {
        //                     cout << u[i][j];
        //                     if(j < m - 1)
        //                         cout << ", ";
        //             }
        //             cout << " >" << endl;
        //     }
        // }

        return 0;
}
