#include <cstdlib>
#include <deque>
#include <fstream>
#include <iostream>

#include "../../../mocc/mocc.hpp"
#include "../../../mocc/system.hpp"
#include "../../../mocc/time.hpp"

urng_t urng = pseudo_random_engine_from_device();
real_t AVG, VAR;
size_t N;

const size_t T = 1, HORIZON = 1000000;

std::normal_distribution<> random_interval;
System _system;
Time _time(T, &_system);

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
        timer->resetWithDuration(random_interval(urng));
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

struct Monitor : Observer<CustomerPurchaseRequest> {

    real_t last_request_time = 0;
    bool preserves_order = true;

    void update(CustomerPurchaseRequest request) override {
        if (request.time < last_request_time) {
            preserves_order = false;
        }

        last_request_time = request.time;
    }
};

int main() {

    {
        std::ifstream parameters("parameters.txt");

        std::string line_type;
        while (parameters >> line_type) {
            if (line_type == "N") {
                parameters >> N;
            } else if (line_type == "Avg") {
                parameters >> AVG;
            } else if (line_type == "StdDev") {
                parameters >> VAR;
            }
        }
        random_interval = std::normal_distribution<>(AVG, VAR);

        parameters.close();
    }

    Dispatcher dispatcher(N);
    Monitor monitor;
    std::vector<Customer *> customers;

    for (size_t id = 1; id <= N; id++) {
        Customer *customer = new Customer(id);
        customer->addObserver(&dispatcher);
        customers.push_back(customer);
    }

    _system.addObserver(&dispatcher);
    dispatcher.Notifier<CustomerPurchaseRequest>::addObserver(&monitor);

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
        output << "M2 " << (monitor.preserves_order ? 0 : 1) << std::endl;

        output.close();
    }

    return EXIT_SUCCESS;
}
