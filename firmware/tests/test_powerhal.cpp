#include "minigtest.h"
#include "PowerHAL.h"

TEST(PowerHALTest, SetsHighPerformanceProfile) {
    PowerHAL hal;
    hal.set_cpu_frequency(240);
    EXPECT_EQ(PowerProfile::HIGH_PERFORMANCE, hal.get_current_profile());
}

TEST(PowerHALTest, SetsNormalProfile) {
    PowerHAL hal;
    hal.set_cpu_frequency(80);
    EXPECT_EQ(PowerProfile::NORMAL, hal.get_current_profile());
}
