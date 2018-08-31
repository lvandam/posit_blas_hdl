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
#include <positarith.h> // FPGA accelerator

using namespace std;
using namespace sw::unum;

int main(int argc, char ** argv)
{
    std::vector<posit<32,2>> vec1, vec2;
    posit<32,2> result;
    vec1.push_back(5);
    vec2.push_back(6);

    double t_fpga;
    t_fpga = vector_dot(vec1, vec2, result);

    cout << "Posit Result: " << pretty_print(result) << endl;
    cout << "FPGA Execution Time: " << t_fpga << "s" << endl;

    return 0;
}
