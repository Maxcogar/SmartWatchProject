#include "StateManager.h"

StateManager::StateManager() : state_(SystemState::Idle) {}

void StateManager::setState(SystemState state) {
    state_ = state;
}

SystemState StateManager::getState() const {
    return state_;
}
