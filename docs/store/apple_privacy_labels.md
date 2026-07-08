# App Store Privacy Nutrition Labels — RxMind

**Last updated:** 2026-07-08  
**Cross-checked against:** `ios/Runner/Info.plist`

## Summary questionnaire answers

| Question | Answer |
| --- | --- |
| Data used to track you | **No** |
| Data linked to you | **Yes** (health data stored on device, linked to user profile) |
| Data collected off-device by developer | **No** |

## Data types

### Health & Fitness

| Detail | Value |
| --- | --- |
| Collected | Yes |
| Linked to identity | Yes (local profile) |
| Used for tracking | No |
| Purpose | App Functionality |
| Examples | Medications, recovery tasks, discharge instructions, wellness notes |

### User Content

| Detail | Value |
| --- | --- |
| Collected | Yes |
| Linked to identity | Yes |
| Used for tracking | No |
| Purpose | App Functionality |
| Examples | Scanned discharge documents (on-device OCR), on-device AI chat |

### Contact Info

| Detail | Value |
| --- | --- |
| Collected | Yes (user-selected via CNContactPicker only) |
| Linked to identity | Yes |
| Used for tracking | No |
| Purpose | App Functionality |
| Examples | Clinician name and phone number user selects |

### Photos or Videos

| Detail | Value |
| --- | --- |
| Collected | Yes (user-initiated camera / photo library) |
| Linked to identity | Yes |
| Used for tracking | No |
| Purpose | App Functionality |
| Examples | Discharge document capture for on-device text extraction |

## iOS permission keys (Info.plist)

| Key | Present | Notes |
| --- | --- | --- |
| `NSCameraUsageDescription` | Yes | On-device document capture |
| `NSPhotoLibraryUsageDescription` | Yes | Import discharge documents |
| `NSUserNotificationsUsageDescription` | Yes | Wellness reminders |
| `NSContactsUsageDescription` | **No** | Contact picker only — no bulk access |
| `NSLocationWhenInUseUsageDescription` | **No** | Location not requested |
| HealthKit | **No** | Not a regulated medical device integration |

## Encryption & deletion

- Data encrypted at rest via SQLCipher
- User deletion: Settings → Delete All Data (type DELETE to confirm)
- No RxMind-operated cloud database receives health data
