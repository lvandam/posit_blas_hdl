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
    #define DEBUG 1
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
        srand(0);
        flush(cout);

        int rc = 0;
        uint32_t num_rows = BATCHES_PER_CORE * 1;

        bool calculate_sw = true;
        bool show_results = false;

        DEBUG_PRINT("Parsing input arguments...\n");
        if (argc >= 2) istringstream(argv[1]) >> calculate_sw;
        if (argc >= 3) istringstream(argv[2]) >> show_results;

        // batches = std::vector<t_batch>(workload->batches);
        // for (int q = 0; q < workload->batches; q++) {
        //         fill_batch(batches[q], q, workload->bx[q], workload->by[q], powf(2.0, initial_constant_power)); // HW unit starts with last batch
        //         print_batch_info(batches[q]);
        // }

        // PairHMMPosit pairhmm_posit(workload, show_results, show_table);
        // PairHMMFloat<float> pairhmm_float(workload, show_results, show_table);
        // PairHMMFloat<cpp_dec_float_50> pairhmm_dec50(workload, show_results, show_table);

        if (calculate_sw) {
                DEBUG_PRINT("Calculating on host...\n");
                // pairhmm_posit.calculate(batches);
                // pairhmm_float.calculate(batches);
                // pairhmm_dec50.calculate(batches);
        }

        // Make a table with element vectors
        std::vector<posit<NBITS,ES> > vector1, vector2;

        vector1.push_back(posit<NBITS,ES>(1)); vector2.push_back(posit<NBITS,ES>(1));
        vector1.push_back(posit<NBITS,ES>(1)); vector2.push_back(posit<NBITS,ES>(0));
        vector1.push_back(posit<NBITS,ES>(5)); vector2.push_back(posit<NBITS,ES>(2));

        shared_ptr<arrow::Table> table_elements = create_table_elements(vector1, vector2);

        // Create arrays for results to be written to (per SA core)
        std::vector<uint32_t *> result_hw(roundToMultiple(CORES, 2));
        for(int i = 0; i < roundToMultiple(CORES, 2); i++) {
                rc = posix_memalign((void * * ) &(result_hw[i]), BURST_LENGTH * roundToMultiple(CORES, 2), sizeof(uint32_t) * num_rows);
                // clear values buffer
                for (uint32_t j = 0; j < num_rows; j++) {
                        result_hw[i][j] = 0xDEADBEEF;
                }
        }

        // Calculate on FPGA
        // Create a platform
#if (PLATFORM == 0)
        shared_ptr<fletcher::EchoPlatform> platform(new fletcher::EchoPlatform());
#elif (PLATFORM == 2)
        shared_ptr<fletcher::SNAPPlatform> platform(new fletcher::SNAPPlatform());
#else
#error "PLATFORM must be 0 or 2"
#endif

        // Prepare the colummn buffers
        std::vector<std::shared_ptr<arrow::Column> > columns;
        columns.push_back(table_elements->column(0));
        columns.push_back(table_elements->column(1));

        platform->prepare_column_chunks(columns); // This requires a modification in Fletcher (to accept vectors)

        // Create a UserCore
        PositDotUserCore uc(static_pointer_cast<fletcher::FPGAPlatform>(platform));

        // Reset UserCore
        uc.reset();

        // Write result buffer addresses
        for(int i = 0; i < roundToMultiple(CORES, 2); i++) {
                addr_lohi val;
                val.full = (uint64_t) result_hw[i];
                printf("Values buffer @ %016lX\n", val.full);
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

        // Run
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
                DebugValues<posit<NBITS, ES> > hw_debug_values;

                for (int c = 0; c < CORES; c++) {
                    for (int i = 0; i < BATCHES_PER_CORE; i++) {
                        // Store HW posit result for decimal accuracy calculation
                        posit<NBITS, ES> res_hw;
                        res_hw.set_raw_bits(result_hw[c][i]);
                        hw_debug_values.debugValue(res_hw, "result[%d][%d]", c * BATCHES_PER_CORE + (BATCHES_PER_CORE - i - 1), 0);
                    }
                }

                // writeBenchmark(pairhmm_dec50, pairhmm_float, pairhmm_posit, hw_debug_values,
                //                std::to_string(initial_constant_power) + ".txt", false, true);

                // int errs_posit = 0;
                // errs_posit = pairhmm_posit.count_errors(result_hw);
                // DEBUG_PRINT("Posit errors: %d\n", errs_posit);
        }

        // Reset UserCore
        uc.reset();

        return 0;
}
