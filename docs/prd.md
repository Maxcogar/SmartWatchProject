# ESP32-S3 ADHD-Friendly Smartwatch Product Requirements Document (PRD)

### Goals and Background Context

**Goals**

* To create a high-quality, purpose-built wearable that directly addresses the user's specific productivity needs.
* To successfully integrate with the user's existing ecosystem (Microsoft ToDo, phone, local network devices).
* To develop a modular and expandable software architecture.
* To achieve a measurable increase in completed focus timer sessions and a reduction in distractions for the user.
* To ensure the device is stable and performant enough for all-day use.

**Background Context**
This project addresses a key gap in the commercial smartwatch market. This PRD outlines a purpose-built smartwatch that actively defends the user's focus by implementing a "Focus Shield" and adhering to a strict set of minimalist, "ADHD-Friendly Design Principles."

**Change Log**

| Date | Version | Description | Author |
| :--- | :--- | :--- | :--- |
| 2024-05-24 | 1.0 | Initial PRD Draft | John, PM |
| 2025-08-19 | 2.0 | Professional Enhancement - Added ADHD Design Principles, User Personas, Success Metrics, Technical Constraints, Enhanced Acceptance Criteria | BMad Orchestrator |

### Requirements

**Functional Requirements**

1. **FR1:** The system shall synchronize with a user's Microsoft ToDo account via a companion phone app to display a list of tasks.
2. **FR2:** The user shall be able to select a task from the list to set it as the "current task" on the "Active Task Screen".
3. **FR3:** The user shall be able to mark a task as "complete" from the watch, which will then sync back to their Microsoft ToDo account.
4. **FR4:** The system shall provide a countdown timer that the user can start for the current task.
5. **FR5:** The system shall display incoming SMS messages from a connected phone.
6. **FR6:** SMS notifications must remain on-screen until the user explicitly dismisses them with a swipe gesture.
7. **FR7:** The system shall implement a "Focus Shield" that queues all incoming SMS and calendar notifications while the "Active Task Screen" is visible.
8. **FR8:** The user shall be able to toggle a "Compressor" control from a slide-out "Modular Control Panel". This control will send HTTP requests to two predefined local IP addresses.
9. **FR9:** The system shall display a "Priority Alert" (full-screen red flash) for 3 seconds upon receiving a signal from a predefined local IP address. This alert must override all other UI states.

**Non-Functional Requirements**

1. **NFR1 (Performance):** All touch-based UI interactions must provide visual feedback to the user in under 250ms.
2. **NFR2 (Stability):** The device firmware must operate without crashing, freezing, or requiring a manual reboot during a continuous 12-hour period of typical use.
3. **NFR3 (Battery Life):** The device must have a battery life of at least 12 hours under a typical usage profile, which includes a minimum of three 25-minute focus sessions with the always-on display active.
4. **NFR4 (Usability):** The user interface must adhere to the five established "ADHD-Friendly Design Principles" (detailed in Section: ADHD-Friendly Design Principles).
5. **NFR5 (Hardware Constraint):** The firmware shall be designed and optimized exclusively for the Waveshare ESP32-S3-Touch-LCD-2 hardware.
6. **NFR6 (Modularity):** The software architecture shall be layered (HAL, Services, Application, UI).
7. **NFR7 (Security):** The system must not store any secrets (WiFi credentials, API keys) directly in the compiled firmware binary.
8. **NFR8 (Display):** The UI must be rendered in a fixed horizontal orientation. When a focus timer is active, the display must enter a low-power, always-on state. At all other times, the screen will have a timeout.

### ADHD-Friendly Design Principles

These five ADHD-Friendly Design Principles are grounded in clinical ADHD research and neurodivergent UX design best practices, addressing executive function challenges, attention regulation difficulties, and sensory processing needs.

#### Principle 1: Singular Focus
**"One Thing at a Time"** - Each screen presents exactly one primary task or decision point, preventing cognitive overload and reducing executive function demands. Maximum one primary call-to-action per screen with progressive disclosure for secondary options.

#### Principle 2: Immediate Clarity  
**"No Guessing Required"** - All interface elements provide instant understanding without cognitive processing time. High contrast ratios (4.5:1 minimum), clear affordances, text labels with icons, large touch targets (44px minimum), and unambiguous states.

#### Principle 3: Gentle Consistency
**"Familiar Patterns, Reduced Cognitive Load"** - Consistent interaction patterns throughout eliminate relearning behaviors. Standardized gestures, visual pattern consistency, predictable navigation flow, and interaction muscle memory development.

