# Google Play Health Apps Declaration — Draft Answers

**App:** RxMind (`com.rxmind.app`)  
**Last updated:** 2026-07-08

## App category

- **Health & fitness / Personal health organizer**
- **Not a regulated medical device** — wellness recovery organizer only

## Health features

| Feature | Description |
| --- | --- |
| Document capture | On-device OCR of discharge paperwork for user review |
| Medication & task logging | User-entered schedules and reminders |
| Wellness chat | On-device AI clarification (Phase 3); no cloud inference in production |

## Data handling

- All Consumer Health Data stored **locally on device**
- **No** data shared with third parties
- **No** cloud PHI storage
- User may erase all data via Settings → Delete All Data

## Permissions justification

| Permission | Justification |
| --- | --- |
| `POST_NOTIFICATIONS` | Wellness recovery task reminders |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Timely reminder scheduling |
| `CAMERA` (optional) | Capture discharge documents for on-device OCR |

## Permissions NOT used

- `READ_CONTACTS`, `WRITE_CONTACTS`
- `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
- Health Connect / HealthKit

## Medical device status

RxMind does **not** diagnose, treat, cure, or prevent medical conditions. First-screen disclaimer states non-medical-device status.
