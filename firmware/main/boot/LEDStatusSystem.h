/**
 * @file LEDStatusSystem.h
 * @brief ADHD-friendly LED status system for Story 1.1 boot feedback
 * 
 * Implements subtle, non-distracting LED status indicators designed specifically
 * for ADHD users. Provides clear visual feedback during boot sequence without
 * causing sensory overload.
 * 
 * Note: ESP32-S3-Touch-LCD-2 doesn't have dedicated RGB LED, so this system
 * uses the backlight control as a subtle status indicator.
 * 
 * @version 1.0.0
 * @date 2025-08-19
 * @author Sprint 1 Development Team
 */

#pragma once

#include "esp_err.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include <cmath>

// Forward declaration for boot state enum
enum class BootState;

/**
 * @brief LED status states for boot sequence
 */
enum class LEDState {
    OFF,              // LED completely off
    INIT,            // Initialization - soft blue breathing
    BOOT_PROGRESS,   // Boot progress - gentle green breathing
    SUCCESS,         // Boot success - brief green pulse then off
    ERROR,           // Boot error - gentle red breathing
    WARNING,         // Warning state - soft amber breathing
    SAFE_MODE        // Safe mode - minimal white breathing
};

/**
 * @brief ADHD-friendly LED configuration
 */
struct LEDConfig {
    uint8_t max_brightness = 30;        // Maximum brightness (% of full) - kept low for ADHD users
    uint32_t breathing_period_ms = 3000; // Breathing animation period - slow and calming
    uint32_t fade_step_ms = 50;         // Fade animation step timing - smooth transitions
    uint32_t solid_timeout_ms = 5000;   // Duration for solid color display
    bool use_warm_colors = true;        // Use warmer, less stimulating color temperatures
};

/**
 * @brief Breathing animation parameters
 */
struct BreathingParams {
    uint8_t hue;               // HSV hue (0-360 mapped to 0-255)
    uint8_t saturation;        // HSV saturation (0-100)
    uint8_t value;            // HSV value (0-100) 
    uint8_t max_brightness;   // Maximum brightness for breathing effect
    uint8_t current_brightness; // Current breathing brightness
    int8_t direction;         // Breathing direction: 1 = in, -1 = out
};

/**
 * @brief ADHD-friendly LED status system
 * 
 * Provides subtle, non-distracting visual feedback during boot sequence.
 * Designed specifically to avoid sensory overload for ADHD users while
 * still providing clear status information.
 */
class LEDStatusSystem {
public:
    /**
     * @brief Constructor
     */
    LEDStatusSystem();
    
    /**
     * @brief Destructor
     */
    ~LEDStatusSystem();
    
    /**
     * @brief Initialize LED status system
     * @param config ADHD-friendly LED configuration
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t init(const LEDConfig& config = LEDConfig{});
    
    /**
     * @brief Set LED to specific state
     * @param state LED state to display
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t set_led_state(LEDState state);
    
    /**
     * @brief Set LED state based on boot state
     * @param boot_state Current boot state
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t set_boot_state(BootState boot_state);
    
    /**
     * @brief Start boot sequence LED indication
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t start_boot_sequence();
    
    /**
     * @brief Signal successful boot completion
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t signal_boot_success();
    
    /**
     * @brief Signal boot failure
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t signal_boot_failure();
    
    /**
     * @brief Enter safe mode indication
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t enter_safe_mode();
    
    /**
     * @brief Set custom color with ADHD-friendly brightness limiting
     * @param hue HSV hue (0-255)
     * @param saturation HSV saturation (0-100)
     * @param value HSV value (0-100)
     * @param brightness Brightness level (0-100) - will be clamped to safe levels
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t set_custom_color(uint8_t hue, uint8_t saturation, uint8_t value, uint8_t brightness);
    
    /**
     * @brief Start breathing effect with specified color
     * @param hue HSV hue (0-255)
     * @param saturation HSV saturation (0-100)
     * @param value HSV value (0-100)
     * @param max_brightness Maximum brightness for breathing effect
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t start_breathing_effect(uint8_t hue, uint8_t saturation, uint8_t value, uint8_t max_brightness);
    
    /**
     * @brief Stop breathing effect and turn off LED
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t stop_breathing_effect();
    
    /**
     * @brief Get current LED state
     * @return Current LED state
     */
    LEDState get_current_state() const;
    
    /**
     * @brief Check if breathing effect is active
     * @return true if breathing, false otherwise
     */
    bool is_breathing_active() const;
    
    /**
     * @brief Log current status report
     */
    void log_status_report() const;

private:
    bool initialized_;                    // Initialization state
    LEDState current_state_;             // Current LED state
    LEDConfig config_;                   // ADHD-friendly configuration
    
    // Breathing animation
    bool breathing_enabled_;             // Breathing effect active
    esp_timer_handle_t breathing_timer_; // Timer for breathing effect
    TaskHandle_t breathing_task_handle_; // Task handle for breathing animation
    BreathingParams breathing_params_;   // Current breathing parameters
    
    /**
     * @brief Set solid LED color
     * @param hue HSV hue (0-255)
     * @param saturation HSV saturation (0-100)
     * @param value HSV value (0-100)
     * @param brightness Brightness level (0-100)
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t set_solid_color(uint8_t hue, uint8_t saturation, uint8_t value, uint8_t brightness);
    
    /**
     * @brief Breathing animation task
     * @param parameter Task parameter (LEDStatusSystem instance)
     */
    static void breathing_task(void* parameter);
    
    /**
     * @brief Update breathing animation frame
     */
    void update_breathing_animation();
    
    /**
     * @brief Breathing timer callback
     * @param arg Timer argument (LEDStatusSystem instance)
     */
    static void breathing_timer_callback(void* arg);
    
    static constexpr const char* TAG = "LED_STATUS";
};