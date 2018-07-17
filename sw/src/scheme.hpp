#pragma once

#include <memory>

// Apache Arrow
#include <arrow/api.h>

#include "utils.hpp"

using namespace std;

shared_ptr<arrow::Table> create_table_elements(std::vector<uint32_t>& vector1, std::vector<uint32_t>& vector2);
