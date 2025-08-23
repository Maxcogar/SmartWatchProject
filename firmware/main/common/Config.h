/**
 * @file Config.h
 * @brief Global configuration and hardware definitions for ESP32-S3 ADHD SmartWatch
 * 
 * This file contains all hardware-specific pin definitions, system constants,
 * and configuration parameters for the Waveshare ESP32-S3-Touch-LCD-2 board.
 * 
 * @version 1.0.0
 * @date 2025-08-19
 * @author ESP32-S3 Development Team
 */

#pragma once

#include "sdkconfig.h"
#include "esp_log.h"

// Project Information
#define SMARTWATCH_VERSION_MAJOR        1
#define SMARTWATCH_VERSION_MINOR        0
#define SMARTWATCH_VERSION_PATCH        0
#define SMARTWATCH_VERSION_STRING       "1.0.0"
#define SMARTWATCH_PROJECT_NAME         "ADHD SmartWatch"
#define PROJECT_NAME                    SMARTWATCH_PROJECT_NAME
#define PROJECT_VERSION                 SMARTWATCH_VERSION_STRING

// Hardware Configuration - Waveshare ESP32-S3-Touch-LCD-2
#define SMARTWATCH_BOARD_NAME           "ESP32-S3-Touch-LCD-2"

// Display Configuration
#define DISPLAY_WIDTH                   CONFIG_ADHD_WATCH_DISPLAY_WIDTH
#define DISPLAY_HEIGHT                  CONFIG_ADHD_WATCH_DISPLAY_HEIGHT
#define DISPLAY_BITS_PER_PIXEL          16
#define DISPLAY_BUFFER_SIZE            (DISPLAY_WIDTH * DISPLAY_HEIGHT * 2)

// Display SPI Configuration (based on Waveshare ESP32-S3-Touch-LCD-2 hardware)
#define DISPLAY_SPI_HOST                SPI2_HOST
#define DISPLAY_SPI_CLOCK_MHZ           80
#define DISPLAY_PIN_MOSI                38    // From hardware example: EXAMPLE_PIN_NUM_MOSI
#define DISPLAY_PIN_CLK                 39    // From hardware example: EXAMPLE_PIN_NUM_SCLK
#define DISPLAY_PIN_MISO                40    // From hardware example: EXAMPLE_PIN_NUM_MISO
#define DISPLAY_PIN_CS                  45    // From hardware example: EXAMPLE_PIN_NUM_LCD_CS
#define DISPLAY_PIN_DC                  42    // From hardware example: EXAMPLE_PIN_NUM_LCD_DC
#define DISPLAY_PIN_RST                 -1    // From hardware example: EXAMPLE_PIN_NUM_LCD_RST (not used)
#define DISPLAY_PIN_BL                  CONFIG_ADHD_WATCH_BACKLIGHT_GPIO

// Touch Controller Configuration (CST816S)
#define TOUCH_I2C_HOST                  I2C_NUM_0
#define TOUCH_I2C_CLOCK_HZ              400000
#define TOUCH_PIN_SDA                   CONFIG_ADHD_WATCH_TOUCH_I2C_SDA
#define TOUCH_PIN_SCL                   CONFIG_ADHD_WATCH_TOUCH_I2C_SCL
#define TOUCH_PIN_INT                   CONFIG_ADHD_WATCH_TOUCH_INT
#define TOUCH_PIN_RST                   CONFIG_ADHD_WATCH_TOUCH_RST
#define TOUCH_I2C_ADDRESS               0x15

// Power Management Configuration
#define BATTERY_ADC_UNIT                ADC_UNIT_1
#define BATTERY_ADC_CHANNEL             CONFIG_ADHD_WATCH_BATTERY_ADC_CHANNEL
#define BATTERY_ADC_ATTEN               ADC_ATTEN_DB_11
#define BATTERY_ADC_BITWIDTH            ADC_BITWIDTH_12

// Battery voltage calculation (voltage divider)
#define BATTERY_VOLTAGE_DIVIDER_RATIO   2.0f
#define BATTERY_MAX_VOLTAGE             4.2f
#define BATTERY_MIN_VOLTAGE             3.0f

