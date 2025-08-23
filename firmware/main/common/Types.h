/**
 * @file Types.h
 * @brief Common data types and structures for ESP32-S3 ADHD SmartWatch
 * 
 * This file defines all the common data types, enumerations, and structures
 * used throughout the smartwatch application, following the architecture
 * specification data models.
 * 
 * @version 1.0.0
 * @date 2025-08-19
 * @author ESP32-S3 Development Team
 */

#pragma once

#include <string>
#include <vector>
#include <queue>
#include <memory>
#include <functional>
#include "esp_err.h"

// Forward declarations
struct task_t;
struct notification_t;
struct app_state_t;
struct focus_session_t;

// Basic Types and Enumerations

/**
 * @brief Priority levels for tasks and notifications
 */
typedef enum {
    PRIORITY_LOW = 0,
    PRIORITY_MEDIUM = 1,
    PRIORITY_HIGH = 2,
    PRIORITY_URGENT = 3
} priority_level_t;

/**
 * @brief Notification types supported by the system
 */
typedef enum {
    NOTIFICATION_TASK_REMINDER = 0,
    NOTIFICATION_MEETING = 1,
    NOTIFICATION_MESSAGE = 2,
    NOTIFICATION_SYSTEM = 3,
    NOTIFICATION_FOCUS_START = 4,
    NOTIFICATION_FOCUS_END = 5,
    NOTIFICATION_BREAK_START = 6,
    NOTIFICATION_BREAK_END = 7
} notification_type_t;

/**
 * @brief Display and power states
 */
typedef enum {
    DISPLAY_STATE_ON = 0,
    DISPLAY_STATE_DIMMED = 1,
    DISPLAY_STATE_OFF = 2,
    DISPLAY_STATE_SLEEP = 3
} display_state_t;

/**
 * @brief Battery status information
 */
typedef struct {
    uint8_t level_percent;      ///< Battery level 0-100%
    float voltage;              ///< Battery voltage in volts
    bool is_charging;           ///< True if currently charging
    bool is_low;                ///< True if below low threshold
    bool is_critical;           ///< True if below critical threshold
} battery_status_t;

/**
 * @brief Power management profiles
 */
typedef enum {
    POWER_PROFILE_PERFORMANCE = 0,  ///< High performance, high power consumption
    POWER_PROFILE_BALANCED = 1,     ///< Balanced performance and power
    POWER_PROFILE_POWER_SAVE = 2,   ///< Low power consumption, reduced performance
    POWER_PROFILE_SLEEP = 3         ///< Sleep mode, minimal power consumption
} power_profile_t;

// Touch and Input Types

/**
 * @brief Touch point coordinates
 */
typedef struct {
    uint16_t x;                 ///< X coordinate
    uint16_t y;                 ///< Y coordinate
    bool pressed;               ///< True if touch is pressed
    uint32_t timestamp;         ///< Touch timestamp in milliseconds
} touch_point_t;

/**
 * @brief Touch event information
 */
typedef struct {
    uint16_t x;                 ///< X coordinate
    uint16_t y;                 ///< Y coordinate
    bool pressed;               ///< True if pressed, false if released
    uint32_t duration;          ///< Touch duration in milliseconds
} touch_event_t;

/**
 * @brief Touch callback function type
 */
typedef std::function<void(touch_point_t)> touch_callback_t;

// Task Management Types

/**
 * @brief Task structure as defined in architecture specification
 */
typedef struct task_t {
    std::string id;             ///< Unique task identifier
    std::string title;          ///< Task title/description
    bool is_complete;           ///< Completion status
    priority_level_t priority;  ///< Task priority level
    uint64_t due_date_unix;     ///< Due date in Unix timestamp
    uint16_t estimated_minutes; ///< Estimated completion time in minutes
    
    task_t() : is_complete(false), priority(PRIORITY_MEDIUM), 
               due_date_unix(0), estimated_minutes(0) {}
} task_t;

/**
 * @brief List of tasks
 */
typedef std::vector<task_t> task_list_t;

// Notification Types

/**
 * @brief Notification structure as defined in architecture specification
 */
typedef struct notification_t {
    std::string id;             ///< Unique notification identifier
    notification_type_t type;   ///< Type of notification
    std::string sender;         ///< Sender/source of notification
    std::string body;           ///< Notification content
    uint64_t timestamp_unix;    ///< Timestamp in Unix format
    priority_level_t priority;  ///< Notification priority
    bool action_required;       ///< True if user action is required
    bool is_read;              ///< True if notification has been read
    
    notification_t() : type(NOTIFICATION_SYSTEM), timestamp_unix(0),
                      priority(PRIORITY_MEDIUM), action_required(false), is_read(false) {}
} notification_t;

/**
 * @brief Queue of notifications
 */
typedef std::queue<notification_t> notification_queue_t;

// Focus Session Types

