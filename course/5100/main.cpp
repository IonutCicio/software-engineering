#include <fstream>
#include <random>
#include <vector>

#include "../../mocc/mocc.hpp"

const size_t HORIZON = 20, STATES_SIZE = 10;

int main() {
    urng_t urng = pseudo_random_engine_from_device();

    auto random_state =
        std::uniform_int_distribution<>(0, STATES_SIZE - 1);
    std::uniform_real_distribution<> uniform(0, 1);

    std::vector<std::discrete_distribution<>>
        transition_matrix(STATES_SIZE);

    for (size_t state = 0; state < STATES_SIZE; state++) {
        std::vector<real_t> weights(STATES_SIZE);
        for (auto &weight : weights) {
            weight = uniform(urng);
        }

        transition_matrix[state] =
            std::discrete_distribution<>(
                weights.begin(), weights.end()
            );
    }

    std::ofstream file("logs");

    size_t state = random_state(urng);
    for (size_t time = 0; time <= HORIZON; time++) {
        file << time << " " << state << std::endl;
        state = transition_matrix[state](urng);
    }

    file.close();
    return EXIT_SUCCESS;
}
