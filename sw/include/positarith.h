#ifndef POSITARITH_H
#define POSITARITH_H

#include <posit/posit>

// Apache Arrow
#include <arrow/api.h>
// Fletcher
#include <fletcher/fletcher.h>

#define POS_NBITS 32
#define POS_ES 2

using namespace sw::unum;

// Addition/Subtraction
double vector_add(std::vector<posit<POS_NBITS,POS_ES>>& vector1, std::vector<posit<POS_NBITS,POS_ES>>& vector2, std::vector<posit<POS_NBITS,POS_ES>>& result);
double vector_sub(std::vector<posit<POS_NBITS,POS_ES>>& vector1, std::vector<posit<POS_NBITS,POS_ES>>& vector2, std::vector<posit<POS_NBITS,POS_ES>>& result);

// Addition/Subtraction Scalar
double vector_add(std::vector<posit<POS_NBITS,POS_ES>>& vector1, posit<POS_NBITS,POS_ES>& scalar, std::vector<posit<POS_NBITS,POS_ES>>& result);
double vector_sub(std::vector<posit<POS_NBITS,POS_ES>>& vector1, posit<POS_NBITS,POS_ES>& scalar, std::vector<posit<POS_NBITS,POS_ES>>& result);

// Multiplication Scalar
double vector_mult(std::vector<posit<POS_NBITS,POS_ES>>& vector1, std::vector<posit<POS_NBITS,POS_ES>>& vector2, std::vector<posit<POS_NBITS,POS_ES>>& result);
double vector_mult(std::vector<posit<POS_NBITS,POS_ES>>& vector1, posit<POS_NBITS,POS_ES>& scalar, std::vector<posit<POS_NBITS,POS_ES>>& result);

// Aggregation functions
double vector_dot(std::vector<posit<POS_NBITS,POS_ES>>& vector1, std::vector<posit<POS_NBITS,POS_ES>>& vector2, posit<POS_NBITS,POS_ES>& result);
double vector_sum(std::vector<posit<POS_NBITS,POS_ES>>& vector1, posit<POS_NBITS,POS_ES>& result);

#endif