#### Principle 4: Protective Boundaries
**"Respect Focus States"** - Interface clearly communicates and enforces different attention states, supporting "Focus Shield" concept. Clear focus state indicators, user-controlled interruption levels, graceful queuing system, and context preservation.

#### Principle 5: Empowering Feedback
**"Immediate Response and Positive Reinforcement"** - All interactions provide immediate, confidence-building feedback. Sub-250ms response time, multi-modal feedback, progress visualization, celebration micro-interactions, and solution-focused error handling.

### User Personas & Target Audience

#### Primary Target: Adults with ADHD (Age 22-45)

**Alex Chen (ADHD-I Professional) - 60% of target market**
- Marketing Manager, 32 years old
- Challenges: Time blindness, notification overwhelm, task switching costs
- Strengths: Hyperfocus capability, creative problem-solving, crisis performance
- Key Needs: Focus protection, minimal cognitive load, clear task prioritization

**Sam Rodriguez (ADHD-H Student) - 25% of target market**  
- University student, 21 years old
- Challenges: Hyperfocus traps, impulse control, stimulation regulation
- Strengths: High energy, quick thinking, crisis management
- Key Needs: Gentle interruption management, energy regulation support, clear boundaries

**Jordan Kim (ADHD-C Creative) - 15% of target market**
- Creative professional, 28 years old  
- Challenges: Variable creative cycles, client management, sensory overwhelm
- Strengths: Creative hyperfocus, innovative problem-solving
- Key Needs: Flexible focus periods, creative flow protection, minimal distractions

### Success Metrics & KPIs

#### User Engagement Success
- **Daily Focus Sessions:** ≥1 focus timer session per day per user
- **Focus Completion Rate:** ≥80% of started focus timers completed without interruption
- **Task Completion Improvement:** ≥40% increase in daily completed tasks vs. baseline
- **30-Day User Retention:** >75% of users with consistent daily usage

#### Technical Performance Success
- **Touch Response Time:** <250ms for all interactions (NFR1 compliance)
- **BLE Connection Reliability:** >98% successful connection establishment
- **Battery Performance:** 12+ hours with minimum 3x 25-minute focus sessions
- **Focus Shield Effectiveness:** >95% notification blocking success during focus sessions

#### Business Success Indicators
- **MVP Delivery:** Sprint 8 delivery with 100% core functionality
- **User Satisfaction:** >4.5/5.0 on System Usability Scale
- **Quality Standards:** >90% unit test coverage, zero critical defects in production

### User Interface Design Goals

* **Overall UX Vision:** The experience is one of calm, focus, and deliberate action.
* **Core Screens:** Watch Face / Launcher (Home), Main Task List, Active Task Screen, Notification View, Modular Control Panel, Priority Alert View.

### Technical Constraints & Limitations

#### Hardware Constraints
* **Processing Power:** ESP32-S3 dual-core Xtensa LX7 @ 240MHz maximum
* **Memory Limitations:** 512KB SRAM, 384KB ROM - strict memory optimization required
* **Display:** 2.8" TFT LCD 320x240 resolution, fixed horizontal orientation only
* **Touch Interface:** Single-point capacitive touch, no multi-touch gestures
* **Battery:** Limited to ~12 hours continuous operation with aggressive power management

#### Connectivity Dependencies
* **BLE Range:** 10-meter maximum reliable connection distance from paired phone
* **WiFi Dependency:** Local network required for HTTP device control features
* **Phone-as-Proxy:** All internet services (Microsoft ToDo API) require companion phone
* **Offline Capability:** Limited to locally cached tasks and basic timer functionality

#### API & Integration Constraints
* **Microsoft ToDo API:** Rate limited to 10,000 requests per hour per application
* **BLE MTU Limitation:** Maximum 247 bytes per characteristic notification
* **JSON Processing:** Memory-constrained JSON parsing - maximum 2KB message size
* **Sync Latency:** 3-10 second sync delay for task updates depending on network conditions

#### User Interface Constraints
* **Single-Screen Focus:** No split-screen or multi-window interfaces due to display size
* **Touch Target Size:** Minimum 44px touch targets reduce available UI real estate
* **Text Rendering:** Limited font sizes and styles due to memory constraints
* **Animation Limitations:** Simple animations only to preserve battery and performance

#### Scalability & Future Limitations
* **User Data:** Single user device - no multi-user support planned
* **Task Volume:** Optimal performance with <100 active tasks
* **Notification Queue:** Maximum 20 queued notifications before oldest are dropped
* **Feature Expansion:** Limited flash memory constrains additional feature development

