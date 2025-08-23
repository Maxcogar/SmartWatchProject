/**
 * @file MemoryManager.h
 * @brief Memory management and monitoring for Story 1.1 boot requirements
 * 
 * Implements strict memory threshold enforcement with 180KB minimum heap,
 * 280KB peak memory tracking, and emergency procedures for low memory conditions.
 * 
 * @version 1.0.0
 * @date 2025-08-19
 * @author Sprint 1 Development Team
 */

#pragma once

#include "esp_err.h"
#include "esp_log.h"
#include "esp_heap_caps.h"
#include "esp_system.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"

/**
 * @brief Memory thresholds from Story 1.1 acceptance criteria
 */
struct MemoryThresholds {
    uint32_t min_heap_free_kb = 180;      // AC1: 180KB minimum after boot
    uint32_t max_peak_usage_kb = 280;     // AC1: 280KB maximum during init
    uint32_t emergency_threshold_kb = 100; // AC1: Emergency procedure trigger
    uint32_t warning_threshold_kb = 150;   // Early warning threshold
    uint32_t monitoring_interval_ms = 100; // Memory monitoring frequency
};

/**
 * @brief Memory usage statistics
 */
struct MemoryStats {
    uint32_t current_free_heap_kb;
    uint32_t current_used_heap_kb;
    uint32_t peak_used_heap_kb;
    uint32_t min_free_heap_kb;
    uint32_t total_heap_kb;
    uint32_t largest_free_block_kb;
    bool emergency_triggered;
    uint64_t last_update_time_us;
};

/**
 * @brief Memory allocation tracking entry
 */
struct MemoryAllocation {
    void* ptr;
    size_t size;
    uint64_t timestamp_us;
    const char* tag;
    uint32_t line_number;
    const char* file_name;
};

/**
 * @brief Memory manager for boot sequence monitoring
 * 
 * Provides comprehensive memory monitoring, threshold enforcement, and
 * emergency procedures as required by Story 1.1 acceptance criteria.
 */
class MemoryManager {
public:
    /**
     * @brief Constructor
     */
    MemoryManager();
    
    /**
     * @brief Destructor
     */
    ~MemoryManager();
    
    /**
     * @brief Initialize memory management system
     * @param thresholds Memory threshold configuration
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t init(const MemoryThresholds& thresholds = MemoryThresholds{});
    
    /**
     * @brief Start memory monitoring during boot
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t start_boot_monitoring();
    
    /**
     * @brief Stop memory monitoring after boot completion
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t stop_boot_monitoring();
    
    /**
     * @brief Check if memory requirements are met for successful boot
     * @return ESP_OK if requirements met, ESP_ERR_NO_MEM otherwise
     */
    esp_err_t validate_boot_requirements();
    
    /**
     * @brief Get current memory statistics
     * @return Current memory usage statistics
     */
    const MemoryStats& get_memory_stats() const;
    
    /**
     * @brief Check if emergency threshold has been triggered
     * @return true if emergency procedures needed, false otherwise
     */
    bool is_emergency_triggered() const;
    
    /**
     * @brief Execute emergency memory procedures
     * @return ESP_OK if emergency handled, error code otherwise
     */
    esp_err_t execute_emergency_procedures();
    
    /**
     * @brief Force garbage collection and heap defragmentation
     * @return ESP_OK on success, error code otherwise
     */
    esp_err_t force_memory_cleanup();
    
    /**
     * @brief Log detailed memory report
     * @param detailed Include allocation tracking if enabled
     */
    void log_memory_report(bool detailed = false);
    
    /**
     * @brief Check if peak memory usage exceeded limits during boot
     * @return true if peak exceeded 280KB limit, false otherwise
     */
    bool peak_memory_exceeded() const;
    
    /**
     * @brief Get peak memory usage during boot sequence
     * @return Peak memory usage in KB
     */
    uint32_t get_peak_memory_usage_kb() const;

private:
    // Configuration
    MemoryThresholds thresholds_;
    MemoryStats stats_;
    bool initialized_;
    bool monitoring_active_;
    bool emergency_triggered_;
    
    // Monitoring state
    TaskHandle_t monitoring_task_handle_;
    SemaphoreHandle_t stats_mutex_;
    uint64_t boot_start_time_us_;
    
    // Memory tracking (debug builds only)
    #ifdef CONFIG_HEAP_TRACING_STANDALONE
    std::vector<MemoryAllocation> allocations_;
    SemaphoreHandle_t allocation_mutex_;
    #endif
    
    // Monitoring task
    static void memory_monitoring_task(void* parameter);
    void execute_monitoring_cycle();
    
    // Memory analysis
    esp_err_t update_memory_statistics();
    esp_err_t check_memory_thresholds();
    esp_err_t handle_threshold_violation(uint32_t current_free_kb);
    
    // Emergency procedures
    esp_err_t emergency_free_caches();
    esp_err_t emergency_stop_non_critical_tasks();
    esp_err_t emergency_reduce_heap_usage();
    
    // Heap analysis utilities
    uint32_t bytes_to_kb(size_t bytes) const;
    size_t kb_to_bytes(uint32_t kb) const;
    esp_err_t get_heap_info(size_t& free_size, size_t& total_size, size_t& largest_block);
    
    // Allocation tracking (debug builds)
    #ifdef CONFIG_HEAP_TRACING_STANDALONE
    void track_allocation(void* ptr, size_t size, const char* tag, 
                         uint32_t line, const char* file);
    void track_deallocation(void* ptr);
    void log_allocation_report();
    #endif
    
    // Logging and diagnostics
    void log_memory_threshold_warning(const char* threshold_name, 
                                    uint32_t current_kb, uint32_t threshold_kb);
    void log_emergency_trigger(uint32_t current_free_kb);
    
    static constexpr const char* TAG = "MEMORY";
};

/**
 * @brief RAII memory monitor for critical boot sections
 * 
 * Automatically tracks memory usage during construction/destruction
 * to identify memory-intensive boot operations.
 */
class ScopedMemoryMonitor {
public:
    ScopedMemoryMonitor(const char* operation_name, MemoryManager& manager);
    ~ScopedMemoryMonitor();
    
private:
    const char* operation_name_;
    MemoryManager& manager_;
    uint32_t start_free_kb_;
    uint64_t start_time_us_;
};

// Convenience macro for scoped memory monitoring
#define MONITOR_MEMORY_USAGE(name, manager) \
    ScopedMemoryMonitor _monitor(name, manager)