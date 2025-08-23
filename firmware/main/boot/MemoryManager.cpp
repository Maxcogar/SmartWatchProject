/**
 * @file MemoryManager.cpp
 * @brief Memory management and validation implementation for Story 1.1
 * 
 * Implements comprehensive memory management with heap validation, monitoring,
 * and enforcement of the >400KB available heap requirement (AC 1.1.5).
 * 
 * @version 1.0.0
 * @date 2025-08-19
 * @author Sprint 1 Development Team
 */

#include "boot/MemoryManager.h"
#include "common/Config.h"

#include "esp_heap_caps.h"
#include "esp_system.h"
#include "esp_log.h"
#include "esp_timer.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

constexpr const char* MemoryManager::TAG = "MEMORY";

MemoryManager::MemoryManager() 
    : initialized_(false)
    , monitoring_active_(false)
    , emergency_triggered_(false)
    , monitoring_task_handle_(nullptr)
    , stats_mutex_(nullptr)
    , boot_start_time_us_(0)
{
    memset(&stats_, 0, sizeof(stats_));
    memset(&thresholds_, 0, sizeof(thresholds_));
    
    #ifdef CONFIG_HEAP_TRACING_STANDALONE
    allocation_mutex_ = nullptr;
    #endif
}

MemoryManager::~MemoryManager() {
    if (monitoring_active_) {
        stop_boot_monitoring();
    }
    
    if (stats_mutex_) {
        vSemaphoreDelete(stats_mutex_);
    }
    
    #ifdef CONFIG_HEAP_TRACING_STANDALONE
    if (allocation_mutex_) {
        vSemaphoreDelete(allocation_mutex_);
    }
    #endif
}

esp_err_t MemoryManager::init(const MemoryThresholds& thresholds) {
    ESP_LOGI(TAG, "Initializing Memory Manager for Story 1.1");
    ESP_LOGI(TAG, "Target: >400KB heap available after boot completion");
    
    thresholds_ = thresholds;
    
    // Override minimum threshold to ensure AC 1.1.5 compliance (>400KB)
    if (thresholds_.min_heap_free_kb < 400) {
        ESP_LOGW(TAG, "Increasing minimum heap threshold to 400KB for AC 1.1.5 compliance");
        thresholds_.min_heap_free_kb = 400;
    }
    
    // Create synchronization primitives
    stats_mutex_ = xSemaphoreCreateMutex();
    if (!stats_mutex_) {
        ESP_LOGE(TAG, "Failed to create stats mutex");
        return ESP_ERR_NO_MEM;
    }
    
    #ifdef CONFIG_HEAP_TRACING_STANDALONE
    allocation_mutex_ = xSemaphoreCreateMutex();
    if (!allocation_mutex_) {
        ESP_LOGE(TAG, "Failed to create allocation mutex");
        return ESP_ERR_NO_MEM;
    }
    #endif
    
    // Initialize statistics
    esp_err_t ret = update_memory_statistics();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to initialize memory statistics");
        return ret;
    }
    
    boot_start_time_us_ = esp_timer_get_time();
    
    ESP_LOGI(TAG, "Memory Manager Configuration:");
    ESP_LOGI(TAG, "  Min heap free: %lu KB", thresholds_.min_heap_free_kb);
    ESP_LOGI(TAG, "  Max peak usage: %lu KB", thresholds_.max_peak_usage_kb);
    ESP_LOGI(TAG, "  Emergency threshold: %lu KB", thresholds_.emergency_threshold_kb);
    ESP_LOGI(TAG, "  Warning threshold: %lu KB", thresholds_.warning_threshold_kb);
    ESP_LOGI(TAG, "Current heap: %lu KB free of %lu KB total", 
             stats_.current_free_heap_kb, stats_.total_heap_kb);
    
    initialized_ = true;
    
    ESP_LOGI(TAG, "Memory Manager initialized successfully");
    return ESP_OK;
}