### Technical Assumptions

* **Repository Structure:** Monorepo
* **Service Architecture:** Layered Monolith
* **Key Assumptions:** Phone-as-Proxy, State Persistence, OTA Updates, High-Priority Power Management.

### Epic List & Effort Planning

**Total Project Estimate:** 76 Story Points across 11 Sprints

1. **Epic 1: Foundation, Core UI & Priority Systems** (26 Story Points - Sprints 1-3)
2. **Epic 2: Task Management & The Focus Shield** (32 Story Points - Sprints 4-7)  
3. **Epic 3: External Connectivity & Notifications** (18 Story Points - Sprints 8-11)

### Epic 1: Foundation, Core UI & Priority Systems (26 Story Points)

**Dependencies:** ESP-IDF setup, hardware procurement, development environment configuration
**Risk Factors:** Hardware delivery delays, toolchain compatibility issues
**Success Criteria:** Stable platform foundation with <250ms UI response time

#### **Story 1.1: Project Initialization and Basic Boot** (8 Story Points)
**Priority:** Critical | **Sprint:** 1 | **Dependencies:** Hardware delivery

**Enhanced Acceptance Criteria:**
* **AC 1.1.1 (Build System):** Project compiles without errors using ESP-IDF v5.1+ toolchain within 60 seconds on development machine
* **AC 1.1.2 (Boot Sequence):** Device completes power-on boot sequence within 5 seconds and displays splash screen
* **AC 1.1.3 (Display Initialization):** 320x240 LCD display initializes with correct orientation and 80% brightness level
* **AC 1.1.4 (Touch Calibration):** Touch screen responds to finger press with visual feedback within 250ms across entire display surface
* **AC 1.1.5 (Memory Validation):** System reports >400KB available heap memory at boot completion
* **AC 1.1.6 (Error Handling):** Failed initialization displays clear error message with diagnostic information

#### **Story 1.2: Home Screen UI and Navigation Shell** (10 Story Points)
**Priority:** High | **Sprint:** 1-2 | **Dependencies:** Story 1.1, LVGL integration

**Enhanced Acceptance Criteria:**
* **AC 1.2.1 (Home Display):** Home screen displays current time in 48px font size with date in 24px font beneath
* **AC 1.2.2 (Navigation Icons):** Four navigation icons (Tasks, Timer, Notifications, Settings) displayed in 2x2 grid with 44px minimum touch targets
* **AC 1.2.3 (Visual Hierarchy):** Time display uses high contrast (7:1 ratio), navigation icons use medium contrast (4.5:1 ratio)
* **AC 1.2.4 (Touch Response):** Icon tap provides visual feedback (color change) within 100ms and navigates to placeholder screen within 250ms
* **AC 1.2.5 (Battery Indicator):** Battery level displayed as percentage with low battery warning (<20%) using amber color
* **AC 1.2.6 (ADHD Principle Compliance):** Interface adheres to "Singular Focus" principle with time as primary element

#### **Story 1.3: Priority Alert System Implementation** (8 Story Points)
**Priority:** Critical | **Sprint:** 2 | **Dependencies:** WiFi connectivity, HTTP client implementation

**Enhanced Acceptance Criteria:**
* **AC 1.3.1 (Signal Reception):** Device receives HTTP POST signal from configurable IP address within 2 seconds of transmission
* **AC 1.3.2 (Alert Override):** Priority alert overrides any current UI state within 500ms of signal reception
* **AC 1.3.3 (Visual Alert):** Full-screen red background (RGB: 255,0,0) displayed for exactly 3.0 seconds ±100ms
* **AC 1.3.4 (Alert Text):** "PRIORITY ALERT" text displayed in 36px white font centered on red background
* **AC 1.3.5 (User Acknowledgment):** Touch anywhere on screen dismisses alert and returns to previous UI state
* **AC 1.3.6 (Audio Feedback):** Brief vibration pulse (100ms) accompanies visual alert if hardware supports
* **AC 1.3.7 (Logging):** Alert events logged with timestamp for debugging and analytics purposes

### Epic 2: Task Management & The Focus Shield (32 Story Points)

**Dependencies:** BLE stack implementation, Microsoft ToDo API integration, companion app development
**Risk Factors:** BLE connection stability, API rate limiting, focus timer accuracy
**Success Criteria:** >98% BLE connection reliability, >80% focus session completion rate

#### **Story 2.1: Bluetooth Connectivity & Handshake** (8 Story Points)
**Priority:** Critical | **Sprint:** 3 | **Dependencies:** BLE stack, pairing workflow

