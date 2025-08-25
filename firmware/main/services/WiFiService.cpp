#include "WiFiService.h"

esp_err_t WiFiService::init() {
    ESP_LOGI(TAG, "WiFi service initialized");
    return ESP_OK;
}

void WiFiService::on_connected() {
    ESP_LOGI(TAG, "WiFi connected");
}

void WiFiService::on_disconnected() {
    ESP_LOGI(TAG, "WiFi disconnected");
}

