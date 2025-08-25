#pragma once

#include "esp_err.h"
#include "esp_log.h"

class NvsService {
public:
    esp_err_t init();
    void on_ready();

private:
    static constexpr const char* TAG = "NvsService";
};
