#include <cstddef>
#include <fstream>
#include <random>

#include "../../mocc/mocc.hpp"

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

    real_t time = 0;
    size_t phase = 0, costs = 0;

    std::ofstream file("logs");

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

    file.close();
    return EXIT_SUCCESS;
}
