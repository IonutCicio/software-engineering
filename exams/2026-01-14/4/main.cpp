#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <istream>

#include "../../../mocc/math.hpp"
#include "../../../mocc/mocc.hpp"
#include "../../../mocc/time.hpp"

size_t C, S, P, Q, F, M, G;
real_t A, B, V, W, T, H, a, b;
std::uniform_real_distribution<> customer_random_wait_interval;
std::uniform_real_distribution<> supplier_random_wait_interval;
std::uniform_int_distribution<size_t> random_server;
std::uniform_int_distribution<size_t> random_product;
std::uniform_int_distribution<size_t> random_amount;

urng_t urng = pseudo_random_engine_from_device();

struct CustomerPurchaseRequest {
    size_t product, amount;
};

struct SupplyRequest {
    size_t product, amount;
};

struct MissedSell {};

struct Server : Observer<CustomerPurchaseRequest>,
                Observer<SupplyRequest>,
                Notifier<MissedSell> {
    std::vector<size_t> db;

    Server() : db(P, 0) {
        for (size_t product = 0; product < P; product++) {
            db[product] = random_amount(urng);
        }
    }

    void update(CustomerPurchaseRequest request) {
        size_t k = std::min(request.amount, db[request.product]);
        db[request.product] -= k;

        if (k < request.amount) {
            notify(MissedSell{});
        }
    }

    void update(SupplyRequest request) {
        db[request.product] += request.amount; // 1???
    }
};

struct Supplier : Observer<Timer *> {
    std::vector<Server *> &servers;

    Supplier(std::vector<Server *> &servers, Time &time) : servers(servers) {
        new Timer(W - V / 2, TimerMode::Once, &time, this);
    }

    void update(Timer *timer) {
        servers[random_server(urng)]->update(
            SupplyRequest{
                .product = random_product(urng),
                .amount = random_amount(urng),
            }
        );

        timer->resetWithDuration(supplier_random_wait_interval(urng));
    }
};

struct Customer : Observer<Timer *> {
    std::vector<Server *> &servers;

    Customer(std::vector<Server *> &servers, Time &time) : servers(servers) {
        new Timer(B - A / 2, TimerMode::Once, &time, this);
    }

    void update(Timer *timer) {
        servers[random_server(urng)]->update(
            CustomerPurchaseRequest{
                .product = random_product(urng),
                .amount = random_amount(urng),
            }
        );

        timer->resetWithDuration(customer_random_wait_interval(urng));
    }
};

struct Monitor : Observer<MissedSell> {
    size_t missed_sells = 0;

    void update(MissedSell) override { missed_sells++; }
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
            case 'G': parameters >> G; break;
            case 'a': parameters >> a; break;
            case 'b': parameters >> b; break;
            case 'A': parameters >> A; break;
            case 'B': parameters >> B; break;
            case 'C': parameters >> C; break;
            case 'S': parameters >> S; break;
            case 'P': parameters >> P; break;
            case 'Q': parameters >> Q; break;
            case 'V': parameters >> V; break;
            case 'W': parameters >> W; break;
            }
        }
        // clang-format on

        parameters.close();

        customer_random_wait_interval = std::uniform_real_distribution<>(A, B);
        supplier_random_wait_interval = std::uniform_real_distribution<>(V, W);
        random_server = std::uniform_int_distribution<size_t>(0, S - 1);
        random_product = std::uniform_int_distribution<size_t>(0, P - 1);
        random_amount = std::uniform_int_distribution<size_t>(0, Q);
    }

    real_t min_rate = 0, min_F = G, min_J = std::numeric_limits<real_t>::max();

    for (size_t F = G; F >= 1; F--) {
        DataDistribution missed_sells_distribution;

        for (size_t _ = 0; _ < M; _++) {
            System system;
            Time time(T, &system);
            Monitor monitor;

            std::vector<Server *> servers;
            for (size_t server_num = 0; server_num < S; server_num++) {
                Server *server = new Server();
                server->addObserver(&monitor);
                servers.push_back(server);
            }

            std::vector<Supplier *> suppliers;
            for (size_t supplier_num = 0; supplier_num < F; supplier_num++) {
                Supplier *supplier = new Supplier(servers, time);
                suppliers.push_back(supplier);
            }

            std::vector<Customer *> customers;
            for (size_t customer_num = 0; customer_num < C; customer_num++) {
                Customer *customer = new Customer(servers, time);
                customers.push_back(customer);
            }

            while (time.elapsedTime() <= H) {
                system.next();
            }

            missed_sells_distribution.insertDataPoint(
                (real_t)monitor.missed_sells / H
            );
        }

        real_t J = a * F + b * missed_sells_distribution.mean();
        if (F == G or J < min_J) {
            min_rate = missed_sells_distribution.mean();
            min_F = F;
            min_J = J;
        }
    }

    std::ofstream("results.txt") << "2026-01-14" << std::endl
                                 << "R " << min_rate << std::endl
                                 << "F " << min_F << std::endl
                                 << "J " << min_J << std::endl;
    return EXIT_SUCCESS;
}
