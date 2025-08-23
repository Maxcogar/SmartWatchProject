# ESP32-S3 ADHD Smartwatch - Coding Standards

## Overview

This document establishes comprehensive coding standards for the ESP32-S3 ADHD-Friendly Smartwatch project. These standards ensure code quality, maintainability, and alignment with the project's high-performance requirements (NFR1-NFR8) and layered architecture (HAL, Services, Application, UI).

## 1. File Naming Conventions

### Source Files
- **C++ Implementation Files:** `PascalCase.cpp`
  - Examples: `TaskManager.cpp`, `FocusTimer.cpp`, `BluetoothService.cpp`
- **C++ Header Files:** `PascalCase.hpp` 
  - Examples: `TaskManager.hpp`, `FocusTimer.hpp`, `BluetoothService.hpp`
- **C Files (ESP-IDF integration only):** `snake_case.c`
  - Examples: `hardware_init.c`, `nvs_config.c`
- **C Headers (ESP-IDF integration only):** `snake_case.h`
  - Examples: `hardware_init.h`, `nvs_config.h`

### Directory Structure
```
src/
├── hal/           # Hardware Abstraction Layer
├── services/      # Core Services Layer  
├── app/          # Application Logic Layer
└── ui/           # User Interface Layer
```

### Configuration Files
- **Component Config:** `component_config.hpp`
- **Build Config:** `build_config.hpp`
- **Hardware Config:** `hardware_config.hpp`

## 2. Code Style & Formatting

### Brace Style - Allman Style (Required)
```cpp
class TaskManager
{
public:
    void startTask(const Task& task)
    {
        if (task.isValid())
        {
            currentTask = task;
            notifyObservers();
        }
        else
        {
            ESP_LOGE(TAG, "Invalid task provided");
        }
    }
};
```

### Indentation
- **4 spaces** (no tabs)
- **Continuation lines:** 8 spaces or align with opening parenthesis

### Line Length
- **Maximum 120 characters per line**
- Break long lines at logical points (operators, commas, etc.)

### Naming Conventions

#### Classes & Structures
```cpp
class TaskManager {};           // PascalCase
struct TaskData {};            // PascalCase  
enum class TaskState {};       // PascalCase
```

#### Functions & Methods
```cpp
void startFocusTimer();        // camelCase
bool isTaskActive() const;     // camelCase
void processNotification();    // camelCase
```

#### Variables
```cpp
// Local variables - camelCase
int currentTaskId = 0;
bool isTimerActive = false;
TaskState focusState = TaskState::IDLE;

// Member variables - camelCase with m_ prefix
class TaskManager
{
private:
    int m_activeTaskId;
    bool m_isRunning;
    std::vector<Task> m_taskQueue;
};

// Constants - SCREAMING_SNAKE_CASE
static constexpr int MAX_TASK_COUNT = 50;
static constexpr uint32_t TIMER_INTERVAL_MS = 1000;
```

#### Preprocessor Macros
```cpp
#define WATCH_VERSION_MAJOR 1
#define TASK_QUEUE_SIZE 32
#define LOG_LEVEL_DEBUG 1
```

## 3. Core Patterns

### Error Handling Pattern (Mandatory)
```cpp
// Use ESP32 error codes consistently
esp_err_t TaskManager::addTask(const Task& task)
{
    if (!task.isValid())
    {
        ESP_LOGE(TAG, "Invalid task data provided");
        return ESP_ERR_INVALID_ARG;
    }
    
    if (m_taskQueue.size() >= MAX_TASK_COUNT)
    {
        ESP_LOGW(TAG, "Task queue full, cannot add task");
        return ESP_ERR_NO_MEM;
    }
    
    try
    {
        m_taskQueue.push_back(task);
        ESP_LOGI(TAG, "Task added successfully: %s", task.getTitle().c_str());
        return ESP_OK;
    }
    catch (const std::exception& e)
    {
        ESP_LOGE(TAG, "Failed to add task: %s", e.what());
        return ESP_FAIL;
    }
}
```

