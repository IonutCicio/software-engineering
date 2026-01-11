#include <fstream>

#include "parameters.hpp"
#include "traffic_light.hpp"

int main() {
    System system;
    Time time(1);
    TrafficLight traffic_light(time);

    system.addObserver(&time);

    std::ofstream file("logs");

    while (time.elapsedTime() <= HORIZON) {
        file << time.elapsedTime() << ' '
             << traffic_light.light() << std::endl;
        system.next();
    }

    file.close();
    return EXIT_SUCCESS;
}