/**
 * @brief Focus session structure as defined in architecture specification
 */
typedef struct focus_session_t {
    bool is_active;             ///< True if focus session is currently active
    std::string task_id;        ///< ID of associated task
    uint64_t start_time_unix;   ///< Session start time in Unix timestamp
    uint16_t duration_minutes;  ///< Planned session duration in minutes
    uint16_t remaining_minutes; ///< Remaining session time in minutes
    uint32_t session_count;     ///< Number of completed sessions today
    bool is_break;              ///< True if this is a break session
    
    focus_session_t() : is_active(false), start_time_unix(0), 
                       duration_minutes(0), remaining_minutes(0),
                       session_count(0), is_break(false) {}
} focus_session_t;

// Application State Types

/**
 * @brief Complete application state structure
 */
typedef struct app_state_t {
    std::string current_task_id;        ///< Currently active task ID
    notification_queue_t notification_queue; ///< Queue of pending notifications
    focus_session_t focus_session;      ///< Current focus session state
    uint64_t last_sync_timestamp;       ///< Last BLE sync timestamp
    battery_status_t battery_status;    ///< Current battery status
    display_state_t display_state;      ///< Current display state
    power_profile_t power_profile;      ///< Current power profile
    
    app_state_t() : last_sync_timestamp(0), 
                   display_state(DISPLAY_STATE_ON),
                   power_profile(POWER_PROFILE_BALANCED) {}
} app_state_t;

// BLE Communication Types

/**
 * @brief BLE event types
 */
typedef enum {
    BLE_EVENT_CONNECTED = 0,
    BLE_EVENT_DISCONNECTED = 1,
    BLE_EVENT_DATA_RECEIVED = 2,
    BLE_EVENT_PAIRING_REQUEST = 3,
    BLE_EVENT_PAIRING_COMPLETE = 4,
    BLE_EVENT_ERROR = 5
} ble_event_type_t;

/**
 * @brief BLE event structure
 */
typedef struct {
    ble_event_type_t type;      ///< Event type
    uint16_t conn_id;           ///< Connection ID
    void* data;                 ///< Event-specific data
    size_t data_len;            ///< Data length
} ble_event_t;

/**
 * @brief BLE characteristic configuration
 */
typedef struct {
    const char* uuid;           ///< Characteristic UUID
    uint16_t properties;        ///< Characteristic properties
    uint16_t permissions;       ///< Access permissions
    uint16_t max_len;          ///< Maximum data length
} ble_char_config_t;

/**
 * @brief BLE connection status
 */
typedef enum {
    BLE_DISCONNECTED = 0,
    BLE_CONNECTING = 1,
    BLE_CONNECTED = 2,
    BLE_PAIRING = 3,
    BLE_PAIRED = 4
} connection_status_t;

/**
 * @brief BLE event callback function type
 */
typedef std::function<void(ble_event_t, void*)> ble_event_callback_t;

// WiFi Types

/**
 * @brief WiFi event types
 */
typedef enum {
    WIFI_EVENT_CONNECTED = 0,
    WIFI_EVENT_DISCONNECTED = 1,
    WIFI_EVENT_IP_OBTAINED = 2,
    WIFI_EVENT_CONNECTION_FAILED = 3,
    WIFI_EVENT_PROVISIONING_STARTED = 4,
    WIFI_EVENT_PROVISIONING_COMPLETE = 5
} wifi_event_type_t;

/**
 * @brief WiFi event structure
 */
typedef struct {
    wifi_event_type_t type;     ///< Event type
    void* data;                 ///< Event-specific data
    size_t data_len;            ///< Data length
} wifi_event_t;

/**
 * @brief WiFi connection status
 */
typedef enum {
    WIFI_DISCONNECTED = 0,
    WIFI_CONNECTING = 1,
    WIFI_CONNECTED = 2,
    WIFI_IP_OBTAINED = 3,
    WIFI_CONNECTION_FAILED = 4
} wifi_status_t;

/**
 * @brief WiFi event callback function type
 */
typedef std::function<void(wifi_event_t, void*)> wifi_event_callback_t;

/**
 * @brief HTTP request structure
 */
typedef struct {
    std::string url;            ///< Request URL
    std::string method;         ///< HTTP method (GET, POST, etc.)
    std::string headers;        ///< Request headers
    std::string body;           ///< Request body
    uint32_t timeout_ms;        ///< Request timeout in milliseconds
} http_request_t;

/**
 * @brief HTTP response structure
 */
typedef struct {
    int status_code;            ///< HTTP status code
    std::string headers;        ///< Response headers
    std::string body;           ///< Response body
    size_t content_length;      ///< Content length
} http_response_t;

// UI Types

/**
 * @brief Screen types available in the UI
 */
