#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <random>

#include "../../../mocc/math.hpp"
#include "../../../mocc/mocc.hpp"
#include "../../../mocc/observer.hpp"
#include "../../../mocc/time.hpp"

size_t M, N;
real_t T, H, A, L, V, D, R;
urng_t urng = pseudo_random_engine_from_device();
std::uniform_real_distribution<> random_bool(0, 1);
std::vector<real_t> z(3, 0);

struct UAV : Observer<Time *> {
    std::vector<real_t> x;

    UAV(std::vector<real_t> x) : x(x) {}

    void update(Time *time) override {
        for (size_t dimension = 0; dimension < 3; dimension++) {
            real_t p = exp(-A * ((x[dimension] + L) / (2 * L)));
            real_t v = -V;
            if (random_bool(urng) <= p) {
                v = V;
            }

            x[dimension] += v * time->timeStep();
        }
    }
};

struct Monitor : Observer<Timer *> {
    std::vector<UAV *> &uavs;
    size_t total_collisions = 0;

    Monitor(std::vector<UAV *> &uavs) : uavs(uavs) {}

    void update(Timer *timer) override {
        for (size_t uav_i = 0; uav_i < uavs.size(); uav_i++) {
            for (size_t uav_j = uav_i + 1; uav_j < uavs.size(); uav_j++) {
                real_t distance = 0;
                for (size_t component = 0; component < 3; component++) {
                    distance += pow(
                        uavs[uav_i]->x[component] - uavs[uav_j]->x[component], 2
                    );
                }

                if (sqrt(distance) <= D) {
                    total_collisions++;
                }
            }
        }
    }
};

int main() {

    {
        std::ifstream parameters("parameters.txt");

        // clang-format off
        char format;
        while (parameters >> format) {
            switch (format) {
            case 'T': parameters >> T; break;
            case 'H': parameters >> H; break;
            case 'M': parameters >> M; break;
            case 'N': parameters >> N; break;
            case 'L': parameters >> L; break;
            case 'V': parameters >> V; break;
            case 'A': parameters >> A; break;
            case 'D': parameters >> D; break;
            case 'R': parameters >> R; break;
            }
        }
        // clang-format on

        parameters.close();
    }

    std::uniform_real_distribution<> random_position(-L, L);

    DataDistribution collisions_distribution;
    for (size_t _ = 0; _ < M; _++) {
        System system;
        Time time(T, &system);

        std::vector<UAV *> uavs;
        for (size_t uav_number = 0; uav_number < N; uav_number++) {
            std::vector<real_t> x(3, 0);
            for (size_t dimension = 0; dimension < 3; dimension++) {
                x[dimension] = random_position(urng);
            }

            UAV *uav = new UAV(x);
            uavs.push_back(uav);
            time.addObserver(uav);
        }

        real_t d = 0;
        for (auto uav : uavs) {
            for (size_t dimension = 0; dimension < 3; dimension++) {
                d += pow((z[dimension] - uav->x[dimension]) / (2 * L), 2);
            }
        }

        Monitor monitor(uavs);
        Timer timer(R, TimerMode::Repeating, &time, &monitor);

        while (time.elapsedTime() <= H) {
            system.next();
        }

        collisions_distribution.insertDataPoint(monitor.total_collisions);
    }

    std::ofstream("results.txt")
        << "2026-01-14" << std::endl
        << "C " << collisions_distribution.mean() / H << std::endl;

    return EXIT_SUCCESS;
}