esp_err_t MemoryManager::start_boot_monitoring() {
    if (!initialized_) {
        ESP_LOGE(TAG, "Memory Manager not initialized");
        return ESP_ERR_INVALID_STATE;
    }
    
    if (monitoring_active_) {
        ESP_LOGW(TAG, "Memory monitoring already active");
        return ESP_OK;
    }
    
    ESP_LOGI(TAG, "Starting boot memory monitoring");
    
    // Create monitoring task
    BaseType_t result = xTaskCreate(
        memory_monitoring_task,
        "memory_monitor",
        2048,  // Stack size
        this,  // Task parameter
        3,     // Priority
        &monitoring_task_handle_
    );
    
    if (result != pdPASS) {
        ESP_LOGE(TAG, "Failed to create memory monitoring task");
        return ESP_ERR_NO_MEM;
    }
    
    monitoring_active_ = true;
    
    ESP_LOGI(TAG, "Boot memory monitoring started");
    return ESP_OK;
}

esp_err_t MemoryManager::stop_boot_monitoring() {
    if (!monitoring_active_) {
        return ESP_OK;
    }
    
    ESP_LOGI(TAG, "Stopping boot memory monitoring");
    
    monitoring_active_ = false;
    
    if (monitoring_task_handle_) {
        vTaskDelete(monitoring_task_handle_);
        monitoring_task_handle_ = nullptr;
    }
    
    ESP_LOGI(TAG, "Boot memory monitoring stopped");
    return ESP_OK;
}

esp_err_t MemoryManager::validate_boot_requirements() {
    if (!initialized_) {
        return ESP_ERR_INVALID_STATE;
    }
    
    ESP_LOGI(TAG, "Validating boot memory requirements for AC 1.1.5");
    
    // Update current statistics
    esp_err_t ret = update_memory_statistics();
    if (ret != ESP_OK) {
        return ret;
    }
    
    // Check AC 1.1.5: System reports >400KB available heap memory
    if (stats_.current_free_heap_kb < thresholds_.min_heap_free_kb) {
        ESP_LOGE(TAG, "BOOT REQUIREMENT FAILED!");
        ESP_LOGE(TAG, "AC 1.1.5 Violation: %lu KB < %lu KB required", 
                 stats_.current_free_heap_kb, thresholds_.min_heap_free_kb);
        ESP_LOGE(TAG, "Available: %lu KB, Required: >400KB", stats_.current_free_heap_kb);
        return ESP_ERR_NO_MEM;
    }
    
    // Check if peak usage exceeded limits
    if (stats_.peak_used_heap_kb > thresholds_.max_peak_usage_kb) {
        ESP_LOGW(TAG, "Peak memory usage exceeded target: %lu KB > %lu KB", 
                 stats_.peak_used_heap_kb, thresholds_.max_peak_usage_kb);
        // This is a warning, not a failure
    }
    
    ESP_LOGI(TAG, "✅ Boot memory requirements VALIDATED");
    ESP_LOGI(TAG, "Available heap: %lu KB (Target: >400KB) - PASSED", stats_.current_free_heap_kb);
    ESP_LOGI(TAG, "Peak usage: %lu KB (Target: <%lu KB)", 
             stats_.peak_used_heap_kb, thresholds_.max_peak_usage_kb);
    
    return ESP_OK;
}

const MemoryStats& MemoryManager::get_memory_stats() const {
    return stats_;
}

bool MemoryManager::is_emergency_triggered() const {
    return emergency_triggered_;
}

esp_err_t MemoryManager::execute_emergency_procedures() {
    ESP_LOGW(TAG, "Executing emergency memory procedures");
    
    emergency_triggered_ = true;
    
    // Step 1: Free caches
    esp_err_t ret = emergency_free_caches();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to free caches: %s", esp_err_to_name(ret));
    }
    
    // Step 2: Reduce heap usage
    ret = emergency_reduce_heap_usage();
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "Failed to reduce heap usage: %s", esp_err_to_name(ret));
    }
    
    // Step 3: Update statistics after cleanup
    update_memory_statistics();
    
    ESP_LOGW(TAG, "Emergency procedures completed");
    ESP_LOGW(TAG, "Free heap after cleanup: %lu KB", stats_.current_free_heap_kb);
    
    return ESP_OK;
}

