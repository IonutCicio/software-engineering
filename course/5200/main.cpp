#include <cassert>
#include <fstream>
#include <iostream>
#include <random>
#include <vector>

using real_t = double;
const size_t HORIZON = 800, PHASES_SIZE = 3;

enum Outcome {
    NO_ERROR = 0,
    NO_ERROR_DETECTED = 1,
    ERROR_DETECTED = 2
};

int main() {
    std::random_device random_device;
    std::default_random_engine urng(random_device());

    std::uniform_real_distribution<> uniform_0_1(0, 1);
    std::vector<std::discrete_distribution<>>
        phases_error_distribution;

    {
        std::ifstream probabilities("probabilities.csv");
        real_t probability_error_introduced,
            probability_error_not_detected;

        while (probabilities >> probability_error_introduced >>
               probability_error_not_detected)
            phases_error_distribution.push_back(
                std::discrete_distribution<>({
                    1 - probability_error_introduced,
                    probability_error_introduced *
                        probability_error_not_detected,
                    probability_error_introduced *
                        (1 - probability_error_not_detected),
                })
            );

        probabilities.close();
        assert(
            phases_error_distribution.size() == PHASES_SIZE
        );
    }

    std::ofstream log("log.csv");
    log << "time phase progress-0 progress-1 progress-2 "
           "outcome-0 outcome-1 outcome-2 assess-0 assess-1 "
           "assess-2"
        << std::endl;

    real_t probability_repeat_phase = 0.8;

    size_t phase = 0;
    std::vector<size_t> progress(PHASES_SIZE, 0);
    std::vector<Outcome> outcomes(PHASES_SIZE, NO_ERROR);

    for (size_t time = 0; time < HORIZON; time++) {
        progress[phase]++;

        if (progress[phase] == 4) {
            outcomes[phase] = static_cast<Outcome>(
                phases_error_distribution[phase](urng)
            );
            switch (outcomes[phase]) {
            case NO_ERROR:
            case NO_ERROR_DETECTED:
                phase++;
                break;
            case ERROR_DETECTED:
                if (phase > 0 && uniform_0_1(urng) >
                                     probability_repeat_phase)
                    phase = std::
                        uniform_int_distribution<>(0, phase - 1)(
                            urng
                        );
                break;
            }

            if (phase == PHASES_SIZE)
                break;

            progress[phase] = 0;
        }

        {
            log << time << " " << phase << " ";
            for (size_t phase = 0; phase < PHASES_SIZE;
                 phase++)
                log << progress[phase] << " ";
            for (size_t phase = 0; phase < PHASES_SIZE;
                 phase++)
                log << (outcomes[phase] != NO_ERROR) << " ";
            for (size_t phase = 0; phase < PHASES_SIZE;
                 phase++)
                log << (outcomes[phase] == ERROR_DETECTED)
                    << " ";
            log << std::endl;
        }
    }

    log.close();
    return EXIT_SUCCESS;
}
