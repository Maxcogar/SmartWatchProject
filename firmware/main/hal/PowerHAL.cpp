#include "PowerHAL.h"

PowerHAL::PowerHAL() : initialized_(false), low_power_mode_(false) {}

int PowerHAL::init() {
    initialized_ = true;
    return 0; // success
}

bool PowerHAL::isInitialized() const {
    return initialized_;
}

void PowerHAL::setLowPowerMode(bool enable) {
    low_power_mode_ = enable;
}

bool PowerHAL::isLowPowerMode() const {
    return low_power_mode_;
}
