#include "PowerHAL.h"

void PowerHAL::set_cpu_frequency(uint32_t freq_mhz) {
    freq_mhz_ = freq_mhz;
    profile_ = (freq_mhz_ > 160) ? PowerProfile::HIGH_PERFORMANCE : PowerProfile::NORMAL;
}

PowerProfile PowerHAL::get_current_profile() const {
    return profile_;
}
