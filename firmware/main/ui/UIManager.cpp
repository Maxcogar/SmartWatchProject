#include "UIManager.h"

esp_err_t UIManager::init() {
    ESP_LOGI(TAG, "UIManager initialized");
    return ESP_OK;
}

esp_err_t UIManager::show_screen(const char* screen_name) {
    ESP_LOGI(TAG, "Showing screen: %s", screen_name);
    return ESP_OK;
}

