# Project Brief: ESP32-S3 ADHD-Friendly Smartwatch

### Executive Summary
This project brief outlines the development of a custom-built ESP32-S3 smartwatch designed as a productivity and focus tool specifically for users with ADHD. The core mission is to create a non-distracting, high-quality wearable that integrates with Microsoft ToDo for task management and provides a persistent, on-device focus timer. Key features include a "Focus Shield" to queue notifications during work sessions, persistent alerts that require user dismissal, and contextual on-demand controls for network devices. The user interface will be built on the esp-brookesia framework to ensure a modern, clean, and intuitive touch-based experience, adhering to a strict set of 'ADHD-Friendly Design Principles' to aid focus and reduce cognitive load.

### Problem Statement
Commercial smartwatches, while feature-rich, often exacerbate the very focus and productivity challenges they claim to solve, particularly for users with ADHD. Their interfaces are typically dense with distracting applications, notifications are ephemeral and easily missed, and the user experience is optimized for broad consumer appeal rather than targeted focus enhancement. This creates a state of continuous partial attention.

The core problems to be solved are:
1.  **Notification Overload:** Standard smartwatches present a constant stream of notifications that are easy to dismiss accidentally and contribute to a fractured focus.
2.  **Lack of a "Focus State":** There is no built-in, disciplined way to enforce a "do not disturb" state that respects a user's commitment to a specific task for a set period.
3.  **High Cognitive Load:** Cluttered UIs with numerous apps, vibrant colors, and non-essential information require significant mental energy to navigate and parse, which is counterproductive to maintaining focus.
4.  **Generic Tooling:** Existing task management and timer apps are generic and fail to integrate in a way that provides persistent, glanceable context for the user's current task.

### Proposed Solution
The proposed solution is a purpose-built smartwatch on the ESP32-S3 platform, designed with a minimalist and focus-centric philosophy. The watch will serve as a dedicated productivity companion that actively protects the user's focus rather than competing for their attention.

The core of the solution is the **'Active Task Screen,'** a dedicated interface that displays the user's current Microsoft ToDo task alongside an integrated focus timer. This screen enables the **'Focus Shield,'** a system-level rule that automatically queues all non-critical phone and calendar notifications while the user is in a work session. These notifications are only revealed once the focus period is intentionally concluded by the user.

The user experience will be governed by a set of five **'ADHD-Friendly Design Principles'** emphasizing a single focus per screen, professional aesthetics, and persistent, actionable notifications. Secondary functionality, such as controlling network-connected devices, will be accessible via a non-intrusive, gesture-based **'Modular Control Panel.'** High-priority, real-world alerts, like a customer buzzer, will be handled by a transient, auto-dismissing **'Priority Alert System.'** The entire interface will be touch-driven and built on the modern esp-brookesia UI framework.

### Target Users
**Primary User Segment: The Technically-Proficient Professional with ADHD**
*   **Profile:** A professional who is technologically adept and has high standards for the tools they use. They are detail-oriented and value quality, modularity, and thoughtful design in both hardware and software.
*   **Goals:** To complete tasks more efficiently, reduce the mental friction of staying on track, and leverage technology to support a focused state rather than disrupt it.

### Goals & Success Metrics
**Business Objectives**
*   To create a high-quality, reliable, and purpose-built wearable.
*   To successfully integrate with the user's existing ecosystem.
*   To develop a modular and expandable software architecture.

**User Success Metrics**
*   A measurable increase in the number of completed focus timer sessions per week.
*   A reduction in self-reported instances of distraction caused by device notifications.

**Key Performance Indicators (KPIs)**
*   **System Stability:** The device operates without hangs or required reboots during a full workday.
*   **Battery Life:** The device maintains sufficient battery to last a minimum of 12 hours with typical use.
*   **UI Responsiveness:** All touch interactions provide feedback in under 250ms.

### MVP Scope
**Core Features (Must Have for MVP)**
*   Task Management (Sync, View, Complete)
*   Focus Timer with Always-On Display
*   Persistent Phone Notifications (SMS)
*   "Focus Shield" Notification Queuing
*   Network Device Control Panel
*   Priority Network Alerts (Buzzer)
*   Core UI Navigation (Home, Task List, Active Task Screen)

**Out of Scope for MVP**
*   Adding new tasks from the watch.
*   Caller ID / Call Management.
*   WiFi backup for notifications.
*   Dedicated Calendar app, Weather, Custom Faces.

### Post-MVP Vision (Revised)
*   **Phase 2:** Dedicated Calendar Display, "Focus Shield" Aware Caller ID.
*   **Long-term:** Voice-first, AI-powered commands via a physical button for on-the-fly reminders and IoT control.

### Technical Considerations (Expanded for Architect)
*   **Target Hardware:** Waveshare ESP32-S3-Touch-LCD-2.
*   **UI Framework:** esp-brookesia.
*   **Connectivity:** Bluetooth (Primary for phone), WiFi (Secondary for local IoT).
*   **Architecture Mandates:** Layered Architecture, Phone-as-Proxy design, No Hardcoded Secrets.
*   **Key Challenges:** Power Management, State Persistence, Connectivity Management, OTA Updates.

### Constraints & Assumptions
*   **Constraints:** Hardware-specific, personal project budget, single developer.
*   **Assumptions:** A companion phone app will be created, stable local network, accessible MS ToDo API.

### Risks & Open Questions (Revised)
*   **Risks:** Power consumption of the timer's always-on display, Bluetooth reliability, UI performance on the MCU.
*   **Open Questions:** Specific power draw, most battery-efficient connection management, esp-brookesia performance limits.

### Next Steps
*   **Immediate Actions:** Finalize brief, save as `docs/brief.md`, engage Product Manager.
*   **PM Handoff:** A clear directive for the PM to use this brief to create the PRD.