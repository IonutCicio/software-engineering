#pragma once

#include "../../mocc/time.hpp"
#include "parameters.hpp"

class TrafficLight : public Observer<Timer *> {
    std::uniform_int_distribution<> random_interval;
    Light l = Light::RED;

  public:
    TrafficLight(Time &time) : random_interval(60, 120) {
        new Timer(90, TimerMode::Once, &time, this);
    }

    void update(Timer *timer) override {
        l = (l == RED ? GREEN : (l == GREEN ? YELLOW : RED));
        timer->resetWithDuration(random_interval(urng));
    }

    Light light() { return l; }
};
