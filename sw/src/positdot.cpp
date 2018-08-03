// Copyright 2018 Delft University of Technology
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <cstdint>
#include <memory>
#include <vector>
#include <string>
#include <numeric>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <omp.h>

// Apache Arrow
#include <arrow/api.h>

// Fletcher
#include <fletcher/fletcher.h>

// Posit dot FPGA UserCore
#include "scheme.hpp"
#include "PositDotUserCore.h"
#include "positdot.hpp"

#include "debug_values.hpp"
#include "utils.hpp"

#ifndef PLATFORM
  #define PLATFORM 0
#endif

#ifndef DEBUG
    #define DEBUG 0
#endif

/* Burst step length in bytes */
#define BURST_LENGTH 32

using namespace std;

/* Structure to easily convert from 64-bit addresses to 2x32-bit registers */
typedef struct _lohi {
        uint32_t lo;
        uint32_t hi;
}
lohi;

typedef union _addr_lohi {
        uint64_t full;
        lohi half;
}
addr_lohi;

/**
 * Main function for pair HMM accelerator
 */
int main(int argc, char ** argv)
{
        // Times
        double start, stop;
        double t_fill_vector, t_fill_table, t_prepare_column, t_create_core, t_fpga, t_sw, t_float = 0.0;

        srand(0);
        flush(cout);

        int rc = 0;
        uint32_t num_rows = BATCHES_PER_CORE * 1;

        int length = 10;
        bool calculate_sw = true;
        bool show_results = false;

        DEBUG_PRINT("Parsing input arguments...\n");
        if (argc >= 2) istringstream(argv[1]) >> length;
        if (argc >= 3) istringstream(argv[2]) >> calculate_sw;
        if (argc >= 4) istringstream(argv[3]) >> show_results;

        cout << "=========================================" << endl;
        cout << "LENGTH = " << length << endl;

        if (calculate_sw) {
                DEBUG_PRINT("Calculating on host...\n");
        }

        DEBUG_PRINT("Filling posit vectors...\n");
        // Make a table with element vectors
        start = omp_get_wtime();
        std::vector<posit<NBITS, ES> > vector1, vector2;
        for(int i = 0; i < length; i++) {
            // Some simple test case
            posit<NBITS, ES> pos1, pos2;
            pos1.set_raw_bits(i);
            pos2.set_raw_bits(i * 2);
            pos2 = pos2 * 1e26;

            vector1.push_back(pos1);
            vector2.push_back(pos2);
        }
        stop = omp_get_wtime();
        t_fill_vector = stop - start;

        DEBUG_PRINT("Creating Arrow table...\n");
        start = omp_get_wtime();
        shared_ptr<arrow::Table> table_elements = create_table_elements(vector1, vector2);
        stop = omp_get_wtime();
        t_fill_table = stop - start;

        DEBUG_PRINT("Creating result buffers...\n");
        // Create arrays for results to be written to (per SA core)
        std::vector<uint32_t *> result_hw(roundToMultiple(CORES, 2));
        for(int i = 0; i < roundToMultiple(CORES, 2); i++) {
                rc = posix_memalign((void * * ) &(result_hw[i]), BURST_LENGTH * roundToMultiple(CORES, 2), sizeof(uint32_t) * num_rows);
                // clear values buffer
                for (uint32_t j = 0; j < num_rows; j++) {
                        result_hw[i][j] = 0xDEADBEEF;
                }
        }

        // Create a platform
        shared_ptr<fletcher::SNAPPlatform> platform(new fletcher::SNAPPlatform());

        DEBUG_PRINT("Preparing column buffers...\n");
        // Prepare the colummn buffers
        start = omp_get_wtime();
        std::vector<std::shared_ptr<arrow::Column> > columns;
        columns.push_back(table_elements->column(0));
        columns.push_back(table_elements->column(1));
        platform->prepare_column_chunks(columns); // This requires a modification in Fletcher (to accept vectors)
        stop = omp_get_wtime();
        t_prepare_column = stop - start;

        DEBUG_PRINT("Creating UserCore instance...\n");

        start = omp_get_wtime();
        // Create a UserCore
        PositDotUserCore uc(static_pointer_cast<fletcher::FPGAPlatform>(platform));

        // Reset UserCore
        uc.reset();

        DEBUG_PRINT("Writing result buffer addresses...\n");
        // Write result buffer addresses
        for(int i = 0; i < roundToMultiple(CORES, 2); i++) {
                addr_lohi val;
                val.full = (uint64_t) result_hw[i];
                platform->write_mmio(REG_RESULT_DATA_OFFSET + i, val.full);
        }

        // Configure the cores
        std::vector<uint32_t> batch_offsets;
        batch_offsets.reserve(roundToMultiple(CORES, 2));
        for(int i = 0; i < roundToMultiple(CORES, 2); i++) {
                // For now, same amount of batches for all cores
                batch_offsets[i] = i * BATCHES_PER_CORE;
        }
        uc.set_batch_offsets(batch_offsets);
        stop = omp_get_wtime();
        t_create_core = stop - start;

        // Run
        start = omp_get_wtime();
        uc.start();

#ifdef DEBUG
        uc.wait_for_finish(1000000);
#else
        uc.wait_for_finish(10);
#endif

        // Wait for last result of last SA core
        do {
                usleep(10);
        }
        while ((result_hw[CORES - 1][0] == 0xDEADBEEF));

        stop = omp_get_wtime();
        t_fpga = stop - start;

        // Get the results from the UserCore
        for(int i = 0; i < CORES; i++) {
                cout << "==================================" << endl;
                cout << "== CORE " << i << endl;
                cout << "==================================" << endl;
                for(int j = 0; j < num_rows; j++) {
                        cout << dec << j <<": " << hex << result_hw[i][j] << dec <<endl;
                }
                cout << "==================================" << endl;
                cout << endl;
        }

        posit<NBITS, ES> result_posit;
        result_posit.set_raw_bits(result_hw[0][0]);
        cout << "Result: " << pretty_print(result_posit) << endl;

        // Check for errors with SW calculation
        if (calculate_sw) {
                DebugValues<posit<NBITS, ES> > hw_debug_values, sw_debug_values;
                DebugValues<float > float_debug_values;
                DebugValues<cpp_dec_float_100 > dec_debug_values;

                for (int c = 0; c < CORES; c++) {
                        for (int i = 0; i < BATCHES_PER_CORE; i++) {
                                // Store HW posit result for decimal accuracy calculation
                                posit<NBITS, ES> res_hw;
                                res_hw.set_raw_bits(result_hw[c][i]);
                                hw_debug_values.debugValue(res_hw, "result[%d][%d]", c, 0);
                        }
                }

                start = omp_get_wtime();
                posit<NBITS, ES> res_sw(0);
                for(int i = 0; i < vector1.size(); i++) {
                        res_sw = res_sw + vector1[i] * vector2[i];
                }
                stop = omp_get_wtime();
                t_sw = stop - start;
                sw_debug_values.debugValue(res_sw, "result[0][0]");

                cout << "SW RESULT: " << hexstring(res_sw.collect()) << endl;

                cout << "Calculating in cpp_dec_float_100..." << endl;
                cpp_dec_float_100 res_dec = 0.0;
                for(int i = 0; i < vector1.size(); i++) {
                        res_dec = res_dec + (cpp_dec_float_100)vector1[i] * (cpp_dec_float_100)vector2[i];
                }
                dec_debug_values.debugValue(res_dec, "result[0][0]");

                cout << "Calculating in float..." << endl;
                start = omp_get_wtime();
                float res_float = 0.0;
                for(int i = 0; i < vector1.size(); i++) {
                        res_float = res_float + (float)vector1[i] * (float)vector2[i];
                }
                stop = omp_get_wtime();
                t_float = stop - start;
                float_debug_values.debugValue(res_float, "result[0][0]");

                cout << "Writing benchmark file..." << endl;
                writeBenchmark(hw_debug_values, sw_debug_values, float_debug_values, dec_debug_values,
                               "positdot_es2_" + std::to_string(length) + ".txt");
        }

        cout << "Resetting user core..." << endl;
        // Reset UserCore
        uc.reset();

        cout << "Adding timing data..." << endl;
        time_t t = chrono::system_clock::to_time_t(chrono::system_clock::now());
        ofstream outfile("positdot_es2_" + std::to_string(length) + ".txt", ios::out | ios::app);
        outfile << endl << "===================" << endl;
        outfile << ctime(&t) << endl;
        outfile << "Vector lengths = " << length << endl;
        outfile << "t_fill_vector,t_fill_table,t_prepare_column,t_create_core,t_fpga,t_sw,t_float" << endl;
        outfile << t_fill_vector <<","<< t_fill_table <<","<< t_prepare_column <<","<< t_create_core <<","<< t_fpga <<","<< t_sw <<","<< t_float << endl;
        outfile.close();

        return 0;
}
