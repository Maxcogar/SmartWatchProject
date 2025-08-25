# Main component for ESP32-S3 ADHD SmartWatch
# Defines the main application component with all source files

# Register main component
idf_component_register(
    SRCS
        # Main application entry point
        "main.cpp"

        # Boot sequence components (Story 1.1)
        "boot/BootManager.cpp"
        "boot/MemoryManager.cpp"
        "boot/LEDStatusSystem.cpp"

        # Hardware Abstraction Layer (HAL)
        "hal/DisplayHAL.cpp"
        "hal/TouchHAL.cpp"
        "hal/PowerHAL.cpp"

        # Services Layer
        "services/BluetoothService.cpp"
        "services/WiFiService.cpp"
        "services/NvsService.cpp"

        # Application Logic Layer
        "app/StateManager.cpp"

        # UI Layer
        "ui/UIManager.cpp"

        # Common utilities
        "common/Logger.cpp"
        "common/Utils.cpp"
        "common/Config.cpp"

    INCLUDE_DIRS
        "."
        "boot"
        "hal"
        "services"
        "app"
        "ui"
        "common"

    REQUIRES
        # ESP-IDF components
        esp_wifi
        esp_timer
        nvs_flash
        bt
        esp_bt_stack
        esp_adc
        esp_lcd
        spi_flash
        fatfs

        # Third-party components
        lvgl
        esp_lcd_touch_cst816s
        esp_brookesia
)
