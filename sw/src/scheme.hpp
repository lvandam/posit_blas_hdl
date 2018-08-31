#pragma once

#include <memory>

// Apache Arrow
#include <arrow/api.h>

#include "utils.hpp"

using namespace std;

shared_ptr<arrow::Table> create_table_elements(std::vector<posit<NBITS,ES>>& vector1, std::vector<posit<NBITS,ES>>& vector2);
shared_ptr<arrow::Table> create_table_elements_sub(std::vector<posit<NBITS,ES>>& vector1, std::vector<posit<NBITS,ES>>& vector2);
shared_ptr<arrow::Table> create_table_elements(std::vector<posit<NBITS, ES> >& vector1);