### Logging Pattern (Mandatory)
```cpp
// Define TAG at top of each source file
static const char* TAG = "TaskManager";

// Use appropriate log levels
ESP_LOGE(TAG, "Critical error: %s", errorMessage);     // Errors
ESP_LOGW(TAG, "Warning: %s", warningMessage);          // Warnings  
ESP_LOGI(TAG, "Info: %s", infoMessage);                // Important info
ESP_LOGD(TAG, "Debug: %s", debugMessage);              // Debug info
ESP_LOGV(TAG, "Verbose: %s", verboseMessage);          // Verbose debug
```

### FreeRTOS Task Pattern (Mandatory)
```cpp
class ServiceBase
{
protected:
    TaskHandle_t m_taskHandle = nullptr;
    QueueHandle_t m_messageQueue = nullptr;
    static constexpr int QUEUE_SIZE = 10;
    static constexpr int STACK_SIZE = 4096;
    static constexpr int TASK_PRIORITY = 5;
    
public:
    esp_err_t start()
    {
        m_messageQueue = xQueueCreate(QUEUE_SIZE, sizeof(Message));
        if (m_messageQueue == nullptr)
        {
            ESP_LOGE(TAG, "Failed to create message queue");
            return ESP_ERR_NO_MEM;
        }
        
        BaseType_t result = xTaskCreate(
            taskEntry,
            "ServiceTask",
            STACK_SIZE,
            this,
            TASK_PRIORITY,
            &m_taskHandle
        );
        
        if (result != pdPASS)
        {
            ESP_LOGE(TAG, "Failed to create task");
            vQueueDelete(m_messageQueue);
            return ESP_ERR_NO_MEM;
        }
        
        return ESP_OK;
    }
    
private:
    static void taskEntry(void* parameter)
    {
        static_cast<ServiceBase*>(parameter)->taskLoop();
    }
    
    virtual void taskLoop() = 0;
};
```

### Resource Management Pattern (RAII)
```cpp
class DisplayLock
{
private:
    SemaphoreHandle_t m_mutex;
    bool m_acquired;
    
public:
    explicit DisplayLock(SemaphoreHandle_t mutex, TickType_t timeout = portMAX_DELAY)
        : m_mutex(mutex), m_acquired(false)
    {
        if (xSemaphoreTake(m_mutex, timeout) == pdTRUE)
        {
            m_acquired = true;
        }
        else
        {
            ESP_LOGW(TAG, "Failed to acquire display lock");
        }
    }
    
    ~DisplayLock()
    {
        if (m_acquired)
        {
            xSemaphoreGive(m_mutex);
        }
    }
    
    bool isAcquired() const { return m_acquired; }
};

// Usage:
void updateDisplay()
{
    DisplayLock lock(displayMutex);
    if (lock.isAcquired())
    {
        // Perform display operations
        ESP_LOGI(TAG, "Display updated");
    }
}
```

## 4. Header Guard Conventions

### Standard Include Guards
```cpp
// File: TaskManager.hpp
#ifndef SMARTWATCH_TASK_MANAGER_HPP
#define SMARTWATCH_TASK_MANAGER_HPP

// Header content here...

#endif // SMARTWATCH_TASK_MANAGER_HPP
```

### Pattern: `SMARTWATCH_[NAMESPACE_]FILENAME_HPP`
- **Service Layer:** `SMARTWATCH_SERVICES_BLUETOOTH_SERVICE_HPP`
- **HAL Layer:** `SMARTWATCH_HAL_DISPLAY_DRIVER_HPP`  
- **UI Layer:** `SMARTWATCH_UI_TASK_SCREEN_HPP`
- **App Layer:** `SMARTWATCH_APP_TASK_MANAGER_HPP`

