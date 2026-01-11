#pragma once

#include "mocc.hpp"
#include "notifier.hpp"
#include "observer.hpp"
#include "system.hpp"

/* docs.rs/bevy/latest/bevy/time/struct.Stopwatch.html
 * An object that measures time. It is a SystemObserver, so it must be attached
 * to a System for it to measure the time elapsed in the systme.
 *
 * System system.
 * Stopwatch stopwatch(1).
 *
 * system.addObserver(&stopwatch);
 * system.next();
 * system.next();
 *
 * stopwatch.elapsedTime(); // 2
 * */
class Time : public Observer<>, public Notifier<Time *> {
  private:
    real_t elapsed_time = 0;
    const real_t time_step;

  public:
    Time(real_t time_step, System *system = nullptr);

    real_t timeStep();

    /* Returns the "elapsed time" since the Time was started. */
    real_t elapsedTime();

    /* Synchronizes to a system. */
    void update() override;
};

enum class TimerMode {
    /* When the timer ends it doesn't restart. */
    Once,

    /* When the timer ends it automatically restarts. */
    Repeating
};

/* docs.rs/bevy/latest/bevy/time/struct.Timer.html */
/* A timer is synchronized to a system.
 * It updates the elapsed time as the system is simulated, until the duration of
 * the timer is over.
 * */
class Timer : public Observer<Time *>, public Notifier<Timer *> {
  private:
    real_t duration, elapsed_time = 0;
    bool is_finished = false;
    TimerMode mode;

  public:
    Timer(
        real_t duration,
        TimerMode mode,
        Time *time = nullptr,
        Observer<Timer *> *observer = nullptr
    );

    /* Resets the timer with a new initial duration. */
    void resetWithDuration(real_t duration);

    /* Synchronizes to a system. */
    void update(Time *) override;
};

// TODO: smart pointers
// TODO: option could be useful too! std::option<std::shared_ptr<System>> or
// std::option<System *>
// TODO: how to handle any type of ref in Notifier?
