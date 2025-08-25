#include "minitest.h"
#include "app/StateManager.h"

TEST(StateManagerStateTransitions) {
    StateManager manager;
    EXPECT_EQ(SystemState::Idle, manager.getState());
    manager.setState(SystemState::Active);
    EXPECT_EQ(SystemState::Active, manager.getState());
}
