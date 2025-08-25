#include "minitest.h"
#include "hal/PowerHAL.h"

TEST(PowerHALInitializesAndSetsLowPower) {
    PowerHAL hal;
    EXPECT_FALSE(hal.isInitialized());
    EXPECT_EQ(0, hal.init());
    EXPECT_TRUE(hal.isInitialized());
    EXPECT_FALSE(hal.isLowPowerMode());
    hal.setLowPowerMode(true);
    EXPECT_TRUE(hal.isLowPowerMode());
}