typedef enum {
    SCREEN_HOME = 0,
    SCREEN_TASKS = 1,
    SCREEN_FOCUS = 2,
    SCREEN_NOTIFICATIONS = 3,
    SCREEN_SETTINGS = 4,
    SCREEN_ABOUT = 5,
    SCREEN_SPLASH = 6
} screen_type_t;

/**
 * @brief UI event types
 */
typedef enum {
    UI_EVENT_BUTTON_PRESS = 0,
    UI_EVENT_SCREEN_CHANGE = 1,
    UI_EVENT_TASK_SELECT = 2,
    UI_EVENT_FOCUS_START = 3,
    UI_EVENT_FOCUS_STOP = 4,
    UI_EVENT_NOTIFICATION_DISMISS = 5,
    UI_EVENT_SETTINGS_CHANGE = 6
} ui_event_type_t;

/**
 * @brief UI event structure
 */
typedef struct {
    ui_event_type_t type;       ///< Event type
    screen_type_t screen;       ///< Source screen
    void* data;                 ///< Event-specific data
    size_t data_len;            ///< Data length
} ui_event_t;

/**
 * @brief Screen data for UI updates
 */
typedef struct {
    screen_type_t screen_type;  ///< Target screen type
    void* data;                 ///< Screen-specific data
    size_t data_len;            ///< Data length
} screen_data_t;

/**
 * @brief UI event callback function type
 */
typedef std::function<void(ui_event_t, void*)> ui_event_callback_t;

// Display Types

/**
 * @brief Display information structure
 */
typedef struct {
    uint16_t width;             ///< Display width in pixels
    uint16_t height;            ///< Display height in pixels
    uint8_t bit_depth;          ///< Color depth in bits per pixel
    uint32_t buffer_size;       ///< Frame buffer size in bytes
    bool backlight_enabled;     ///< Backlight status
    uint8_t brightness;         ///< Current brightness level (0-100)
} display_info_t;

// System Callback Types

/**
 * @brief State change callback structure
 */
typedef struct {
    std::function<void(const task_list_t&)> on_task_update;
    std::function<void(const notification_t&)> on_notification;
    std::function<void(const app_state_t&)> on_state_change;
    std::function<void(const battery_status_t&)> on_battery_change;
} state_callbacks_t;

// Error and Status Types

/**
 * @brief System health information
 */
typedef struct {
    uint8_t battery_level;      ///< Battery level percentage
    int8_t ble_rssi;           ///< BLE signal strength in dBm
    uint32_t free_heap;         ///< Free heap memory in bytes
    uint32_t uptime_seconds;    ///< System uptime in seconds
    uint32_t reset_count;       ///< Number of resets since flash
    esp_reset_reason_t last_reset_reason; ///< Last reset reason
} system_health_t;

/**
 * @brief Component initialization status
 */
typedef enum {
    COMPONENT_UNINITIALIZED = 0,
    COMPONENT_INITIALIZING = 1,
    COMPONENT_INITIALIZED = 2,
    COMPONENT_ERROR = 3
} component_status_t;

// Validation and Utility Functions

/**
 * @brief Validate task structure
 */
inline bool is_valid_task(const task_t& task) {
    return !task.id.empty() && 
           !task.title.empty() && 
           task.estimated_minutes > 0 &&
           task.estimated_minutes <= 480; // Max 8 hours
}

/**
 * @brief Validate notification structure
 */
inline bool is_valid_notification(const notification_t& notification) {
    return !notification.id.empty() &&
           !notification.body.empty() &&
           notification.body.length() <= 200 && // Max notification length
           notification.timestamp_unix > 0;
}

/**
 * @brief Get priority string representation
 */
inline const char* priority_to_string(priority_level_t priority) {
    switch (priority) {
        case PRIORITY_LOW: return "Low";
        case PRIORITY_MEDIUM: return "Medium";
        case PRIORITY_HIGH: return "High";
        case PRIORITY_URGENT: return "Urgent";
        default: return "Unknown";
    }
}

/**
 * @brief Get notification type string representation
 */
inline const char* notification_type_to_string(notification_type_t type) {
    switch (type) {
        case NOTIFICATION_TASK_REMINDER: return "Task Reminder";
        case NOTIFICATION_MEETING: return "Meeting";
        case NOTIFICATION_MESSAGE: return "Message";
        case NOTIFICATION_SYSTEM: return "System";
        case NOTIFICATION_FOCUS_START: return "Focus Start";
        case NOTIFICATION_FOCUS_END: return "Focus End";
        case NOTIFICATION_BREAK_START: return "Break Start";
        case NOTIFICATION_BREAK_END: return "Break End";
        default: return "Unknown";
    }
}

/**
 * @brief Convert battery level to status string
 */
inline const char* battery_status_to_string(uint8_t level) {
    if (level > 80) return "Excellent";
    else if (level > 60) return "Good";
    else if (level > 40) return "Fair";
    else if (level > 20) return "Low";
    else return "Critical";
}