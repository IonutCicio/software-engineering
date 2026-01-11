#include <cstddef>
#include <cstdlib>
#include <deque>
#include <fstream>
#include <iostream>

#include "../../../mocc/mocc.hpp"
#include "../../../mocc/system.hpp"
#include "../../../mocc/time.hpp"

static urng_t urng = pseudo_random_engine_from_device();
static real_t AVG, VAR;
static size_t N;
const size_t T = 1, HORIZON = 1000000;

System _system;
Time _time(T, &_system);
std::normal_distribution<> random_time_interval;

struct CustomerPurchaseRequest {
    size_t id;
    real_t time;
};

struct CustomerRequestsCount {
    size_t id, count;
};

struct Customer : Observer<Timer *>, Notifier<CustomerPurchaseRequest> {
    const size_t id;

    Customer(size_t id) : id(id) {
        new Timer(AVG, TimerMode::Once, &_time, this);
    }

    void update(Timer *timer) override {
        notify(CustomerPurchaseRequest{.id = id, .time = _time.elapsedTime()});
        timer->resetWithDuration(random_time_interval(urng));
    }
};

struct Dispatcher : Observer<>,
                    Observer<CustomerPurchaseRequest>,
                    Notifier<CustomerRequestsCount>,
                    Notifier<CustomerPurchaseRequest> {

    std::deque<CustomerPurchaseRequest> requests;
    std::vector<size_t> requests_count;

    Dispatcher(size_t N) : requests_count(N, 0) {}

    void update() override {
        if (requests.empty()) {
            return;
        }

        Notifier<CustomerPurchaseRequest>::notify(requests.front());
        requests.pop_front();
    }

    void update(CustomerPurchaseRequest request) override {
        requests_count[request.id - 1]++;
        requests.push_back(request);
        Notifier<CustomerRequestsCount>::notify(
            CustomerRequestsCount{
                .id = request.id, .count = requests_count[request.id - 1]
            }
        );
    }
};

struct Monitor : Observer<CustomerRequestsCount> {
    std::vector<size_t> counts;
    size_t total_requests_received = 0;

    Monitor(size_t N) : counts(N, 0) {}

    void update(CustomerRequestsCount requests) override {
        total_requests_received -= counts[requests.id - 1];
        counts[requests.id - 1] = requests.count;
        total_requests_received += counts[requests.id - 1];
    }
};

int main() {
    {
        std::ifstream parameters("parameters.txt");

        std::string format;
        while (parameters >> format) {
            if (format == "N") {
                parameters >> N;
            } else if (format == "Avg") {
                parameters >> AVG;
            } else if (format == "StdDev") {
                parameters >> VAR;
            }
        }
        random_time_interval = std::normal_distribution(AVG, VAR);

        parameters.close();
    }

    Dispatcher dispatcher(N);
    Monitor monitor(N);
    std::vector<Customer *> customers;

    for (size_t id = 1; id <= N; id++) {
        Customer *customer = new Customer(id);
        customer->addObserver(&dispatcher);
        customers.push_back(customer);
    }

    _system.addObserver(&dispatcher);
    dispatcher.Notifier<CustomerRequestsCount>::addObserver(&monitor);

    while (_time.elapsedTime() <= HORIZON) {
        _system.next();
    }

    {
        std::ofstream output("results.txt");
        output << "2025-01-09" << std::endl;
        for (auto customer : customers) {
            output << customer->id << " "
                   << dispatcher.requests_count[customer->id - 1] << std::endl;
        }
        output << "M1 " << monitor.total_requests_received << std::endl;
        output.close();
    }

    return EXIT_SUCCESS;
}
