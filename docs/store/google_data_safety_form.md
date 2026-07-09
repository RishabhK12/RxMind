# Google Play Data Safety Form — RxMind

**Last updated:** 2026-07-08  
**Cross-checked against:** `android/app/src/main/AndroidManifest.xml`

## App overview

| Field | Answer |
| --- | --- |
| App collects data | Yes |
| Data encrypted in transit | N/A — health data not transmitted to RxMind servers |
| Data encrypted at rest | Yes — SQLCipher database, secure storage for keys |
| Users can request deletion | Yes — Settings → Delete All Data (type DELETE) |
| Data shared with third parties | **No** |

## Declared Android permissions (manifest)

| Permission | Declared | Data Safety mapping |
| --- | --- | --- |
| `POST_NOTIFICATIONS` | Yes | App functionality — wellness reminders |
| `SCHEDULE_EXACT_ALARM` | Yes | App functionality — reminder scheduling |
| `USE_EXACT_ALARM` | Yes | App functionality — reminder scheduling |
| `CAMERA` | Yes (optional hardware) | Photos — on-device OCR only |
| `READ_CONTACTS` | **No** | OS contact picker returns single selection only |
| `ACCESS_FINE_LOCATION` | **No** | Not requested |
| Analytics / AD_ID | **No** | No advertising SDKs |

## Data types collected (on-device)

### Health and fitness

| Sub-type | Collected | Processed on device | Shared | Purpose |
| --- | --- | --- | --- | --- |
| Medications (names, schedules) | Yes | Yes | No | App functionality |
| Recovery tasks & instructions | Yes | Yes | No | App functionality |
| Discharge document text (OCR) | Yes | Yes | No | App functionality |
| Wellness notes / profile | Yes | Yes | No | App functionality |

### Photos and videos

| Sub-type | Collected | Processed on device | Shared | Purpose |
| --- | --- | --- | --- | --- |
| Discharge document images | Yes (user-initiated) | Yes — ephemeral OCR | No | App functionality |

### Personal info

| Sub-type | Collected | Processed on device | Shared | Purpose |
| --- | --- | --- | --- | --- |
| Name (optional profile) | Yes | Yes | No | App functionality |
| Phone (contact picker, user-selected) | Yes | Yes | No | App functionality |

### App activity

| Sub-type | Collected | Processed on device | Shared | Purpose |
| --- | --- | --- | --- | --- |
| On-device AI chat history | Yes | Yes | No | App functionality |

## Security practices

- SQLCipher encryption with PBKDF2-derived passphrase
- Android Keystore / iOS Secure Enclave master key wrapping
- Multi-pass secure wipe on user deletion
- Neutral notification copy (no clinical strings on lock screen)
- No cloud inference or health data upload in production builds

## Undeclared collectors

Verified: zero undeclared third-party analytics, crash reporting, or advertising SDKs in `pubspec.yaml` production dependencies for health screens.
