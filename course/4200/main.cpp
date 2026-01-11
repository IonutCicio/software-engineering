#include <cstddef>
#include <fstream>
#include <iostream>
#include <random>

#include "../../mocc/math.hpp"
#include "../../mocc/mocc.hpp"

const size_t ITERATIONS = 10000;

int main() {
    std::random_device random_device;
    urng_t urng(random_device());

    // clang-format off
    std::vector<std::discrete_distribution<>>
        transition_matrix = {
            {0, 1},          
            {0, .3, .7},
            {0, 0, .2, .8},  
            {0, .1, .1, .1, .7},
            {0, 0, 0, 0, 1},
        };
    // clang-format on

    DataDistribution costs_distribution;
    size_t less_than_100_count = 0;
    real_t time = 0;

    std::ofstream file("logs");

    for (int iter = 0; iter < ITERATIONS; iter++) {
        size_t phase = 0, costs = 0;

        while (phase != 4) {
            time++;
            if (phase == 1 || phase == 3)
                costs += 20;
            else if (phase == 2)
                costs += 40;

            phase = transition_matrix[phase](urng);
            file << time << ' ' << phase << ' ' << costs
                 << std::endl;
        }

        costs_distribution.insertDataPoint(costs);
        if (costs < 100)
            less_than_100_count++;
    }

    std::cout << costs_distribution.mean() << ' '
              << costs_distribution.stddev() << ' '
              << (double)less_than_100_count / ITERATIONS
              << std::endl;

    file.close();
    return EXIT_SUCCESS;
}
