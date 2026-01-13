#include <cstdlib>
#include <fstream>
#include <random>

#include "../../../mocc/math.hpp"

int main() {
    size_t N, M;
    std::vector<std::discrete_distribution<>> transition_matrix;
    matrix<real_t> transition_cost;

    {
        std::ifstream parameters("parameters.txt");

        struct Transition {
            size_t i, j;
            real_t P, C;
        };

        std::vector<Transition> transitions;

        char format;
        while (parameters >> format) {
            switch (format) {
            case 'A':
                Transition transition;
                parameters >> transition.i >> transition.j >> transition.P >>
                    transition.C;
                transitions.push_back(transition);
                break;
            case 'N':
                parameters >> N;
                break;
            case 'M':
                parameters >> M;
                break;
            }
        }

        parameters.close();

        matrix<real_t> transition_probability =
            matrix<real_t>(N, std::vector<real_t>(N, 0));
        transition_cost = matrix<real_t>(N, std::vector<real_t>(N, 0));
        for (auto transition : transitions) {
            transition_probability[transition.i][transition.j] = transition.P;
            transition_cost[transition.i][transition.j] = transition.C;
        }

        for (auto row : transition_probability) {
            transition_matrix.push_back(
                std::discrete_distribution<>(row.begin(), row.end())
            );
        }
    }

    DataDistribution project_cost_distribution;
    urng_t urng = pseudo_random_engine_from_device();
    const size_t INITIAL_STATE = 0;

    for (size_t _ = 0; _ < M; _++) {
        size_t current_state = INITIAL_STATE;
        real_t project_cost = 0;

        while (current_state != N - 1) {
            size_t next_state = transition_matrix[current_state](urng);
            project_cost += transition_cost[current_state][next_state];
            current_state = next_state;
        }

        project_cost_distribution.insertDataPoint(project_cost);
    }

    std::ofstream("results.txt")
        << "2025-11-03" << std::endl
        << "C " << project_cost_distribution.mean() << std::endl;

    return EXIT_SUCCESS;
}
