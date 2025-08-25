cmake_minimum_required(VERSION 3.14)
project(FirmwareTests)

add_executable(firmware_tests
  PowerHAL.cpp
  StateManager.cpp
  test_powerhal.cpp
  test_statemanager.cpp
  test_main.cpp
)
