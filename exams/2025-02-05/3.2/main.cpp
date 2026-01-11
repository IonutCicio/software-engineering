#include <fstream>
#include <iostream>
#include <random>
#include <vector>

#include "../../../mocc/math.hpp"
#include "../../../mocc/server.hpp"
#include "../../../mocc/system.hpp"
#include "../../../mocc/time.hpp"
#include "customer.hpp"
#include "database.hpp"
#include "parameters.hpp"
#include "server.hpp"
#include "supplier.hpp"

typedef int my_int;

int main() {

    {
        std::ifstream parameters("parameters.txt");
        parameters >> H;
        parameters >> n;
        parameters >> k;

        parameters >> alpha;
        postgresql_update = std::bernoulli_distribution(alpha);

        std::vector<real_t> items_purchase_probabilities;
        for (size_t _ = 0; _ <= k; _++) {
            real_t probability;
            parameters >> probability;
            items_purchase_probabilities.push_back(probability);
        }
        items_purchase_distribution = std::discrete_distribution(
            items_purchase_probabilities.begin(),
            items_purchase_probabilities.end()
        );

        std::vector<real_t> items_supply_probabilities;
        for (size_t _ = 0; _ <= k; _++) {
            real_t probability;
            parameters >> probability;
            items_supply_probabilities.push_back(probability);
        }

        items_supply_distribution = std::discrete_distribution(
            items_supply_probabilities.begin(), items_supply_probabilities.end()
        );

        parameters.close();
    }

    OnlineDataAnalysis oversellings_data;
    for (size_t _ = 0; _ < 1000; _++) {
        System system;
        Stopwatch stopwatch(T);

        PostgreSQL database;
        Supplier supplier;

        system.addObserver(&stopwatch);
        system.addObserver(&supplier);
        supplier.addObserver(&database);

        auto customers = std::vector<Customer *>();
        for (size_t _ = 0; _ < n; _++) {
            auto c = new Customer();
            system.addObserver(c);

            customers.push_back(c);
        }

        auto servers = std::vector<Server *>();
        for (size_t i = 0; i < n; i++) {
            auto s = new Server(system);

            customers[i]->addObserver(s);
            s->Client<SellsUpdateRequest, CacheUpdateResponse>::addObserver(
                &database
            );

            servers.push_back(s);
        }

        try {
            while (stopwatch.elapsedTime() <= H) {
                system.next();
            }
        } catch (buffer_full) {
        }

        oversellings_data.insertDataPoint(database.total_oversellings);
    }

    {
        std::ofstream output("results.txt");
        output << "2025-02-05" << std::endl;
        output << "S " << (size_t)oversellings_data.mean() << std::endl;
        output << "R " << oversellings_data.mean() / (n * H) << std::endl;
        output.close();
    }

    return EXIT_SUCCESS;
}