### Include Order (Mandatory)
```cpp
// 1. Standard C++ headers
#include <vector>
#include <string>
#include <memory>

// 2. ESP-IDF headers
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

// 3. Third-party headers (esp-brookesia, etc.)
#include "esp_brookesia.hpp"

// 4. Project headers (same layer)
#include "TaskData.hpp"

// 5. Project headers (other layers)
#include "hal/DisplayDriver.hpp"
#include "services/BluetoothService.hpp"
```

## 5. Critical Rules for AI Development

### 🚨 NEVER Violate These Rules

1. **NEVER use `printf` for logging; ALWAYS use `ESP_LOGX` macros**
   ```cpp
   // ❌ WRONG
   printf("Task started\n");
   
   // ✅ CORRECT
   ESP_LOGI(TAG, "Task started");
   ```

2. **NEVER use raw pointers for dynamic memory; ALWAYS use RAII or ESP-IDF memory management**
   ```cpp
   // ❌ WRONG
   char* buffer = (char*)malloc(256);
   
   // ✅ CORRECT
   std::unique_ptr<char[]> buffer = std::make_unique<char[]>(256);
   // OR for ESP-IDF specific:
   char* buffer = (char*)heap_caps_malloc(256, MALLOC_CAP_DMA);
   ```

3. **NEVER block the main UI thread; ALWAYS use proper task management**
   ```cpp
   // ❌ WRONG - blocking delay in UI thread
   vTaskDelay(pdMS_TO_TICKS(5000));
   
   // ✅ CORRECT - use timers or separate tasks
   esp_timer_start_once(timer_handle, 5000000); // 5 seconds in microseconds
   ```

4. **NEVER access shared resources without synchronization**
   ```cpp
   // ❌ WRONG
   sharedData = newValue;
   
   // ✅ CORRECT
   xSemaphoreTake(dataMutex, portMAX_DELAY);
   sharedData = newValue;
   xSemaphoreGive(dataMutex);
   ```

5. **NEVER ignore return values from ESP-IDF functions**
   ```cpp
   // ❌ WRONG
   esp_wifi_init(&cfg);
   
   // ✅ CORRECT
   esp_err_t ret = esp_wifi_init(&cfg);
   if (ret != ESP_OK)
   {
       ESP_LOGE(TAG, "WiFi init failed: %s", esp_err_to_name(ret));
       return ret;
   }
   ```

6. **NEVER hardcode timing values; ALWAYS use named constants**
   ```cpp
   // ❌ WRONG
   vTaskDelay(pdMS_TO_TICKS(250));
   
   // ✅ CORRECT
   static constexpr int UI_RESPONSE_TIMEOUT_MS = 250; // NFR1 requirement
   vTaskDelay(pdMS_TO_TICKS(UI_RESPONSE_TIMEOUT_MS));
   ```

7. **NEVER use exceptions in interrupt handlers or FreeRTOS tasks**
   ```cpp
   // ❌ WRONG in ISR context
   void IRAM_ATTR gpio_isr_handler(void* arg)
   {
       throw std::runtime_error("Error"); // NEVER!
   }
   
   // ✅ CORRECT
   void IRAM_ATTR gpio_isr_handler(void* arg)
   {
       BaseType_t xHigherPriorityTaskWoken = pdFALSE;
       xQueueSendFromISR(eventQueue, &event, &xHigherPriorityTaskWoken);
       portYIELD_FROM_ISR(xHigherPriorityTaskWoken);
   }
   ```

8. **ALWAYS validate input parameters at public API boundaries**
   ```cpp
   esp_err_t TaskManager::setActiveTask(const Task* task)
   {
       if (task == nullptr)
       {
           ESP_LOGE(TAG, "Task pointer is null");
           return ESP_ERR_INVALID_ARG;
       }
       
       if (!task->isValid())
       {
           ESP_LOGE(TAG, "Task data is invalid");
           return ESP_ERR_INVALID_ARG;
       }
       
       // Proceed with implementation...
   }
   ```

