#include <cstdlib>
#include <fstream>

#include "../../mocc/system.hpp"
#include "control_center.hpp"
#include "monitor.hpp"
#include "network.hpp"
#include "parameters.hpp"
#include "traffic_light.hpp"

int main() {
    System system;
    Monitor monitor;
    Time time(1, &system);
    Network network(time);
    TrafficLight traffic_light;
    ControlCenter control_center(time);

    system.addObserver(&monitor);
    network.addObserver(&traffic_light);
    traffic_light.addObserver(&monitor);
    control_center.addObserver(&network);
    control_center.addObserver(&monitor);

    std::ofstream file("logs");

    while (time.elapsedTime() <= HORIZON) {
        file << time.elapsedTime() << ' '
             << control_center.light() << ' '
             << traffic_light.light() << ' '
             << monitor.isValid() << std::endl;

        system.next();
    }

    file.close();
    return EXIT_SUCCESS;
}
