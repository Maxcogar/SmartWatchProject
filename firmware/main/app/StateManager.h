#pragma once

enum class SystemState {
    Idle,
    Active
};

class StateManager {
public:
    StateManager();
    void setState(SystemState state);
    SystemState getState() const;
private:
    SystemState state_;
};
