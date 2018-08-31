#ifndef POSITARITH_H
#define POSITARITH_H

// Apache Arrow
#include <arrow/api.h>
// Fletcher
#include <fletcher/fletcher.h>
// #include "defines.hpp"
#include <posit/posit>

using namespace sw::unum;

double vector_dot(std::vector<posit<32, 2>>& vector1, std::vector<posit<32, 2>>& vector2, posit<32, 2>& result);

#endif
