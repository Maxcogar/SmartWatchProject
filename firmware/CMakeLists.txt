# ESP32-S3 ADHD SmartWatch Project
# Professional-grade ESP-IDF project configuration

cmake_minimum_required(VERSION 3.16)

# Project configuration
set(PROJECT_NAME "adhd_smartwatch")
set(PROJECT_VER "1.0.0")
set(IDF_TARGET "esp32s3")

# Include project configuration
include($ENV{IDF_PATH}/tools/cmake/project.cmake)

# Additional CMake options for C++20 support
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Project definition
project(${PROJECT_NAME})

# Add compile definitions for the project
target_compile_definitions(${CMAKE_PROJECT_NAME}.elf PRIVATE
    PROJECT_VERSION=\"${PROJECT_VER}\"
    PROJECT_NAME=\"${PROJECT_NAME}\"
)

# Custom build configurations
if(CONFIG_ADHD_WATCH_DEBUG)
    target_compile_definitions(${CMAKE_PROJECT_NAME}.elf PRIVATE
        ADHD_WATCH_DEBUG=1
        LOG_LOCAL_LEVEL=ESP_LOG_DEBUG
    )
endif()

if(CONFIG_ADHD_WATCH_PRODUCTION)
    target_compile_definitions(${CMAKE_PROJECT_NAME}.elf PRIVATE
        ADHD_WATCH_PRODUCTION=1
        LOG_LOCAL_LEVEL=ESP_LOG_INFO
    )
endif()