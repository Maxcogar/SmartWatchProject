#include "StateManager.h"

esp_err_t StateManager::init() {
    current_state_ = State::INIT;
    ESP_LOGI(TAG, "StateManager initialized");
    return ESP_OK;
}

esp_err_t StateManager::set_state(State state) {
    current_state_ = state;
    ESP_LOGI(TAG, "State changed");
    return ESP_OK;
}

StateManager::State StateManager::get_state() const {
    return current_state_;
}

