# Epic 2: Task Management & The Focus Shield - User Stories

## Story 2.1: Bluetooth Connectivity & Handshake

**As a** user  
**I want** my smartwatch to connect reliably to my phone via Bluetooth  
**So that** I can sync my tasks and receive notifications seamlessly

### Acceptance Criteria
- [ ] **AC2.1.1:** Watch discovers and pairs with companion phone app via BLE
- [ ] **AC2.1.2:** Connection establishment completes within 30 seconds
- [ ] **AC2.1.3:** Basic message exchange (ping/pong) works bidirectionally
- [ ] **AC2.1.4:** Connection status is clearly indicated on home screen
- [ ] **AC2.1.5:** Connection survives phone sleep/wake cycles
- [ ] **AC2.1.6:** Automatic reconnection attempts after connection loss
- [ ] **AC2.1.7:** Connection remains stable for minimum 4 hours
- [ ] **AC2.1.8:** Pairing process is user-friendly and documented

### Definition of Done
- [ ] BLE stack implemented and tested
- [ ] Pairing UI flow created
- [ ] Connection stability validated over 8+ hours
- [ ] Error handling for connection failures
- [ ] User feedback for connection states
- [ ] Documentation for pairing process

### Story Points: 8
**Estimation Notes:** Medium-high complexity due to BLE protocol implementation and stability requirements

### Technical Requirements
- **Protocol:** Bluetooth Low Energy (BLE) 4.0+
- **Range:** Minimum 10 meters line-of-sight
- **Power Consumption:** Optimized for battery life (NFR3)
- **Data Rate:** Sufficient for task list sync
- **Security:** Encrypted connection for data protection

### Technical Notes
- Use ESP32-S3 built-in BLE capabilities
- Implement GATT server/client architecture
- Consider custom service UUID for task sync
- Implement connection state machine
- Add reconnection backoff algorithm

---

## Story 2.2: Task Synchronization and Display

**As a** user  
**I want** to see my Microsoft ToDo tasks on my smartwatch  
**So that** I can choose which task to focus on without checking my phone

### Acceptance Criteria
- [ ] **AC2.2.1:** Watch can request task list from companion phone app
- [ ] **AC2.2.2:** Task list displays in scrollable format with clear typography
- [ ] **AC2.2.3:** Maximum 20 tasks displayed (performance consideration)
- [ ] **AC2.2.4:** Task titles are truncated appropriately for screen size
- [ ] **AC2.2.5:** Tasks show priority indicators if available
- [ ] **AC2.2.6:** Sync occurs automatically on connection establishment
- [ ] **AC2.2.7:** Manual refresh option available via pull-to-refresh gesture
- [ ] **AC2.2.8:** Empty state handled gracefully with helpful message

### Definition of Done
- [ ] Task list UI component implemented
- [ ] BLE communication protocol for task sync
- [ ] Scrolling performance optimized
- [ ] Text truncation handles various task lengths
- [ ] Sync error handling implemented
- [ ] Empty and loading states designed

### Story Points: 13
**Estimation Notes:** High complexity due to data synchronization, UI performance, and Microsoft ToDo integration

### UI Specifications
- **List Item Height:** Minimum 60px for touch accessibility
- **Font Size:** Large enough for readability (16px minimum)
- **Scrolling:** Smooth scrolling performance
- **Visual Hierarchy:** Clear distinction between task items
- **Loading State:** Progress indicator during sync

### Data Requirements
- **Task Properties:** Title, description (optional), priority, due date
- **Sync Protocol:** JSON over BLE GATT characteristic
- **Performance:** Load and render < 2 seconds
- **Memory:** Efficient memory usage for 20+ tasks

---

## Story 2.3: The Active Task Screen UI

**As a** user  
**I want** a dedicated screen for my selected task with focus timer controls  
**So that** I can work on one task with minimal distractions

### Acceptance Criteria
- [ ] **AC2.3.1:** Tapping a task from the list opens the Active Task Screen
- [ ] **AC2.3.2:** Screen displays task title clearly on one side (left 60% of screen)
- [ ] **AC2.3.3:** Timer controls occupy right side (40% of screen) in vertical layout
- [ ] **AC2.3.4:** Timer controls include: Start, Pause, Resume, Reset buttons
- [ ] **AC2.3.5:** Current timer value displayed prominently (MM:SS format)
- [ ] **AC2.3.6:** Task title wraps appropriately and remains readable
- [ ] **AC2.3.7:** "Complete Task" button visible and accessible
- [ ] **AC2.3.8:** Navigation back to task list available

### Definition of Done
- [ ] Split-screen layout responsive to different task title lengths
- [ ] Timer display updates smoothly every second
- [ ] Button touch targets meet accessibility standards
- [ ] UI adheres to ADHD-friendly design principles
- [ ] Screen orientation locked to horizontal
- [ ] Performance meets 250ms response requirement

### Story Points: 8
**Estimation Notes:** Medium complexity due to split-screen layout and timer UI integration

