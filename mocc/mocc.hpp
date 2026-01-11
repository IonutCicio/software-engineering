#pragma once

#include <random>

/* (uniform random number generator) */
using urng_t = std::default_random_engine;
using real_t = double;
template <typename T> using matrix = std::vector<std::vector<T>>;

urng_t pseudo_random_engine_from_device();

// template <typename T> using vec = std::vector<T>;
// template <typename T> using matrix = std::vector<vec<T>>;
// using vec = std::vector<real_t>;
