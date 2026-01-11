#pragma once

#include "../../mocc/buffer.hpp"
#include "../../mocc/notifier.hpp"
#include "../../mocc/time.hpp"
#include "parameters.hpp"
#include <cstdlib>

class Network : public Observer<Timer *>,
                public Buffer<NetworkPayloadLight>,
                public Notifier<LightUpdateMessage> {

  public:
    Timer *timer;

    Network(Time &time) {
        Timer *timer =
            new Timer(0, TimerMode::Once, &time, this);
    }

    void update(NetworkPayloadLight payload) override {
        if (buffer.empty()) {
            timer->resetWithDuration(2);
        }
        Buffer<NetworkPayloadLight>::update(payload);
    }

    void update(Timer *timer) override {
        if (!buffer.empty()) {
            notify((Light)buffer.front());
            buffer.pop_front();

            if (!buffer.empty()) {
                timer->resetWithDuration(2);
            }
        }
    }
};
