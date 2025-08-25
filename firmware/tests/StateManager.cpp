#include "StateManager.h"

void StateManager::start_focus_session(const std::string& task_id) {
    state_ = AppState::FOCUS;
    task_id_ = task_id;
}

void StateManager::end_focus_session() {
    state_ = AppState::IDLE;
    task_id_.clear();
}

AppState StateManager::get_current_state() const {
    return state_;
}

std::string StateManager::current_task() const {
    return task_id_;
}