// Power thresholds (from Kconfig)
#define BATTERY_LOW_THRESHOLD           CONFIG_ADHD_WATCH_BATTERY_LOW_THRESHOLD
#define BATTERY_CRITICAL_THRESHOLD      CONFIG_ADHD_WATCH_BATTERY_CRITICAL_THRESHOLD

// Sleep configuration
#define DISPLAY_SLEEP_TIMEOUT_MS        (CONFIG_ADHD_WATCH_SLEEP_TIMEOUT_SECONDS * 1000)
#define DEEP_SLEEP_TIMEOUT_MS           (CONFIG_ADHD_WATCH_DEEP_SLEEP_TIMEOUT_MINUTES * 60 * 1000)

// IMU Configuration (QMI8658C) - Optional
#define IMU_I2C_HOST                    I2C_NUM_1
#define IMU_I2C_CLOCK_HZ                400000
#define IMU_PIN_SDA                     17
#define IMU_PIN_SCL                     18
#define IMU_I2C_ADDRESS                 0x6B

// SD Card Configuration - Optional
#define SD_SPI_HOST                     SPI3_HOST
#define SD_PIN_MISO                     37
#define SD_PIN_MOSI                     35
#define SD_PIN_CLK                      36
#define SD_PIN_CS                       34

// BLE Configuration
#define BLE_DEVICE_NAME                 CONFIG_ADHD_WATCH_BLE_DEVICE_NAME
#define BLE_MAX_CONNECTIONS             1
#define BLE_SECURITY_LEVEL              CONFIG_ADHD_WATCH_BLE_SECURITY_LEVEL

// BLE Service UUIDs (from architecture specification)
#define BLE_SERVICE_UUID                "12345678-1234-5678-9abc-123456789abc"
#define BLE_CHAR_TASK_DATA_UUID         "12345678-1234-5678-9abc-123456789abd"
#define BLE_CHAR_NOTIFICATION_UUID      "12345678-1234-5678-9abc-123456789abe"
#define BLE_CHAR_COMMAND_UUID           "12345678-1234-5678-9abc-123456789abf"
#define BLE_CHAR_DEVICE_STATE_UUID      "12345678-1234-5678-9abc-123456789abg"

// Focus Session Configuration
#define DEFAULT_FOCUS_DURATION_MIN      CONFIG_ADHD_WATCH_DEFAULT_FOCUS_DURATION
#define SHORT_BREAK_DURATION_MIN        CONFIG_ADHD_WATCH_SHORT_BREAK_DURATION
#define LONG_BREAK_DURATION_MIN         CONFIG_ADHD_WATCH_LONG_BREAK_DURATION

// Notification Configuration
#define MAX_NOTIFICATIONS               CONFIG_ADHD_WATCH_MAX_NOTIFICATIONS
#define NOTIFICATION_TIMEOUT_MS         (CONFIG_ADHD_WATCH_NOTIFICATION_TIMEOUT_SECONDS * 1000)
#define MAX_NOTIFICATION_TEXT_LENGTH    200

// System Task Configuration
#define MAIN_TASK_STACK_SIZE            8192
#define MAIN_TASK_PRIORITY              5
#define UI_TASK_STACK_SIZE              6144
#define UI_TASK_PRIORITY                4
#define BLE_TASK_STACK_SIZE             4096
#define BLE_TASK_PRIORITY               6
#define WIFI_TASK_STACK_SIZE            4096
#define WIFI_TASK_PRIORITY              3

// Memory Configuration
#define HEAP_CAPS_PSRAM                 MALLOC_CAP_SPIRAM
#define HEAP_CAPS_INTERNAL              MALLOC_CAP_INTERNAL
#define LVGL_BUFFER_SIZE                (DISPLAY_WIDTH * DISPLAY_HEIGHT / 4)

// Timing Configuration
#define LVGL_TICK_PERIOD_MS             10
#define DISPLAY_REFRESH_PERIOD_MS       33  // ~30 FPS
#define SYSTEM_MONITOR_PERIOD_MS        1000
#define BLE_ADV_INTERVAL_MIN            160   // 100ms
#define BLE_ADV_INTERVAL_MAX            160   // 100ms

