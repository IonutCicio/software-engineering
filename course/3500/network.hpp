#pragma once

#include "../../mocc/buffer.hpp"
#include "../../mocc/notifier.hpp"
#include "../../mocc/time.hpp"
#include "parameters.hpp"
#include <cstdlib>
#include <random>

class Network : public Observer<Timer *>,
                public Buffer<NetworkPayloadLight>,
                public Notifier<LightUpdateMessage>,
                public Notifier<Fault> {
    std::bernoulli_distribution random_fault;
    std::bernoulli_distribution random_repair;

  public:
    Timer *timer;

    Network(Time &time)
        : random_fault(0.01), random_repair(0.001) {
        timer = new Timer(0, TimerMode::Once, &time, this);
    }

    void update(NetworkPayloadLight payload) override {
        if (buffer.empty()) {
            timer->resetWithDuration(2);
        }
        Buffer<NetworkPayloadLight>::update(payload);
    }

    void update(Timer *timer) override {
        if (!buffer.empty()) {
            if (random_fault(urng)) {
                if (random_repair(urng)) {
                    Notifier<LightUpdateMessage>::notify(
                        (Light)buffer.front()
                    );
                } else {
                    Notifier<Fault>::notify(true);
                }
            } else {
                Notifier<LightUpdateMessage>::notify(
                    (Light)buffer.front()
                );
            }

            buffer.pop_front();
            if (!buffer.empty()) {
                timer->resetWithDuration(2);
            }
        }
    }
};
