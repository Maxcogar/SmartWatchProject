/**
 * @file BootManager.h
 * @brief Boot sequence management and coordination for Story 1.1
 * 
 * Implements the complete boot sequence with ADHD-friendly UX, progressive
 * error recovery, and memory management according to acceptance criteria.
 * 
 * @version 1.0.0
 * @date 2025-08-19
 * @author Sprint 1 Development Team
 */

#pragma once

#include <memory>
#include "esp_err.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"

// Forward declarations
class LEDStatusSystem;
class MemoryManager;
class DisplayBootManager;
class ErrorRecoverySystem;

/**
 * @brief Boot sequence states for state machine
 */
enum class BootState {
    INIT_START,
    LED_INIT,
    MEMORY_CHECK,
    DISPLAY_INIT,
    SPLASH_DISPLAY,
    TOUCH_INIT,
    NVS_INIT,
    BOOT_SUCCESS,
    BOOT_FAILURE,
    SAFE_MODE
};

/**
 * @brief Boot sequence configuration
 */
struct BootConfig {
    uint32_t boot_timeout_ms = 15000;      // 15 second TWDT timeout
    uint32_t splash_duration_ms = 2500;    // 2.5 second splash screen
    uint32_t min_heap_kb = 180;            // 180KB minimum heap
    uint32_t max_peak_kb = 280;            // 280KB maximum peak memory
    uint32_t emergency_heap_kb = 100;      // 100KB emergency threshold
    uint8_t display_brightness = 80;       // 80% default brightness
    uint32_t retry_delay_ms = 500;         // 500ms retry delay
    uint8_t max_retries = 3;               // Maximum retry attempts
};

/**
 * @brief Boot sequence metrics and telemetry
 */
struct BootMetrics {
    uint64_t boot_start_time_us;
    uint64_t boot_completion_time_us;
    uint32_t peak_memory_used_kb;
    uint32_t final_heap_free_kb;
    uint8_t component_failures;
    uint8_t retry_attempts;
    bool boot_success;
    BootState final_state;
};

/**
 * @brief Main boot sequence manager
 * 
 * Coordinates the complete boot process according to Story 1.1 acceptance criteria.
 * Implements ADHD-friendly UX, progressive error recovery, and comprehensive logging.
 */
class BootManager {
public:
    /**
     * @brief Constructor
     */
    BootManager();
    
    /**
     * @brief Destructor
     */
    ~BootManager();
    
    /**
     * @brief Initialize boot manager
     * @param config Boot configuration parameters
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t init(const BootConfig& config = BootConfig{});
    
    /**
     * @brief Execute complete boot sequence
     * @return ESP_OK on successful boot, error code otherwise
     */
    esp_err_t execute_boot_sequence();
    
    /**
     * @brief Get current boot state
     * @return Current boot state
     */
    BootState get_current_state() const;
    
    /**
     * @brief Get boot metrics
     * @return Boot telemetry data
     */
    const BootMetrics& get_boot_metrics() const;
    
    /**
     * @brief Check if boot completed successfully
     * @return true if boot succeeded, false otherwise
     */
    bool is_boot_successful() const;
    
    /**
     * @brief Enter safe mode with minimal drivers
     * @return ESP_OK on successful safe mode entry
     */
    esp_err_t enter_safe_mode();

private:
    // Configuration
    BootConfig config_;
    BootState current_state_;
    BootMetrics metrics_;
    
    // Component managers
    std::unique_ptr<LEDStatusSystem> led_system_;
    std::unique_ptr<MemoryManager> memory_manager_;
    std::unique_ptr<DisplayBootManager> display_manager_;
    std::unique_ptr<ErrorRecoverySystem> recovery_system_;
    
    // FreeRTOS synchronization
    SemaphoreHandle_t state_mutex_;
    esp_timer_handle_t boot_timer_;
    esp_timer_handle_t splash_timer_;
    
    // State machine methods
    esp_err_t transition_to_state(BootState new_state);
    esp_err_t execute_current_state();
    
    // Boot sequence steps
    esp_err_t init_led_system();
    esp_err_t check_memory_requirements();
    esp_err_t init_display_system();
    esp_err_t show_splash_screen();
    esp_err_t init_touch_system();
    esp_err_t init_nvs_system();
    esp_err_t finalize_boot_success();
    
    // Error handling
    esp_err_t handle_boot_failure(esp_err_t error_code);
    esp_err_t increment_failure_counter();
    bool should_enter_safe_mode();
    
    // Timing and metrics
    void start_boot_timer();
    void update_memory_metrics();
    void finalize_boot_metrics();
    
    // TWDT integration
    static void boot_timeout_callback(void* arg);
    
    // Logging
    static constexpr const char* TAG = "BOOT_MAIN";
};

/**
 * @brief Boot manager singleton access
 * @return Reference to global boot manager instance
 */
BootManager& get_boot_manager();