#pragma once

#include "esp_err.h"
#include "esp_log.h"

class WiFiService {
public:
    esp_err_t init();
    void on_connected();
    void on_disconnected();

private:
    static constexpr const char* TAG = "WiFiService";
};