### Design Specifications
- **Layout:** 60/40 split - Task info left, Timer controls right
- **Typography:** Task title 18px, Timer display 24px bold
- **Color Scheme:** High contrast, ADHD-friendly
- **Button Size:** Minimum 44px tap targets
- **Spacing:** Adequate white space for visual clarity

### UX Considerations
- Clear visual separation between task and timer areas
- Intuitive button placement for thumb navigation
- Visual feedback for all interactive elements
- Consistent with overall app design language

---

## Story 2.4: Functional Focus Timer

**As a** user  
**I want** a reliable timer that helps me focus on my current task  
**So that** I can implement Pomodoro technique or other time-boxing methods

### Acceptance Criteria
- [ ] **AC2.4.1:** Timer can be set to custom durations (1-120 minutes)
- [ ] **AC2.4.2:** Start button begins countdown immediately with visual confirmation
- [ ] **AC2.4.3:** Pause button stops timer and changes to Resume button
- [ ] **AC2.4.4:** Resume button continues from paused time
- [ ] **AC2.4.5:** Reset button returns timer to set duration with confirmation
- [ ] **AC2.4.6:** Display enters always-on, low-power state during active timer
- [ ] **AC2.4.7:** Clear, unmistakable alarm triggers when timer reaches zero
- [ ] **AC2.4.8:** Timer accuracy maintained within ±1 second over 30 minutes

### Definition of Done
- [ ] Timer logic implemented and tested for accuracy
- [ ] Always-on display mode functioning
- [ ] Alarm audio/vibration working reliably
- [ ] Button state management working correctly
- [ ] Power consumption measured in always-on mode
- [ ] Edge cases handled (timer during sleep, etc.)

### Story Points: 13
**Estimation Notes:** High complexity due to timing precision, power management, and always-on display requirements

### Technical Requirements
- **Timing Accuracy:** ±1 second over 30-minute period
- **Power Management:** Low-power always-on display mode
- **Alarm:** Audio tone + vibration (if available)
- **Persistence:** Timer continues during brief disconnections
- **Recovery:** Resume timer after watch restart

### Always-On Display Specifications
- **Brightness:** Reduced to 20% of normal
- **Update Rate:** 1 Hz for timer display
- **Content:** Show timer value and current time
- **Exit Condition:** Touch to return to normal brightness
- **Battery Impact:** Extend 12-hour battery requirement

---

## Story 2.5: The Focus Shield Implementation

**As a** user  
**I want** all notifications to be blocked when I'm in focus mode  
**So that** I can concentrate on my task without interruptions

### Acceptance Criteria
- [ ] **AC2.5.1:** Focus Shield activates automatically when Active Task Screen is visible
- [ ] **AC2.5.2:** All incoming SMS notifications are queued in memory (not displayed)
- [ ] **AC2.5.3:** Calendar notifications are also queued during Focus Shield
- [ ] **AC2.5.4:** Priority alerts (red flash) still override Focus Shield
- [ ] **AC2.5.5:** Shield status is subtly indicated on Active Task Screen
- [ ] **AC2.5.6:** Queued notifications are preserved during timer sessions
- [ ] **AC2.5.7:** Focus Shield deactivates when leaving Active Task Screen
- [ ] **AC2.5.8:** Memory usage for queued notifications is bounded (max 50 notifications)

### Definition of Done
- [ ] Notification interception system implemented
- [ ] Memory management for queued notifications
- [ ] Priority alert exception handling working
- [ ] Visual indicator for Focus Shield status
- [ ] Testing with various notification types
- [ ] Memory bounds enforced and tested

### Story Points: 21
**Estimation Notes:** Very high complexity due to system-level notification interception and memory management

### Technical Architecture
- **Notification Queue:** In-memory FIFO buffer
- **Max Capacity:** 50 notifications with overflow handling
- **Persistence:** Queue survives screen transitions within session
- **Memory Management:** Automatic cleanup of old notifications
- **Exception Handling:** Priority alerts bypass queue

### Focus Shield States
1. **Inactive:** Normal notification display
2. **Active:** Queue all notifications except priority alerts
3. **Transitioning:** Brief state during screen changes

### Testing Requirements
- Notification queueing during various timer states
- Memory management under high notification load
- Priority alert override functionality
- Queue persistence across screen transitions
- Performance impact measurement

---

## Epic 2 Summary

**Total Story Points:** 63  
**Sprint Capacity Recommendation:** 4-5 sprints (assuming 15 points per sprint capacity)

**Dependencies:**
- Bluetooth LE stack configuration
- Microsoft ToDo API integration (via companion app)
- Power management system
- Notification system architecture

**Risks:**
- BLE connection stability challenges
- Always-on display power consumption
- Notification system integration complexity
- Focus Shield memory management

**Success Metrics:**
- BLE connection stability > 95% over 8 hours
- Task sync completion < 5 seconds
- Timer accuracy within ±1 second over 30 minutes
- Focus Shield blocks 100% of non-priority notifications
- Battery life meets 12-hour requirement with always-on timer