**Enhanced Acceptance Criteria:**
* **AC 2.1.1 (BLE Initialization):** Device successfully initializes BLE stack and begins advertising within 3 seconds of boot
* **AC 2.1.2 (Pairing Process):** Device pairs with companion phone using secure numeric comparison within 30 seconds
* **AC 2.1.3 (Connection Establishment):** BLE connection established with >98% success rate across 10 test attempts
* **AC 2.1.4 (Message Exchange):** Bidirectional message exchange confirmed with 100% data integrity using test payload
* **AC 2.1.5 (Connection Stability):** Connection maintained for >10 minutes with <2% packet loss under normal conditions
* **AC 2.1.6 (Reconnection):** Automatic reconnection within 10 seconds after connection drop
* **AC 2.1.7 (Error Handling):** Clear error messages displayed for pairing failures with retry mechanism

#### **Story 2.2: Task Synchronization and Display** (10 Story Points)
**Priority:** High | **Sprint:** 4 | **Dependencies:** Story 2.1, JSON parsing implementation

**Enhanced Acceptance Criteria:**
* **AC 2.2.1 (Task Request):** Watch initiates task sync request and receives response within 5 seconds
* **AC 2.2.2 (Data Format):** Tasks received in standardized JSON format with id, title, isComplete, priority fields
* **AC 2.2.3 (Task Display):** Scrollable list displays up to 20 tasks with title truncation at 30 characters
* **AC 2.2.4 (Visual Indicators):** Completed tasks shown with strikethrough, incomplete with checkbox icon
* **AC 2.2.5 (Priority Visualization):** High priority tasks displayed with red accent, medium with amber, low with green
* **AC 2.2.6 (Touch Responsiveness):** Task selection provides immediate visual feedback within 100ms
* **AC 2.2.7 (Data Persistence):** Tasks cached locally and survive device reboot until next sync

#### **Story 2.3: The Active Task Screen UI** (6 Story Points)
**Priority:** High | **Sprint:** 4 | **Dependencies:** Story 2.2, UI layout framework

**Enhanced Acceptance Criteria:**
* **AC 2.3.1 (Screen Layout):** Split-screen interface with task details (left 60%) and timer controls (right 40%)
* **AC 2.3.2 (Task Information):** Selected task title displayed in 20px font with priority indicator and description
* **AC 2.3.3 (Timer Display):** Large countdown timer (36px font) showing minutes:seconds format
* **AC 2.3.4 (Control Buttons):** Start, Pause, Stop buttons with 44px minimum touch targets and clear labels
* **AC 2.3.5 (Visual States):** Timer state (idle/running/paused) clearly indicated through color coding
* **AC 2.3.6 (Navigation):** Back button returns to task list, maintaining scroll position
* **AC 2.3.7 (ADHD Compliance):** Interface adheres to "Singular Focus" and "Immediate Clarity" principles

#### **Story 2.4: Functional Focus Timer** (8 Story Points)
**Priority:** Critical | **Sprint:** 5 | **Dependencies:** Story 2.3, power management implementation

**Enhanced Acceptance Criteria:**
* **AC 2.4.1 (Timer Accuracy):** Timer countdown accurate within ±1 second over 25-minute period
* **AC 2.4.2 (State Management):** Start, pause, resume functions work reliably with immediate UI feedback
* **AC 2.4.3 (Always-On Display):** Display remains active during timer session with reduced brightness (40%)
* **AC 2.4.4 (Completion Alert):** Timer completion triggers visual alert (full-screen green) and vibration for 3 seconds
* **AC 2.4.5 (Background Operation):** Timer continues running when user navigates away from active task screen
* **AC 2.4.6 (Power Management):** Timer operation maintains 12+ hour battery life requirement
* **AC 2.4.7 (Session Logging):** Timer sessions logged with start time, duration, completion status for analytics

#### **Story 2.5: The Focus Shield Implementation** (6 Story Points)
**Priority:** High | **Sprint:** 6 | **Dependencies:** Notification system, queue management

**Enhanced Acceptance Criteria:**
* **AC 2.5.1 (Shield Activation):** Focus Shield automatically activates when Active Task Screen displayed
* **AC 2.5.2 (Notification Queuing):** All incoming notifications queued in memory (max 20) during focus session
* **AC 2.5.3 (Queue Management):** Oldest notifications dropped when queue exceeds capacity with logging
* **AC 2.5.4 (Shield Indicator):** Visual indicator (shield icon) shows Focus Shield active status
* **AC 2.5.5 (Exception Handling):** Priority alerts (Story 1.3) override Focus Shield and display immediately
* **AC 2.5.6 (Shield Deactivation):** Focus Shield deactivates when timer completes or user exits Active Task Screen
* **AC 2.5.7 (Effectiveness Measurement):** >95% of notifications successfully queued without interrupting focus session

