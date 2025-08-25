#pragma once

#include "esp_err.h"
#include "esp_log.h"

class DisplayHAL {
public:
    esp_err_t init();

private:
    static constexpr const char* TAG = "DisplayHAL";
};
