#pragma once

#include "../../mocc/time.hpp"
#include "parameters.hpp"
#include <cstdlib>

class ControlCenter : public Observer<Timer *>,
                      public Notifier<NetworkPayloadLight> {
    std::uniform_int_distribution<> random_interval;
    Light l = Light::RED;

  public:
    ControlCenter(Time &time) : random_interval(60, 120) {
        new Timer(90, TimerMode::Once, &time, this);
    }

    void update(Timer *timer) override {
        l = (l == RED ? GREEN : (l == GREEN ? YELLOW : RED));
        notify(l);
        timer->resetWithDuration(random_interval(urng));
    }

    Light light() { return l; }
};
