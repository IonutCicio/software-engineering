#include <cmath>
#include <fstream>
#include <iostream>
#include <random>
#include <vector>

#include "../../../mocc/math.hpp"
#include "../../../mocc/mocc.hpp"
#include "../../../mocc/system.hpp"
#include "../../../mocc/time.hpp"

static urng_t urng = pseudo_random_engine_from_device();
static std::uniform_real_distribution<real_t> random_position;
static real_t T, H, M, N, L, V, A, D;

struct UAV : Observer<> {

    std::vector<real_t> x, v, p;

    UAV() : x(3, 0), v(3, 0), p(3, 0) {
        for (size_t k = 0; k < 3; k++) {
            x[k] = random_position(urng);
        }
    }

    void update() override {
        for (size_t k = 0; k < 3; k++) {
            x[k] += v[k] * T;
            p[k] = exp(-A * ((x[k] + L) / (2 * L)));
            std::bernoulli_distribution speed(p[k]);
            v[k] = speed(urng) ? V : -V;
        }
    }
};

int main() {
    {
        std::ifstream parameters("parameters.txt");
        char line_type;
        parameters >> line_type >> T >> line_type >> H >> line_type >> M >>
            line_type >> N >> line_type >> L >> line_type >> V >> line_type >>
            A >> line_type >> D;
        parameters.close();

        random_position = std::uniform_real_distribution<real_t>(-L, L);
    }

    DataDistribution collisions_distribution;
    for (size_t simulation = 0; simulation < M; simulation++) {
        System system;
        Time time(T, &system);

        std::vector<UAV *> uavs;
        for (size_t _ = 0; _ < N; _++) {
            UAV *uav = new UAV();

            uavs.push_back(uav);
            system.addObserver(uav);
        }

        size_t collisions = 0;
        while (time.elapsedTime() <= H) {
            system.next();

            for (size_t i = 0; i < N; i++) {
                for (size_t j = i + 1; j < N; j++) {
                    real_t distance = 0;
                    for (size_t k = 0; k < 3; k++) {
                        distance += pow(uavs[i]->x[k] - uavs[j]->x[k], 2);
                    }
                    distance = sqrt(distance);

                    if (distance <= D) {
                        collisions++;
                    }
                }
            }
        }

        collisions_distribution.insertDataPoint((real_t)collisions / H);
    }

    std::ofstream("results.txt")
        << "2025-01-09\nC " << collisions_distribution.mean() << std::endl;

    return EXIT_SUCCESS;
}
