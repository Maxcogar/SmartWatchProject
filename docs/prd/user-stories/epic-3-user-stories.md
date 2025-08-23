# Epic 3: External Connectivity & Notifications - User Stories

## Story 3.1: Queued Notification Display

**As a** user  
**I want** to see all notifications that arrived during my focus session  
**So that** I can catch up on important messages after completing focused work

### Acceptance Criteria
- [ ] **AC3.1.1:** Notifications queued during Focus Shield are displayed when exiting Active Task Screen
- [ ] **AC3.1.2:** Notifications appear one at a time in chronological order (oldest first)
- [ ] **AC3.1.3:** Each notification requires explicit swipe gesture to dismiss
- [ ] **AC3.1.4:** Notifications remain on screen until user dismisses them (no auto-timeout)
- [ ] **AC3.1.5:** Swipe direction is consistent (left-to-right for dismiss)
- [ ] **AC3.1.6:** Visual indicator shows remaining notification count
- [ ] **AC3.1.7:** Users can navigate back without dismissing (notifications persist)
- [ ] **AC3.1.8:** Empty state displayed when all notifications are dismissed

### Definition of Done
- [ ] Notification display queue system implemented
- [ ] Swipe gesture recognition working reliably
- [ ] Chronological ordering verified
- [ ] Counter display accurate
- [ ] Persistence across navigation tested
- [ ] Empty state UI designed and implemented

### Story Points: 13
**Estimation Notes:** High complexity due to queue management, gesture recognition, and notification persistence

### UX Flow
1. User exits Active Task Screen after focus session
2. System displays first queued notification
3. User swipes to dismiss → next notification appears
4. Process continues until queue is empty
5. User can navigate away and return to continue queue

### Design Specifications
- **Notification Card:** Full-width, clear typography
- **Swipe Feedback:** Visual indication of swipe progress
- **Counter:** "3 of 7" style indicator
- **Dismiss Animation:** Smooth slide-out transition
- **Content:** Sender, timestamp, message preview

### Technical Requirements
- **Queue Persistence:** Maintain queue across app states
- **Gesture Recognition:** Reliable swipe detection
- **Memory Management:** Efficient notification storage
- **State Management:** Track dismissed vs. pending notifications

---

## Story 3.2: Task Completion Sync

**As a** user  
**I want** to mark tasks as complete directly from my smartwatch  
**So that** my task management stays synchronized without needing to use my phone

### Acceptance Criteria
- [ ] **AC3.2.1:** "Complete" button is prominently displayed on Active Task Screen
- [ ] **AC3.2.2:** Tapping Complete sends immediate signal to companion phone app
- [ ] **AC3.2.3:** Phone app successfully marks task as complete in Microsoft ToDo
- [ ] **AC3.2.4:** Completion status is confirmed back to the watch within 10 seconds
- [ ] **AC3.2.5:** Visual feedback indicates completion request is in progress
- [ ] **AC3.2.6:** Error handling for failed completion attempts with retry option
- [ ] **AC3.2.7:** Completed tasks are removed from watch task list on next sync
- [ ] **AC3.2.8:** Offline completion requests are queued for later sync

### Definition of Done
- [ ] Complete button UI implemented and positioned appropriately
- [ ] BLE communication protocol for completion signals
- [ ] Microsoft ToDo API integration via companion app
- [ ] Confirmation feedback system working
- [ ] Error handling and retry logic implemented
- [ ] Offline queue functionality tested

### Story Points: 21
**Estimation Notes:** Very high complexity due to bidirectional sync, API integration, and offline handling

### Completion Workflow
1. User taps "Complete" button on Active Task Screen
2. Watch sends completion signal via BLE to phone
3. Phone app calls Microsoft ToDo API to mark task complete
4. Phone sends confirmation back to watch
5. Watch displays success feedback and updates local task list
6. Failed attempts show error and offer retry option

### Technical Architecture
- **BLE Protocol:** Task completion message with unique task ID
- **API Integration:** Microsoft Graph API for ToDo operations
- **Offline Handling:** Queue completion requests when offline
- **State Management:** Track completion status for UI feedback
- **Error Recovery:** Automatic retry with exponential backoff

### Error Scenarios
- Network unavailable on phone
- Microsoft ToDo API error
- BLE connection lost during completion
- Task already completed by another device
- Authentication token expired

---

## Story 3.3: Modular Control Panel UI & Gesture

**As a** user  
**I want** quick access to device controls without disrupting my current workflow  
**So that** I can adjust settings or control connected devices efficiently

### Acceptance Criteria
- [ ] **AC3.3.1:** Right edge swipe gesture reveals translucent control panel overlay
- [ ] **AC3.3.2:** Control panel appears smoothly with appropriate animation (< 300ms)
- [ ] **AC3.3.3:** Panel is semi-transparent allowing underlying content to remain visible
- [ ] **AC3.3.4:** Left edge swipe gesture dismisses the control panel
- [ ] **AC3.3.5:** Control panel contains modular buttons for different functions
- [ ] **AC3.3.6:** Tap outside control panel area dismisses the panel
- [ ] **AC3.3.7:** Panel maintains consistent visual design with rest of app
- [ ] **AC3.3.8:** Edge swipe gestures are reliable and don't interfere with scrolling

