#pragma once
#include <string>

enum class AppState {
    IDLE,
    FOCUS
};

class StateManager {
public:
    StateManager() : state_(AppState::IDLE) {}
    void start_focus_session(const std::string& task_id);
    void end_focus_session();
    AppState get_current_state() const;
    std::string current_task() const;
private:
    AppState state_;
    std::string task_id_;
};