### Epic 3: External Connectivity & Notifications (18 Story Points)

**Dependencies:** Notification system, HTTP client implementation, gesture recognition
**Risk Factors:** Network latency, gesture recognition accuracy, notification overflow
**Success Criteria:** >75% notification engagement rate, <3 second HTTP response time

#### **Story 3.1: Queued Notification Display** (6 Story Points)
**Priority:** High | **Sprint:** 7 | **Dependencies:** Story 2.5, notification queue system

**Enhanced Acceptance Criteria:**
* **AC 3.1.1 (Queue Processing):** Notifications display sequentially after Focus Shield deactivation in FIFO order
* **AC 3.1.2 (Notification Layout):** Each notification shows sender, message preview (50 characters), timestamp in consistent format
* **AC 3.1.3 (Swipe Gesture):** Left swipe gesture dismisses notification with smooth animation within 200ms
* **AC 3.1.4 (Visual Feedback):** Swipe progress shown with sliding animation and fade-out effect
* **AC 3.1.5 (Queue Status):** Notification counter shows "X of Y" remaining notifications during review process
* **AC 3.1.6 (Auto-Advance):** Next notification automatically displays after 1 second delay following dismissal
* **AC 3.1.7 (Exit Mechanism):** User can exit notification review mode and return notifications to queue

#### **Story 3.2: Task Completion Sync** (4 Story Points)
**Priority:** High | **Sprint:** 8 | **Dependencies:** Story 2.3, Microsoft ToDo API integration

**Enhanced Acceptance Criteria:**
* **AC 3.2.1 (Complete Button):** Prominent "Complete" button on Active Task Screen with confirmation animation
* **AC 3.2.2 (Sync Request):** Task completion signal sent to phone within 1 second of button press
* **AC 3.2.3 (API Integration):** Phone successfully marks task complete in Microsoft ToDo API within 10 seconds
* **AC 3.2.4 (Confirmation Feedback):** Visual confirmation shown on watch when sync successful (checkmark animation)
* **AC 3.2.5 (Error Handling):** Sync failure displays retry option with clear error message
* **AC 3.2.6 (Offline Capability):** Completion cached locally when offline and synced when connection restored
* **AC 3.2.7 (Data Integrity):** 100% accuracy in task completion status across watch and Microsoft ToDo

#### **Story 3.3: Modular Control Panel UI & Gesture** (4 Story Points)
**Priority:** Medium | **Sprint:** 9 | **Dependencies:** Gesture recognition, overlay UI framework

**Enhanced Acceptance Criteria:**
* **AC 3.3.1 (Right Edge Swipe):** Swipe from right edge (within 20px) reveals control panel with slide-in animation
* **AC 3.3.2 (Panel Appearance):** Translucent overlay (70% opacity) with rounded corners and blur effect
* **AC 3.3.3 (Control Layout):** Control buttons arranged in vertical list with 44px minimum touch targets
* **AC 3.3.4 (Left Edge Swipe):** Swipe from left edge dismisses panel with slide-out animation within 300ms
* **AC 3.3.5 (Touch Outside):** Tap outside panel area dismisses panel and returns to previous screen
* **AC 3.3.6 (Visual Indicators):** Active controls show enabled state, inactive controls appear dimmed
* **AC 3.3.7 (Performance):** Panel animations maintain 30+ FPS frame rate without UI lag

#### **Story 3.4: Network Device Control Implementation** (4 Story Points)
**Priority:** Low | **Sprint:** 10 | **Dependencies:** Story 3.3, HTTP client, local network configuration

**Enhanced Acceptance Criteria:**
* **AC 3.4.1 (Compressor Button):** Toggle button in control panel labeled "Compressor" with on/off states
* **AC 3.4.2 (HTTP Requests):** Button press sends HTTP POST to two predefined IP addresses within 3 seconds
* **AC 3.4.3 (Network Configuration):** IP addresses configurable through companion app settings
* **AC 3.4.4 (Request Format):** HTTP requests include proper headers and JSON payload with device state
* **AC 3.4.5 (Response Handling):** HTTP responses validated and success/failure indicated on button
* **AC 3.4.6 (Timeout Management):** Request timeout after 5 seconds with appropriate error message
* **AC 3.4.7 (Network Resilience):** Graceful handling of network unavailability with retry mechanism
