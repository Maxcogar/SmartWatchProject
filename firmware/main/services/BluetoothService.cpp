#include "BluetoothService.h"

esp_err_t BluetoothService::init() {
    ESP_LOGI(TAG, "Bluetooth service initialized");
    return ESP_OK;
}

void BluetoothService::on_connected() {
    ESP_LOGI(TAG, "Bluetooth connected");
}

void BluetoothService::on_disconnected() {
    ESP_LOGI(TAG, "Bluetooth disconnected");
}

