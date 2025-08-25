#pragma once

class PowerHAL {
public:
    PowerHAL();
    int init();
    bool isInitialized() const;
    void setLowPowerMode(bool enable);
    bool isLowPowerMode() const;
private:
    bool initialized_;
    bool low_power_mode_;
};
