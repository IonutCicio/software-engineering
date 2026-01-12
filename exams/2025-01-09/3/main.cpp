#include <cstddef>
#include <cstdlib>
#include <fstream>
#include <iostream>

#include "../../../mocc/math.hpp"
#include "../../../mocc/mocc.hpp"
#include "../../../mocc/system.hpp"
#include "../../../mocc/time.hpp"

urng_t urng = pseudo_random_engine_from_device();
real_t AVG, VAR;

const size_t T = 1, HORIZON = 1000000;

System _system;
Time _time(T, &_system);

struct CustomerPurchaseRequest {
    real_t time;
};

struct Customer : Observer<Timer *>, Notifier<CustomerPurchaseRequest> {
    std::normal_distribution<> random_time_interval;

    Customer() : random_time_interval(AVG, VAR) {
        new Timer(1, TimerMode::Once, &_time, this);
    }

    void update(Timer *timer) override {
        notify(CustomerPurchaseRequest{.time = _time.elapsedTime()});
        timer->resetWithDuration(random_time_interval(urng));
    }
};

struct Monitor : Observer<CustomerPurchaseRequest> {
    real_t last_request_time = 0;
    DataDistribution requests_delta;

    void update(CustomerPurchaseRequest request) {
        requests_delta.insertDataPoint(request.time - last_request_time);
        last_request_time = request.time;
    }
};

int main() {
    {
        std::ifstream parameters("parameters.txt");

        std::string format;
        while (parameters >> format) {
            if (format == "Avg") {
                parameters >> AVG;
            } else if (format == "StdDev") {
                parameters >> VAR;
            }
        }

        parameters.close();
    }

    Customer customer;
    Monitor monitor;
    customer.addObserver(&monitor);

    while (_time.elapsedTime() <= HORIZON) {
        _system.next();
    }

    std::ofstream("results.txt")
        << "2025-01-09" << std::endl
        << "Avg " << monitor.requests_delta.mean() << std::endl
        << "StdDev " << monitor.requests_delta.stddev() << std::endl;

    return EXIT_SUCCESS;
}
