#pragma once
#include <cstdint>

enum class PowerProfile {
    NORMAL,
    HIGH_PERFORMANCE
};

class PowerHAL {
public:
    PowerHAL() : freq_mhz_(160), profile_(PowerProfile::NORMAL) {}
    void set_cpu_frequency(uint32_t freq_mhz);
    PowerProfile get_current_profile() const;
private:
    uint32_t freq_mhz_;
    PowerProfile profile_;
};
