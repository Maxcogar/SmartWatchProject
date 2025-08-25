#pragma once

#include "esp_err.h"
#include "esp_log.h"

class StateManager {
public:
    enum class State {
        INIT,
        HOME
    };

    esp_err_t init();
    esp_err_t set_state(State state);
    State get_state() const;

private:
    static constexpr const char* TAG = "StateManager";
    State current_state_ = State::INIT;
};
