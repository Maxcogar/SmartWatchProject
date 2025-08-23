# ESP32-S3 ADHD-Friendly Smartwatch UI/UX Specification

### Introduction
This document defines the user experience goals, information architecture, user flows, and visual design specifications for the ESP32-S3 ADHD-Friendly Smartwatch's user interface. It serves as the foundation for visual design and frontend development, ensuring a cohesive and user-centered experience.

**Overall UX Goals & Principles**
*   **Target User Personas:** The Technically-Proficient Professional with ADHD.
*   **Usability Goals:** Clarity, Efficiency, Error Prevention, Memorability.
*   **Design Principles:**
    1.  One Primary Focus Per Screen
    2.  Clean & Modern Aesthetics
    3.  Professional & Uncluttered Visual Language
    4.  Actionable & Persistent Notifications
    5.  Contextual, On-Demand Controls

**Change Log**
| Date       | Version | Description              | Author         |
| :--------- | :------ | :----------------------- | :------------- |
| 2024-05-24 | 1.0     | Initial UI/UX Spec Draft | Sally, UX Expert |

### Information Architecture (IA)
**Site Map / Screen Inventory**

graph TD
    A[Watch Face / Launcher] --> B[Main Task List];
    A --> C[Messages App - Placeholder];
    A --> D[Device Controls App - Placeholder];
    
    B --> E[Active Task Screen];
    E --> B;

    subgraph "System Overlays"
        F[Notification View]
        G[Modular Control Panel]
        H[Priority Alert View]
    end

**Navigation Structure**
*   **Primary Navigation:** The **Watch Face / Launcher** is the root of the application.
*   **Hierarchical Navigation:** Tapping an item navigates "deeper" into its context.
*   **Gesture Navigation:** A standard right-swipe is the primary "back" gesture. An edge-swipe from the right opens the "Modular Control Panel".

### User Flows
*   **Flow 1: Start a Focus Session:** User navigates from Watch Face -> Task List -> Active Task Screen and starts the timer.
*   **Flow 2: Review Queued Notifications:** User exits the Active Task Screen, which triggers a one-by-one review of queued notifications.
*   **Flow 3: Use the Modular Control Panel:** User performs a right-edge-swipe to reveal the control overlay, toggles a device, and dismisses the panel with a left-edge-swipe.

### Wireframes & Mockups
*   **1. Watch Face / Launcher:** Top status bar (Time, Status Icons). Main content area is a grid of large, clear launcher icons with text labels.
*   **2. Main Task List Screen:** Top status bar, header ("My Tasks"), and a vertically scrollable list of tasks (checkbox + title).
*   **3. Active Task Screen:** A 60/40 vertical split-screen. The left side shows the full task text and a "Complete" button. The right side shows the large timer display and its controls ("Start", "Pause", "Stop").

### Component Library / Design System
*   **Design System Approach:** A custom, minimalist set of UI components using the esp-brookesia framework.
*   **Core Components:**
    *   **Status Bar:** Displays time and system status icons.
    *   **Launcher Icon:** Tappable entry point for an application.
    *   **Task List Item:** A row in the task list with a checkbox and text.
    *   **Stateful Button:** A general-purpose button with variants for primary, secondary, and toggle actions.

### Branding & Style Guide
*   **Visual Identity:** Minimalist, professional, "glassmorphism" aesthetic.
*   **Color Palette:** Dark mode-first. Black background, white/grey text, blue accent, with green, orange, and red for stateful colors.
*   **Typography:** A single, highly-legible sans-serif font.
*   **Iconography:** Custom, high-quality, minimalist line icons.
*   **Spacing & Layout:** A consistent 4px-based spacing scale for all margins and padding.

### Accessibility Requirements
*   **Compliance Target:** No formal standard for MVP, but adherence to good practices.
*   **Key Requirements:** Minimum 4.5:1 color contrast, 44x44 pixel minimum touch targets, and clear, visible labels for all controls.

### Responsiveness Strategy
*   Not applicable. The UI is designed for a single, fixed-resolution horizontal display on the target hardware.

### Animation & Micro-interactions
*   **Motion Principles:** Animation will be subtle, purposeful, and performant.
*   **Key Animations:** Simple visual feedback for button presses, clean slide/fade screen transitions, a smooth slide-in/out for the control panel, and a rapid full-screen flash for the priority alarm.

 