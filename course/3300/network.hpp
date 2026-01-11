#pragma once

#include "../../mocc/buffer.hpp"
#include "../../mocc/notifier.hpp"
#include "../../mocc/time.hpp"
#include "parameters.hpp"
#include <cstdlib>
#include <random>

class Network : public Observer<Timer *>,
                public Buffer<NetworkPayloadLight>,
                public Notifier<LightUpdateMessage> {
    std::bernoulli_distribution random_fault;

  public:
    Timer *timer;

    Network(Time &time) : random_fault(0.05) {
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
            if (!random_fault(urng)) {
                notify((Light)buffer.front());
            }
            buffer.pop_front();
            if (!buffer.empty()) {
                timer->resetWithDuration(2);
            }
        }
    }
};
