#pragma once

#include "esp_err.h"
#include "esp_log.h"

class UIManager {
public:
    esp_err_t init();
    esp_err_t show_screen(const char* screen_name);

private:
    static constexpr const char* TAG = "UIManager";
};
