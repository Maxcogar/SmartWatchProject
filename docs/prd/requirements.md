# Requirements

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
4. **NFR4 (Usability):** The user interface must adhere to the five established "ADHD-Friendly Design Principles".
5. **NFR5 (Hardware Constraint):** The firmware shall be designed and optimized exclusively for the Waveshare ESP32-S3-Touch-LCD-2 hardware.
6. **NFR6 (Modularity):** The software architecture shall be layered (HAL, Services, Application, UI).
7. **NFR7 (Security):** The system must not store any secrets (WiFi credentials, API keys) directly in the compiled firmware binary.
8. **NFR8 (Display):** The UI must be rendered in a fixed horizontal orientation. When a focus timer is active, the display must enter a low-power, always-on state. At all other times, the screen will have a timeout.