#ifndef POSITARITH_H
#define POSITARITH_H

#include <posit/posit>

// Apache Arrow
#include <arrow/api.h>
// Fletcher
#include <fletcher/fletcher.h>

using namespace sw::unum;

// Addition/Subtraction
double vector_add(std::vector<posit<32, 2>>& vector1, std::vector<posit<32, 2>>& vector2, std::vector<posit<32, 2>>& result);
double vector_sub(std::vector<posit<32, 2>>& vector1, std::vector<posit<32, 2>>& vector2, std::vector<posit<32, 2>>& result);

// Addition/Subtraction Scalar
double vector_add(std::vector<posit<32, 2>>& vector1, posit<32, 2>& scalar, std::vector<posit<32, 2>>& result);
double vector_sub(std::vector<posit<32, 2>>& vector1, posit<32, 2>& scalar, std::vector<posit<32, 2>>& result);

// Aggregation functions
double vector_dot(std::vector<posit<32, 2>>& vector1, std::vector<posit<32, 2>>& vector2, posit<32, 2>& result);
double vector_sum(std::vector<posit<32, 2>>& vector1, posit<32, 2>& result);

#endif
