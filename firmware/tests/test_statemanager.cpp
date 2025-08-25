#include "minigtest.h"
#include "StateManager.h"

TEST(StateManagerTest, StartsAndEndsFocusSession) {
    StateManager mgr;
    mgr.start_focus_session("task1");
    EXPECT_EQ(AppState::FOCUS, mgr.get_current_state());
    EXPECT_EQ(std::string("task1"), mgr.current_task());

    mgr.end_focus_session();
    EXPECT_EQ(AppState::IDLE, mgr.get_current_state());
    EXPECT_EQ(std::string(""), mgr.current_task());
}
