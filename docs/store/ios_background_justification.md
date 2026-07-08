# iOS Background Task Justification — Reminder Sync

**Task identifier:** `org.rxmind.app.reminder-sync`  
**Type:** `BGAppRefreshTask`  
**Phase:** 4.6 (RxMind Engineering Roadmap)

## Purpose

RxMind schedules local wellness reminders for recovery tasks the user creates. The `BGAppRefreshTask` reschedules neutral notifications from the encrypted on-device SQLCipher database when the device is unlocked.

## Data handling

- **No network access.** The worker does not transmit data off-device.
- **No PHI in notifications.** Lock-screen title and body use static neutral copy only (`Recovery reminder` / `You have a scheduled wellness entry`). Task titles and medication names are never shown on the lock screen.
- **Encrypted storage.** Reminder schedules are read from SQLCipher; the master key is unavailable while the device is locked.

## User benefit

Ensures wellness reminders remain accurate after device reboot or OS background budget eviction, without requiring cloud sync.

## Review notes for App Store Connect

1. Background fetch is used solely for local notification rescheduling.
2. Location, HealthKit, and contacts bulk access are not used.
3. The task completes in under 30 seconds and does not run while the keyguard is engaged.
