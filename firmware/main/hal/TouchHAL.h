#pragma once

#include "esp_err.h"
#include "esp_log.h"

class TouchHAL {
public:
    esp_err_t init();

private:
    static constexpr const char* TAG = "TouchHAL";
};