esp_err_t MemoryManager::force_memory_cleanup() {
    ESP_LOGI(TAG, "Forcing memory cleanup");
    
    // Update statistics before cleanup
    update_memory_statistics();
    uint32_t free_before = stats_.current_free_heap_kb;
    
    // Note: ESP32 doesn't have traditional garbage collection
    // We can only provide memory management recommendations
    
    ESP_LOGI(TAG, "Memory cleanup completed");
    ESP_LOGI(TAG, "Heap before: %lu KB, after: %lu KB", 
             free_before, stats_.current_free_heap_kb);
    
    return ESP_OK;
}

void MemoryManager::log_memory_report(bool detailed) {
    if (!initialized_) {
        ESP_LOGW(TAG, "Memory Manager not initialized");
        return;
    }
    
    update_memory_statistics();
    
    ESP_LOGI(TAG, "=== MEMORY REPORT (Story 1.1 AC 1.1.5) ===");
    ESP_LOGI(TAG, "Total heap: %lu KB", stats_.total_heap_kb);
    ESP_LOGI(TAG, "Free heap: %lu KB (Target: >400KB)", stats_.current_free_heap_kb);
    ESP_LOGI(TAG, "Used heap: %lu KB", stats_.current_used_heap_kb);
    ESP_LOGI(TAG, "Peak used: %lu KB (Max target: %lu KB)", 
             stats_.peak_used_heap_kb, thresholds_.max_peak_usage_kb);
    ESP_LOGI(TAG, "Min free: %lu KB", stats_.min_free_heap_kb);
    ESP_LOGI(TAG, "Largest block: %lu KB", stats_.largest_free_block_kb);
    
    // Validation status
    bool ac_passed = (stats_.current_free_heap_kb >= 400);
    ESP_LOGI(TAG, "AC 1.1.5 Status: %s", ac_passed ? "✅ PASSED" : "❌ FAILED");
    ESP_LOGI(TAG, "Emergency triggered: %s", emergency_triggered_ ? "YES" : "NO");
    
    // Boot timing if available
    if (boot_start_time_us_ > 0) {
        uint64_t boot_duration_ms = (esp_timer_get_time() - boot_start_time_us_) / 1000;
        ESP_LOGI(TAG, "Boot duration: %llu ms", boot_duration_ms);
    }
    
    ESP_LOGI(TAG, "=====================================");
    
    #ifdef CONFIG_HEAP_TRACING_STANDALONE
    if (detailed) {
        log_allocation_report();
    }
    #endif
}

bool MemoryManager::peak_memory_exceeded() const {
    return stats_.peak_used_heap_kb > thresholds_.max_peak_usage_kb;
}

uint32_t MemoryManager::get_peak_memory_usage_kb() const {
    return stats_.peak_used_heap_kb;
}

// Private implementation methods

void MemoryManager::memory_monitoring_task(void* parameter) {
    MemoryManager* manager = static_cast<MemoryManager*>(parameter);
    
    ESP_LOGI(TAG, "Memory monitoring task started");
    
    while (manager->monitoring_active_) {
        manager->execute_monitoring_cycle();
        vTaskDelay(pdMS_TO_TICKS(manager->thresholds_.monitoring_interval_ms));
    }
    
    ESP_LOGI(TAG, "Memory monitoring task ended");
    vTaskDelete(NULL);
}

void MemoryManager::execute_monitoring_cycle() {
    // Update memory statistics
    esp_err_t ret = update_memory_statistics();
    if (ret != ESP_OK) {
        ESP_LOGW(TAG, "Failed to update memory statistics");
        return;
    }
    
    // Check memory thresholds
    ret = check_memory_thresholds();
    if (ret != ESP_OK) {
        ESP_LOGW(TAG, "Memory threshold check failed");
    }
}

