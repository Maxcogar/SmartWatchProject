#include "NvsService.h"

esp_err_t NvsService::init() {
    ESP_LOGI(TAG, "NVS service initialized");
    on_ready();
    return ESP_OK;
}

void NvsService::on_ready() {
    ESP_LOGI(TAG, "NVS ready");
}