// Debug Configuration
#ifdef CONFIG_ADHD_WATCH_DEBUG
#define DEBUG_MODE                      1
#define LOG_LEVEL                       ESP_LOG_DEBUG
#define ENABLE_PERFORMANCE_MONITOR      1
#define ENABLE_MEMORY_MONITOR           1
#else
#define DEBUG_MODE                      0
#define LOG_LEVEL                       ESP_LOG_INFO
#define ENABLE_PERFORMANCE_MONITOR      0
#define ENABLE_MEMORY_MONITOR           0
#endif

// Production Configuration
#ifdef CONFIG_ADHD_WATCH_PRODUCTION
#define PRODUCTION_MODE                 1
#define ENABLE_OTA_UPDATES              1
#define ENABLE_SECURE_BOOT              1
#define ENABLE_FLASH_ENCRYPTION         1
#else
#define PRODUCTION_MODE                 0
#define ENABLE_OTA_UPDATES              0
#define ENABLE_SECURE_BOOT              0
#define ENABLE_FLASH_ENCRYPTION         0
#endif

// System Limits and Constraints
#define MAX_TASKS                       50
#define MAX_TASK_TITLE_LENGTH           100
#define MAX_USERNAME_LENGTH             50
#define MAX_WIFI_SSID_LENGTH            32
#define MAX_WIFI_PASSWORD_LENGTH        64

// NVS Configuration
#define NVS_NAMESPACE                   "adhd_watch"
#define NVS_KEY_APP_STATE              "app_state"
#define NVS_KEY_USER_SETTINGS          "user_settings"
#define NVS_KEY_WIFI_CONFIG            "wifi_config"
#define NVS_KEY_BLE_KEYS               "ble_keys"

// Error Handling
#define ESP_RETURN_ON_ERROR(x, tag, format, ...) do { \
    esp_err_t err_rc_ = (x); \
    if (unlikely(err_rc_ != ESP_OK)) { \
        ESP_LOGE(tag, "%s(%d): " format, __FUNCTION__, __LINE__, ##__VA_ARGS__); \
        return err_rc_; \
    } \
} while(0)

#define ESP_GOTO_ON_ERROR(x, goto_tag, tag, format, ...) do { \
    esp_err_t err_rc_ = (x); \
    if (unlikely(err_rc_ != ESP_OK)) { \
        ESP_LOGE(tag, "%s(%d): " format, __FUNCTION__, __LINE__, ##__VA_ARGS__); \
        goto goto_tag; \
    } \
} while(0)

// Utility Macros
#define ARRAY_SIZE(x)                   (sizeof(x) / sizeof((x)[0]))
#define MIN(a, b)                       ((a) < (b) ? (a) : (b))
#define MAX(a, b)                       ((a) > (b) ? (a) : (b))
#define CLAMP(x, min, max)              (MIN(MAX(x, min), max))

// Performance Monitoring
#if ENABLE_PERFORMANCE_MONITOR
#define PERF_START(name)                uint32_t name##_start = esp_timer_get_time()
#define PERF_END(name, tag)             do { \
    uint32_t name##_end = esp_timer_get_time(); \
    ESP_LOGI(tag, "PERF: " #name " took %lu us", name##_end - name##_start); \
} while(0)
#else
#define PERF_START(name)
#define PERF_END(name, tag)
#endif

// Memory Monitoring
#if ENABLE_MEMORY_MONITOR
#define MEM_CHECK(tag)                  do { \
    size_t free_heap = esp_get_free_heap_size(); \
    size_t min_free = esp_get_minimum_free_heap_size(); \
    ESP_LOGI(tag, "MEM: Free heap: %zu bytes, Min free: %zu bytes", free_heap, min_free); \
} while(0)
#else
#define MEM_CHECK(tag)
#endif

// Validation Macros
#define VALIDATE_POINTER(ptr, tag, msg) do { \
    if (!(ptr)) { \
        ESP_LOGE(tag, "NULL pointer: " msg); \
        return ESP_ERR_INVALID_ARG; \
    } \
} while(0)

#define VALIDATE_RANGE(val, min, max, tag, msg) do { \
    if ((val) < (min) || (val) > (max)) { \
        ESP_LOGE(tag, "Value out of range: " msg " (got %d, expected %d-%d)", val, min, max); \
        return ESP_ERR_INVALID_ARG; \
    } \
} while(0)