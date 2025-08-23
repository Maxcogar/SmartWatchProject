# ESP32-S3 ADHD-Friendly Smartwatch Product Requirements Document (PRD)

This document has been sharded into manageable sections for development team consumption.

## Sections

- [Goals and Background Context](./goals-and-background-context.md)
- [Requirements](./requirements.md)
- [User Interface Design Goals](./user-interface-design-goals.md)
- [Technical Assumptions](./technical-assumptions.md)
- [Epic List](./epic-list.md)
- [Epic 1: Foundation, Core UI & Priority Systems](./epic-1-foundation-core-ui-priority-systems.md)
- [Epic 2: Task Management & The Focus Shield](./epic-2-task-management-focus-shield.md)
- [Epic 3: External Connectivity & Notifications](./epic-3-external-connectivity-notifications.md)

## Quick Development Reference

### Functional Requirements (9 total)
- FR1-FR3: Task management and sync
- FR4: Timer functionality
- FR5-FR7: Notifications and Focus Shield
- FR8-FR9: Device control and priority alerts

### Non-Functional Requirements (8 total)
- NFR1: Performance (<250ms response)
- NFR2: Stability (12-hour operation)
- NFR3: Battery life (12+ hours)
- NFR4: ADHD-friendly UI principles
- NFR5: ESP32-S3 hardware constraint
- NFR6-NFR8: Architecture, security, and display requirements

### Development Sequence
1. **Epic 1**: Foundation and core systems (Stories 1.1-1.3)
2. **Epic 2**: Task management and Focus Shield (Stories 2.1-2.5)
3. **Epic 3**: External connectivity (Stories 3.1-3.4)

## User Stories (Sprint-Ready)

**[📋 User Stories Master Document](user-stories/user-stories-master.md)** - Complete overview and sprint planning

### Individual Epic Stories
- [Epic 1 User Stories](user-stories/epic-1-user-stories.md) - Foundation, Core UI & Priority Systems (26 pts, 2 sprints)
- [Epic 2 User Stories](user-stories/epic-2-user-stories.md) - Task Management & Focus Shield (63 pts, 4-5 sprints)
- [Epic 3 User Stories](user-stories/epic-3-user-stories.md) - External Connectivity & Notifications (55 pts, 3-4 sprints)

### Sprint Planning Summary
- **Total Stories:** 12 detailed user stories
- **Total Story Points:** 144  
- **Estimated Duration:** 9-11 sprints (15 points per sprint)
- **MVP Completion:** Sprint 8 (Essential features complete)
- **Full Feature Set:** Sprint 10-11