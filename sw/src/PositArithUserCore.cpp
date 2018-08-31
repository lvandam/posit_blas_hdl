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

#include <stdexcept>

#include "PositArithUserCore.h"
#include "defines.hpp"
#include "utils.hpp"

using namespace fletcher;

PositArithUserCore::PositArithUserCore(std::shared_ptr<fletcher::FPGAPlatform> platform)
        : UserCore(platform)
{
        // Some settings that are different from standard implementation
        // concerning start, reset and status register.
        if(CORES == 1) {
            ctrl_start       = 0x0000000000000001;// 0x00000000000000FF;
            ctrl_reset       = 0x0000000000000002;// 0x000000000000FF00;
            done_status      = 0x0000000000000002;// 0x000000000000FF00;
            done_status_mask = 0x0000000000000002;// 0x000000000000FFFF;
        } else if(CORES == 2) {
            ctrl_start       = 0x0000000000000003;
            ctrl_reset       = 0x000000000000000C;
            done_status      = 0x000000000000000C;
            done_status_mask = 0x000000000000000C;
        }
}

void PositArithUserCore::set_operation(Operation op) {
        uint32_t opcode = op;
        reg_conv_t reg;

        reg.half.hi = opcode;
        reg.half.lo = opcode;

        this->platform()->write_mmio(REG_OPERATION_OFFSET, reg.full);

}

void PositArithUserCore::set_batch_offsets(std::vector<uint32_t>& offsets) {
        // for (int i = 0; i < MAX_CORES / 2; i++) {
        //     reg_conv_t reg;
        //
        //     if(i < CORES) {
        //         reg.half.hi = offsets[2 * i];
        //         reg.half.lo = offsets[2 * i + 1];
        //     } else {
        //         reg.half.hi = 0x00000000;
        //         reg.half.lo = 0x00000000;
        //     }
        //
        //     this->platform()->write_mmio(REG_BATCH_OFFSET + i, reg.full);
        // }
}

void PositArithUserCore::control_zero()
{
        this->platform()->write_mmio(REG_CONTROL_OFFSET, 0x00000000);
}
