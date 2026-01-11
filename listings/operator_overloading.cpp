#include <iostream>

struct Potato {
    float weight_g; // grams
};

struct Person {
    std::string name;
    float weight_kg; // kilograms

    void operator+=(const Potato &potato) {
        this->weight_kg += potato.weight_g / 1000;
    }

    void operator()() { std::cout << this->name << std::endl; }
};

int main() {
    Person pippo = {.name = "Pippo", .weight_kg = 102};
    Potato heavy_potato = {.weight_g = 352};

    std::cout << pippo.weight_kg << std::endl; /* 102 Kg */
    pippo += heavy_potato;
    std::cout << pippo.weight_kg << std::endl; /* 102.352 Kg */

    for (size_t _ = 0; _ < 5; _++) {
        pippo += heavy_potato;
    }

    std::cout << pippo.weight_kg << std::endl; /* 104.112 Kg */
    pippo(); /* Using the "()" operator on the object. */

    return EXIT_SUCCESS;
}