9. **ALWAYS use const correctness**
   ```cpp
   class TaskManager
   {
   public:
       const Task& getCurrentTask() const { return m_currentTask; }
       bool isActive() const { return m_isActive; }
       
   private:
       void processTask(const Task& task);  // const reference for read-only
   };
   ```

10. **NEVER store secrets in source code; ALWAYS use NVS or secure storage**
    ```cpp
    // ❌ WRONG
    const char* wifi_password = "MyPassword123";
    
    // ✅ CORRECT
    esp_err_t getWifiPassword(char* buffer, size_t buffer_size)
    {
        nvs_handle_t nvs_handle;
        esp_err_t ret = nvs_open("wifi_config", NVS_READONLY, &nvs_handle);
        if (ret == ESP_OK)
        {
            ret = nvs_get_str(nvs_handle, "password", buffer, &buffer_size);
            nvs_close(nvs_handle);
        }
        return ret;
    }
    ```

## 6. Performance Guidelines

### Memory Management
- **Prefer stack allocation** for small, short-lived objects
- **Use heap_caps_malloc()** for DMA-capable memory when needed
- **Monitor heap fragmentation** in long-running applications
- **Use memory pools** for frequently allocated/deallocated objects

### Task Priorities (Aligned with NFR1 - 250ms UI response)
```cpp
// Priority levels (higher number = higher priority)
static constexpr int PRIORITY_CRITICAL = 10;   // Priority alerts (FR9)
static constexpr int PRIORITY_UI = 8;          // UI responsiveness (NFR1)  
static constexpr int PRIORITY_SERVICES = 6;    // Core services
static constexpr int PRIORITY_BACKGROUND = 4;  // Background tasks
static constexpr int PRIORITY_LOW = 2;         // Housekeeping
```

### Watchdog Compliance
```cpp
// Feed watchdog in long-running operations
void longRunningOperation()
{
    for (int i = 0; i < largeCount; ++i)
    {
        // Process item
        processItem(i);
        
        // Feed watchdog every 100 iterations
        if (i % 100 == 0)
        {
            esp_task_wdt_reset();
        }
    }
}
```

## 7. Code Documentation Standards

### Class Documentation
```cpp
/**
 * @brief Manages focus timer functionality for ADHD-friendly task execution
 * 
 * This class handles the 25-minute focus timer sessions as specified in NFR3.
 * It integrates with the display power management to enable always-on mode
 * during active focus sessions.
 * 
 * @note Thread-safe for multi-task access
 * @see TaskManager for task integration
 */
class FocusTimer
{
    // Implementation...
};
```

### Function Documentation
```cpp
/**
 * @brief Starts a focus timer session for the specified task
 * 
 * @param task Reference to the task to focus on
 * @param durationMinutes Duration in minutes (default: 25)
 * @return ESP_OK on success, error code otherwise
 * 
 * @note Triggers always-on display mode per NFR8
 * @warning Must be called from main application task only
 */
esp_err_t startFocusSession(const Task& task, uint32_t durationMinutes = 25);
```

## 8. Build System Integration

### CMakeLists.txt Standards
```cmake
# Component registration
idf_component_register(
    SRCS 
        "TaskManager.cpp"
        "FocusTimer.cpp"
        "BluetoothService.cpp"
    INCLUDE_DIRS 
        "include"
    REQUIRES 
        "esp_brookesia"
        "nvs_flash"
        "bt"
)

# Compiler flags for this project
target_compile_options(${COMPONENT_LIB} PRIVATE
    -Wall
    -Wextra
    -Werror
    -std=c++17
)
```

---

## Enforcement

This document is **mandatory** for all code contributions. Code reviews must verify compliance with these standards. Automated tooling (clang-format, static analysis) should enforce these rules where possible.

**Version:** 1.0  
**Last Updated:** 2024-12-19  
**Applies To:** All C++ code in the smartwatch project