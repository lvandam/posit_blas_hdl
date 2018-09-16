#pragma once
// vector_utils.hpp :  include file containing templated utilities to work with vectors and matrices
//
// Copyright (C) 2017-2018 Stillwater Supercomputing, Inc.
//
// This file is part of the universal numbers project, which is released under an MIT Open Source license.

namespace sw {
	namespace hprblas {

		// generate random data vector
		template<typename element_T>
		void randomVectorFill(size_t n, std::vector<element_T>& vec) {
			for (size_t i = 0; i < n; i++) {
				int rnd1 = rand();
				int rnd2 = rand();
				double rnd = rnd1 / (double)rnd2;
				vec[i] = (element_T)rnd;
			}
		}

		// generate a vector of random permutations around 1.0
		// contraction is a right shift of the random variable causing smaller fluctuations
		// RAND_MAX is typically a 16bit number so can't contract more than 15 bits
		template<typename element_T>
		void randomVectorFillAroundOneEPS(size_t n, std::vector<element_T>& vec, size_t contraction = 6) {
			for (size_t i = 0; i < n; i++) {
				int rnd1 = (rand() - (RAND_MAX >> 1)) >> contraction;
				double eps = rnd1 / (double)RAND_MAX;
				double v = 1.0 + eps;
				vec[i] = (element_T)v;
			}
		}

		// print a sampling of the provided vector
		// if samples is set to 0, all elements of the vector are printed
		template<typename element_T>
		void sampleVector(std::string vec_name, std::vector<element_T>& vec, uint32_t start = 0, uint32_t incr = 1, uint32_t nrSamples = 0) {
			std::cout << "Vector sample is: " << '\n';
			if (nrSamples) {
				uint32_t printed = 0;
				for (uint32_t i = start; i < vec.size(); i += incr) {
					if (printed < nrSamples) {
						printed++;
						std::cout << vec_name << "[" << std::setw(3) << i << "] = " << std::setprecision(15) << vec[i] << '\n';
					}
				}
			}
			else {
				for (uint32_t i = start; i < vec.size(); i += incr) {
					std::cout << vec_name << "[" << std::setw(3) << i << "] = " << std::setprecision(15) << vec[i] << '\n';
				}
			}
			std::cout << std::endl;
		}

	} // namespace blas

} // namespace sw
