#include "time.hpp"

Time::Time(real_t time_step, System *system) : time_step(time_step) {
    if (system != nullptr) {
        system->addObserver(this);
    }
}

real_t Time::timeStep() { return time_step; }

real_t Time::elapsedTime() { return elapsed_time; }

void Time::update() {
    elapsed_time += time_step;
    notify(this);
}

Timer::Timer(
    real_t duration,
    TimerMode mode,
    Time *time,
    Observer<Timer *> *observer
)
    : duration(duration), mode(mode) {

    if (time != nullptr) {
        time->addObserver(this);
    }

    if (observer != nullptr) {
        this->addObserver(observer);
    }
}

void Timer::resetWithDuration(real_t duration) {
    this->duration = duration;
    this->elapsed_time = 0;
    this->is_finished = false;
}

void Timer::update(Time *time) {
    if (elapsed_time < duration) {
        elapsed_time += time->timeStep();
    }

    if (elapsed_time + time->timeStep() >= duration && !is_finished) {
        switch (mode) {
        case TimerMode::Repeating:
            elapsed_time = 0;
            break;
        case TimerMode::Once:
            is_finished = true;
            break;
        }

        Notifier<Timer *>::notify(this);
    }
}