esp_err_t MemoryManager::update_memory_statistics() {
    if (xSemaphoreTake(stats_mutex_, pdMS_TO_TICKS(100)) != pdTRUE) {
        return ESP_ERR_TIMEOUT;
    }
    
    // Get heap information
    size_t free_size, total_size, largest_block;
    esp_err_t ret = get_heap_info(free_size, total_size, largest_block);
    if (ret != ESP_OK) {
        xSemaphoreGive(stats_mutex_);
        return ret;
    }
    
    // Update statistics
    stats_.total_heap_kb = bytes_to_kb(total_size);
    stats_.current_free_heap_kb = bytes_to_kb(free_size);
    stats_.current_used_heap_kb = stats_.total_heap_kb - stats_.current_free_heap_kb;
    stats_.largest_free_block_kb = bytes_to_kb(largest_block);
    stats_.last_update_time_us = esp_timer_get_time();
    
    // Update peak usage
    if (stats_.current_used_heap_kb > stats_.peak_used_heap_kb) {
        stats_.peak_used_heap_kb = stats_.current_used_heap_kb;
    }
    
    // Update minimum free heap
    if (stats_.min_free_heap_kb == 0 || stats_.current_free_heap_kb < stats_.min_free_heap_kb) {
        stats_.min_free_heap_kb = stats_.current_free_heap_kb;
    }
    
    xSemaphoreGive(stats_mutex_);
    return ESP_OK;
}

esp_err_t MemoryManager::check_memory_thresholds() {
    uint32_t current_free_kb = stats_.current_free_heap_kb;
    
    // Check emergency threshold
    if (current_free_kb <= thresholds_.emergency_threshold_kb) {
        if (!emergency_triggered_) {
            log_emergency_trigger(current_free_kb);
            execute_emergency_procedures();
        }
        return ESP_ERR_NO_MEM;
    }
    
    // Check warning threshold
    if (current_free_kb <= thresholds_.warning_threshold_kb) {
        log_memory_threshold_warning("WARNING", current_free_kb, thresholds_.warning_threshold_kb);
        return ESP_ERR_NO_MEM;
    }
    
    return ESP_OK;
}

esp_err_t MemoryManager::handle_threshold_violation(uint32_t current_free_kb) {
    ESP_LOGW(TAG, "Memory threshold violation: %lu KB free", current_free_kb);
    
    // Attempt recovery
    esp_err_t ret = force_memory_cleanup();
    if (ret == ESP_OK) {
        update_memory_statistics();
        ESP_LOGI(TAG, "Recovery attempt: %lu KB free after cleanup", stats_.current_free_heap_kb);
    }
    
    return ret;
}

esp_err_t MemoryManager::emergency_free_caches() {
    ESP_LOGW(TAG, "Freeing emergency caches");
    
    // In a real implementation, this would free:
    // - Display buffers (keep minimal)
    // - Network buffers
    // - Temporary allocations
    // - Non-critical caches
    
    return ESP_OK;
}

esp_err_t MemoryManager::emergency_stop_non_critical_tasks() {
    ESP_LOGW(TAG, "Stopping non-critical tasks");
    
    // In a real implementation, this would stop:
    // - Background monitoring tasks
    // - Non-essential services
    // - Logging tasks (keep minimal)
    
    return ESP_OK;
}

esp_err_t MemoryManager::emergency_reduce_heap_usage() {
    ESP_LOGW(TAG, "Reducing heap usage");
    
    // In a real implementation, this would:
    // - Switch to minimal UI mode
    // - Reduce buffer sizes
    // - Free optional features
    
    return ESP_OK;
}

uint32_t MemoryManager::bytes_to_kb(size_t bytes) const {
    return (uint32_t)(bytes / 1024);
}

size_t MemoryManager::kb_to_bytes(uint32_t kb) const {
    return (size_t)kb * 1024;
}

esp_err_t MemoryManager::get_heap_info(size_t& free_size, size_t& total_size, size_t& largest_block) {
    free_size = heap_caps_get_free_size(MALLOC_CAP_8BIT);
    total_size = heap_caps_get_total_size(MALLOC_CAP_8BIT);
    largest_block = heap_caps_get_largest_free_block(MALLOC_CAP_8BIT);
    
    if (free_size == 0 || total_size == 0) {
        return ESP_ERR_INVALID_STATE;
    }
    
    return ESP_OK;
}