### Definition of Done
- [ ] Edge swipe gesture detection implemented and tuned
- [ ] Overlay animation system working smoothly
- [ ] Semi-transparent UI rendering correctly
- [ ] Modular button system for extensible controls
- [ ] Gesture conflict resolution tested
- [ ] Visual design consistent with app theme

### Story Points: 13
**Estimation Notes:** High complexity due to custom gesture recognition and overlay UI system

### Gesture Specifications
- **Right Edge Swipe:** Start within 20px of right edge, swipe left minimum 50px
- **Left Edge Swipe:** Start within 20px of left edge, swipe right minimum 50px
- **Velocity Threshold:** Minimum swipe velocity to trigger action
- **Cancel Distance:** If swipe doesn't reach threshold, animation reverses

### Control Panel Design
- **Transparency:** 80% opacity background
- **Width:** 40% of screen width
- **Position:** Slides from right edge
- **Content:** Modular grid of control buttons
- **Animation:** Smooth ease-in-out transition

### Technical Implementation
- Custom gesture recognizer for edge swipes
- Overlay rendering system with transparency
- Modular component system for controls
- Animation framework for smooth transitions
- Z-order management for overlay display

---

## Story 3.4: Network Device Control Implementation

**As a** user  
**I want** to control my compressor and other network devices from my smartwatch  
**So that** I can manage my workshop environment without leaving my workstation

### Acceptance Criteria
- [ ] **AC3.4.1:** "Compressor" button visible in control panel
- [ ] **AC3.4.2:** Tapping Compressor button sends HTTP requests to two predefined local IP addresses
- [ ] **AC3.4.3:** HTTP requests complete within 5 seconds or show timeout error
- [ ] **AC3.4.4:** Visual feedback indicates request is in progress (loading state)
- [ ] **AC3.4.5:** Success/failure status displayed briefly after request completion
- [ ] **AC3.4.6:** Button state toggles between "ON" and "OFF" based on device status
- [ ] **AC3.4.7:** Network errors handled gracefully with user-friendly messages
- [ ] **AC3.4.8:** Multiple IP addresses can be configured for different device types

### Definition of Done
- [ ] HTTP client implementation for ESP32-S3
- [ ] Control panel button with toggle states
- [ ] Network error handling and user feedback
- [ ] Configuration system for IP addresses
- [ ] Loading states and status indicators
- [ ] Testing with mock HTTP endpoints

### Story Points: 8
**Estimation Notes:** Medium complexity due to HTTP client implementation and network error handling

### HTTP Protocol Specifications
- **Method:** POST or GET (configurable per device)
- **Timeout:** 5 seconds maximum
- **Retry:** Single retry attempt on failure
- **Headers:** Content-Type and User-Agent
- **Response:** Success based on HTTP status code (200-299)

### Device Configuration
```json
{
  "devices": [
    {
      "name": "Compressor",
      "ip_addresses": ["192.168.1.100", "192.168.1.101"],
      "method": "POST",
      "endpoint": "/toggle",
      "icon": "compressor"
    }
  ]
}
```

### User Feedback States
- **Idle:** Normal button appearance
- **Loading:** Spinner/progress indicator
- **Success:** Brief green checkmark
- **Error:** Brief red X with error message
- **Offline:** Grayed out with offline indicator

### Network Requirements
- **Protocol:** HTTP/1.1 over WiFi
- **Security:** Optional basic authentication
- **Discovery:** Static IP configuration (no mDNS)
- **Error Handling:** Connection timeout, DNS resolution, HTTP errors

---

## Epic 3 Summary

**Total Story Points:** 55  
**Sprint Capacity Recommendation:** 3-4 sprints (assuming 15 points per sprint capacity)

**Dependencies:**
- Notification queue system from Epic 2
- BLE communication protocol established
- WiFi network configuration
- Microsoft ToDo API integration (via companion app)

**Risks:**
- Network reliability for device control
- Microsoft ToDo API rate limits and authentication
- Complex gesture recognition implementation
- Offline synchronization complexity

**Success Metrics:**
- Queued notifications displayed 100% reliably after focus sessions
- Task completion sync success rate > 95%
- Control panel gesture recognition accuracy > 90%
- Network device control response time < 5 seconds
- No notification loss during queue operations

**Integration Points:**
- **Epic 1:** Priority alert system must override all notification displays
- **Epic 2:** Focus Shield queue feeds into notification display system
- **All Epics:** Consistent UI design and gesture patterns throughout

**Technical Architecture Notes:**
- HTTP client requires robust error handling due to local network variability
- Notification queue persistence across app lifecycle critical for user trust
- Gesture system must not interfere with existing touch navigation
- BLE protocol extensible for future device control features