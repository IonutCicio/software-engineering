#include <cmath>
#include <deque>
#include <fstream>
#include <iostream>
#include <random>

#include "../../../mocc/alias.hpp"
#include "../../../mocc/math.hpp"
#include "../../../mocc/mocc.hpp"
#include "../../../mocc/system.hpp"
#include "../../../mocc/time.hpp"

static urng_t urng = pseudo_random_engine_from_device();

static std::uniform_int_distribution<> random_server;
static std::uniform_int_distribution<> random_product;
static std::uniform_int_distribution<> random_initial_product_amout;
static std::uniform_real_distribution<> random_customer_wait_interval;
static std::uniform_real_distribution<> random_supplier_wait_interval;

static real_t T, H, M, A, B, V, Q;
static size_t C, S, P, F, K;

STRONG_ALIAS(ProductNumber, size_t)
STRONG_ALIAS(CustomerId, size_t)
STRONG_ALIAS(SupplierId, size_t)

struct Demand {
    CustomerId id;
    ProductNumber i;
};

struct Supply {
    SupplierId id;
    ProductNumber i;
};

struct Server : Observer<>, Observer<Demand>, Observer<Supply> {

    std::vector<size_t> database;
    std::vector<std::deque<ProductNumber>> customers_fifo;
    std::vector<std::deque<ProductNumber>> suppliers_fifo;

    size_t missed_sells = 0;

    Server() : database(P, 0), customers_fifo(), suppliers_fifo() {
        for (size_t customer = 0; customer <= C; customer++) {
            customers_fifo.push_back(std::deque<ProductNumber>());
        }

        for (size_t supplier = 0; supplier <= C; supplier++) {
            suppliers_fifo.push_back(std::deque<ProductNumber>());
        }
    }

    void update() override {
        for (size_t supplier = 0; supplier < F; supplier++) {
            if (!suppliers_fifo[supplier].empty()) {
                auto i = suppliers_fifo[supplier].front();
                suppliers_fifo[supplier].pop_front();
                database[i]++;
            }
        }

        // while (!Buffer<ProductNumberSupply>::buffer.empty()) {
        //     auto i = this->Buffer<ProductNumberSupply>::buffer.front();
        //     Buffer<ProductNumberSupply>::buffer.pop_front();
        //     database[i]++;
        // }

        for (size_t customer = 0; customer < C; customer++) {
            if (!customers_fifo[customer].empty()) {

                auto i = customers_fifo[customer].front();
                customers_fifo[customer].pop_front();

                if (database[i] > 0) {
                    database[i]--;
                } else {
                    missed_sells++;
                }
            }
        }
    }

    void update(Demand demand) override {
        customers_fifo[demand.id].push_back(demand.i);
    }

    void update(Supply supply) override {
        suppliers_fifo[supply.id].push_back(supply.i);
    }
};

struct Customer : Observer<Timer *> {

    std::vector<Server *> &servers;
    size_t id;
    size_t count = 0;

    Customer(Time &time, std::vector<Server *> &servers, size_t id)
        : servers(servers), id(id) {
        new Timer(A, TimerMode::Once, &time, this);
    }

    void update(Timer *timer) override {
        servers[random_server(urng)]->update(
            Demand{.id = id, .i = random_product(urng)}
        );

        timer->resetWithDuration(random_customer_wait_interval(urng));
    }
};

struct Supplier : Observer<Timer *> {
    std::vector<Server *> &servers;

    size_t id;

    Supplier(Time &time, std::vector<Server *> &servers, size_t id)
        : servers(servers), id(id) {
        new Timer(V, TimerMode::Once, &time, this);
    }

    void update(Timer *timer) override {
        servers[random_server(urng)]->update(
            Supply{.id = id, .i = random_product(urng)}
        );

        timer->resetWithDuration(random_supplier_wait_interval(urng));
    }
};

int main() {
    {
        std::ifstream parameters("parameters.txt");
        char line_type;
        // clang-format off
        parameters >> 
            line_type >> T >> 
            line_type >> H >> 
            line_type >> M >>
            line_type >> C >> 
            line_type >> A >> 
            line_type >> B >> 
            line_type >> F >> 
            line_type >> V >> 
            line_type >> Q >> 
            line_type >> P >>
            line_type >> S >>
            line_type >> K;
        // clang-format on

        parameters.close();

        random_server = std::uniform_int_distribution<>(0, S - 1);
        random_product = std::uniform_int_distribution<>(0, P - 1);
        random_initial_product_amout = std::uniform_int_distribution<>(0, K);
        random_customer_wait_interval = std::uniform_real_distribution<>(A, B);
        random_supplier_wait_interval = std::uniform_real_distribution<>(V, Q);
    }

    DataDistribution missed_sells_distribution;
    for (size_t simulation = 0; simulation < M; simulation++) {
        System system;
        Time time(T, &system);
        std::vector<Customer *> customers;
        std::vector<Server *> servers;
        std::vector<Supplier *> suppliers;

        system.addObserver(&time);
        for (size_t _ = 0; _ < S; _++) {
            Server *server = new Server();
            servers.push_back(server);
            system.addObserver(server);
        }

        for (size_t id = 0; id < C; id++) {
            Customer *customer = new Customer(time, servers, id);
            customers.push_back(customer);
        }

        for (size_t id = 0; id < F; id++) {
            Supplier *supplier = new Supplier(time, servers, id);
            suppliers.push_back(supplier);
        }

        while (time.elapsedTime() <= H) {
            system.next();
        }

        size_t total_missed_sells = 0;
        for (auto server : servers) {
            total_missed_sells += server->missed_sells;
        }

        missed_sells_distribution.insertDataPoint(total_missed_sells);
    }

    std::ofstream("results.txt")
        << "2025-01-09\nR " << missed_sells_distribution.mean() / (real_t)H
        << std::endl;

    return EXIT_SUCCESS;
}
