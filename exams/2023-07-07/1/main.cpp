#include "../../../mocc/system.hpp"
#include "../../../mocc/time.hpp"
#include "director.hpp"
#include "employee.hpp"
#include "parameters.hpp"

#include <fstream>
#include <iostream>

int main() {
    {
        std::ifstream parameters("parameters.txt");
        char line_type;

        // clang-format off
        while (parameters >> line_type)
            switch (line_type) {
                case 'A': parameters >> A; break;
                case 'B': parameters >> B; break;
                case 'C': parameters >> C; break;
                case 'D': parameters >> D; break;
                case 'F': parameters >> F; break;
                case 'G': parameters >> G; break;
                case 'N': parameters >> N; break;
                case 'W': parameters >> W; break;
            }
        // clang-format on

        parameters.close();
    }

    System system;
    Director director;
    Stopwatch stopwatch;
    std::vector<Employee *> employees;

    {
        system.addObserver(&stopwatch);

        for (size_t k = 1; k <= W; k++) {
            auto e = new Employee(urng, k);

            e->addObserver(&director);
            director.addObserver(e);
            stopwatch.addObserver(e);
            employees.push_back(e);
        }
    }

    /* Simulation */
    while (stopwatch.elapsedTime() < HORIZON) {
        bool terminate = stopwatch.elapsedTime() > 1000;
        for (auto employee : employees)
            if (employee->completion_time_analysis.stddev() >
                0.01 * employee->completion_time_analysis.mean()) {
                terminate = false;
                break;
            }

        if (terminate)
            break;

        system.next();
    }

    {
        std::ofstream("results.txt")
            << "AvgTime " << director.project_time_analysis.mean() << std::endl
            << "AvgCost " << director.project_cost_analysis.mean() << std::endl;

        for (auto employee : employees)
            std::ofstream("results.txt", std::ios_base::app)
                << employee->id << ' '
                << employee->completion_time_analysis.mean() << ' '
                << employee->completion_time_analysis.mean() * employee->cost
                << ' ' << employee->completion_time_analysis.stddev() << ' '
                << employee->completion_time_analysis.stddev() * employee->cost
                << std::endl;
    }

    return EXIT_SUCCESS;
}
