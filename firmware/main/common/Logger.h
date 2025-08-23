/**
 * @file Logger.h
 * @brief Simple logging system for ESP32-S3 ADHD SmartWatch
 * 
 * Provides a lightweight logging wrapper around ESP-IDF logging system
 * with additional features for debugging and production builds.
 * 
 * @version 1.0.0
 * @date 2025-08-19
 * @author ESP32-S3 Development Team
 */

#pragma once

#include "esp_log.h"

/**
 * @brief Log levels for the logger system
 */
typedef enum {
    LOG_LEVEL_NONE = 0,     // No logging
    LOG_LEVEL_ERROR = 1,    // Errors only
    LOG_LEVEL_WARN = 2,     // Warnings and above
    LOG_LEVEL_INFO = 3,     // Info and above
    LOG_LEVEL_DEBUG = 4,    // Debug and above
    LOG_LEVEL_VERBOSE = 5   // All logging
} log_level_t;

/**
 * @brief Simple logger class wrapper
 */
class Logger {
public:
    /**
     * @brief Initialize the logging system
     * @param level Log level to set
     */
    static void init(log_level_t level = LOG_LEVEL_INFO) {
        esp_log_level_t esp_level;
        
        switch (level) {
            case LOG_LEVEL_NONE:
                esp_level = ESP_LOG_NONE;
                break;
            case LOG_LEVEL_ERROR:
                esp_level = ESP_LOG_ERROR;
                break;
            case LOG_LEVEL_WARN:
                esp_level = ESP_LOG_WARN;
                break;
            case LOG_LEVEL_INFO:
                esp_level = ESP_LOG_INFO;
                break;
            case LOG_LEVEL_DEBUG:
                esp_level = ESP_LOG_DEBUG;
                break;
            case LOG_LEVEL_VERBOSE:
                esp_level = ESP_LOG_VERBOSE;
                break;
            default:
                esp_level = ESP_LOG_INFO;
                break;
        }
        
        esp_log_level_set("*", esp_level);
    }
    
    /**
     * @brief Set log level for a specific tag
     * @param tag Log tag
     * @param level Log level
     */
    static void set_level(const char* tag, log_level_t level) {
        esp_log_level_t esp_level = ESP_LOG_INFO;
        
        switch (level) {
            case LOG_LEVEL_NONE:
                esp_level = ESP_LOG_NONE;
                break;
            case LOG_LEVEL_ERROR:
                esp_level = ESP_LOG_ERROR;
                break;
            case LOG_LEVEL_WARN:
                esp_level = ESP_LOG_WARN;
                break;
            case LOG_LEVEL_INFO:
                esp_level = ESP_LOG_INFO;
                break;
            case LOG_LEVEL_DEBUG:
                esp_level = ESP_LOG_DEBUG;
                break;
            case LOG_LEVEL_VERBOSE:
                esp_level = ESP_LOG_VERBOSE;
                break;
        }
        
        esp_log_level_set(tag, esp_level);
    }
};