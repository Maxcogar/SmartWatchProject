cmake_minimum_required(VERSION 3.16)
project(FirmwareTests)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

enable_testing()

add_executable(run_tests
    tests_main.cpp
    test_power_hal.cpp
    test_state_manager.cpp
    ../main/hal/PowerHAL.cpp
    ../main/app/StateManager.cpp
)

target_include_directories(run_tests PRIVATE ../main)

add_test(NAME firmware_unit_tests COMMAND run_tests)
