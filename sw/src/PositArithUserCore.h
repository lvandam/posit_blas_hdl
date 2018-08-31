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

#pragma once

#include <memory>

#include "fletcher/FPGAPlatform.h"
#include "fletcher/UserCore.h"

#define CORES   1
#define MAX_CORES 8
#define BATCHES_PER_CORE 2

#define REG_CONTROL_OFFSET  1

#define REG_RESULT_DATA_OFFSET 9

#define REG_RESULT_OFFSET 10

#define REG_OPERATION_OFFSET 11

enum Operation { INVALID_OP = 0, VECTOR_DOT = 1 };

/**
 * \class PositArithUserCore
 *
 * A class to provide interaction with the regular expression matching UserCore example.
 */
class PositArithUserCore : public fletcher::UserCore
{
public:
/**
 * \param platform  The platform to run the core on.
 */
PositArithUserCore(std::shared_ptr<fletcher::FPGAPlatform> platform);

void set_operation(Operation op);

void set_batch_offsets(std::vector<uint32_t>& offsets);

void control_zero();

private:


};