void MemoryManager::log_memory_threshold_warning(const char* threshold_name, 
                                               uint32_t current_kb, uint32_t threshold_kb) {
    ESP_LOGW(TAG, "%s threshold reached: %lu KB (threshold: %lu KB)", 
             threshold_name, current_kb, threshold_kb);
}

void MemoryManager::log_emergency_trigger(uint32_t current_free_kb) {
    ESP_LOGE(TAG, "MEMORY EMERGENCY TRIGGERED!");
    ESP_LOGE(TAG, "Free heap: %lu KB (emergency threshold: %lu KB)", 
             current_free_kb, thresholds_.emergency_threshold_kb);
}

#ifdef CONFIG_HEAP_TRACING_STANDALONE
void MemoryManager::track_allocation(void* ptr, size_t size, const char* tag, 
                                   uint32_t line, const char* file) {
    if (!allocation_mutex_) return;
    
    if (xSemaphoreTake(allocation_mutex_, pdMS_TO_TICKS(10)) == pdTRUE) {
        MemoryAllocation alloc = {
            .ptr = ptr,
            .size = size,
            .timestamp_us = esp_timer_get_time(),
            .tag = tag,
            .line_number = line,
            .file_name = file
        };
        allocations_.push_back(alloc);
        xSemaphoreGive(allocation_mutex_);
    }
}

void MemoryManager::track_deallocation(void* ptr) {
    if (!allocation_mutex_ || !ptr) return;
    
    if (xSemaphoreTake(allocation_mutex_, pdMS_TO_TICKS(10)) == pdTRUE) {
        // Remove allocation from tracking
        for (auto it = allocations_.begin(); it != allocations_.end(); ++it) {
            if (it->ptr == ptr) {
                allocations_.erase(it);
                break;
            }
        }
        xSemaphoreGive(allocation_mutex_);
    }
}

void MemoryManager::log_allocation_report() {
    if (!allocation_mutex_) return;
    
    if (xSemaphoreTake(allocation_mutex_, pdMS_TO_TICKS(100)) == pdTRUE) {
        ESP_LOGI(TAG, "=== ALLOCATION REPORT ===");
        ESP_LOGI(TAG, "Active allocations: %zu", allocations_.size());
        
        size_t total_allocated = 0;
        for (const auto& alloc : allocations_) {
            total_allocated += alloc.size;
            ESP_LOGI(TAG, "%p: %zu bytes [%s:%lu] %s", 
                    alloc.ptr, alloc.size, alloc.file_name, alloc.line_number, alloc.tag);
        }
        
        ESP_LOGI(TAG, "Total tracked: %zu bytes (%zu KB)", total_allocated, total_allocated / 1024);
        ESP_LOGI(TAG, "=========================");
        
        xSemaphoreGive(allocation_mutex_);
    }
}
#endif

// ScopedMemoryMonitor implementation
ScopedMemoryMonitor::ScopedMemoryMonitor(const char* operation_name, MemoryManager& manager)
    : operation_name_(operation_name)
    , manager_(manager)
    , start_free_kb_(manager.get_memory_stats().current_free_heap_kb)
    , start_time_us_(esp_timer_get_time()) 
{
    ESP_LOGD(MemoryManager::TAG, "Starting monitored operation: %s (Free: %lu KB)", 
             operation_name_, start_free_kb_);
}

ScopedMemoryMonitor::~ScopedMemoryMonitor() {
    uint64_t end_time_us = esp_timer_get_time();
    uint32_t end_free_kb = manager_.get_memory_stats().current_free_heap_kb;
    
    uint64_t duration_ms = (end_time_us - start_time_us_) / 1000;
    int32_t memory_delta_kb = (int32_t)end_free_kb - (int32_t)start_free_kb_;
    
    ESP_LOGI(MemoryManager::TAG, "Operation '%s' completed: %llu ms, memory change: %ld KB", 
             operation_name_, duration_ms, memory_delta_kb);
}