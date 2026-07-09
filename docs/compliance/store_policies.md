# RxMind Store Submission Compliance Manual

**Document version:** 1.0  
**Last updated:** 2026-07-08  
**Audience:** Release engineering, App Store Connect / Play Console operators, Cursor Agent  
**Compliance basis:** *Mobile Health App Compliance 2026* — Sections 1 (Mobile App Store Policies) and 4 (Permissions & Background Services Minimization)  
**Related:** `docs/roadmap.md` Phase 1 & 4 & 6, `docs/architecture/data_isolation.md`, `docs/ai_moderation/safety_pipeline.md`, `docs/design/brand_identity.md` (visual identity — compliance copy still wins on claims)

---

## 1. Purpose

This manual is the **single source of truth** for first-pass approval on Google Play and the Apple App Store. Every submission must be validated against this checklist before upload. Automated store crawlers and human reviewers evaluate metadata, permissions, in-app disclaimers, and health-data handling — violations trigger rejection or post-launch delisting.

---

## 2. Current Permission Audit

### 2.1 Android — `android/app/src/main/AndroidManifest.xml`

| Permission | Status | Action |
| --- | --- | --- |
| `POST_NOTIFICATIONS` | **Present** | Keep — justify in Health Apps Declaration |
| `SCHEDULE_EXACT_ALARM` | **Present** | Keep — justify for recovery task reminders |
| `USE_EXACT_ALARM` | **Present** | Keep (API ≤32 compat) — audit if redundant on targetSdk 34+ |
| `READ_CONTACTS` | **Absent** | Must remain absent |
| `WRITE_CONTACTS` | **Absent** | Must remain absent |
| `ACCESS_FINE_LOCATION` | **Absent** | Must remain absent unless geofence module ships (see §7) |
| `ACCESS_COARSE_LOCATION` | **Absent** | Must remain absent unless geofence module ships |
| `READ_EXTERNAL_STORAGE` | **Absent** | Do not add — use photo picker / SAF |
| `CAMERA` | **Absent** | Add only with `android:required="false"` + disclosure modal |
| `INTERNET` | Debug/profile manifests only | **Strip from release** — verify merged release manifest |

**Gaps to fix before submission:**

- Add `android:allowBackup="false"` and `android:fullBackupContent="false"` on `<application>`
- Add `NSCameraUsageDescription` equivalent via manifest merge from `image_picker` — verify merged permissions with:

```bash
cd android && ./gradlew :app:processReleaseManifest
# Inspect build/app/intermediates/merged_manifests/release/AndroidManifest.xml
```

- Audit **merged manifest** for plugin-injected permissions (`READ_CONTACTS`, `ACCESS_FINE_LOCATION`) from `permission_handler`, `image_picker`, `file_picker`

### 2.2 iOS — `ios/Runner/Info.plist`

| Key | Status | Action |
| --- | --- | --- |
| `NSCameraUsageDescription` | **Missing** | **Add** before camera OCR ships |
| `NSPhotoLibraryUsageDescription` | **Missing** | **Add** before gallery import ships |
| `NSUserNotificationsUsageDescription` | **Missing** | **Add** (or request at runtime with justification) |
| `NSContactsUsageDescription` | **Absent** | Must remain absent — use `CNContactPickerViewController` |
| `NSLocationWhenInUseUsageDescription` | **Absent** | Must remain absent unless optional geofence ships |
| `NSLocationAlwaysUsageDescription` | **Absent** | **Never add** for RxMind v1 |
| HealthKit keys | **Absent** | Do not add — app is not a regulated medical device |

### 2.3 Forbidden permissions — hard block list

The following must **never** appear in the release merged manifest or release `Info.plist`:

```
READ_CONTACTS, WRITE_CONTACTS, GET_ACCOUNTS
ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, ACCESS_BACKGROUND_LOCATION
READ_CALL_LOG, READ_SMS, RECORD_AUDIO (unless voice feature ships with disclosure)
BODY_SENSORS, ACTIVITY_RECOGNITION
android.permission.health.* (Health Connect) — not used in v1
```

**Pre-submit CI command:**

```bash
# Android
grep -E "READ_CONTACTS|ACCESS_FINE_LOCATION|ACCESS_COARSE" \
  android/app/build/intermediates/merged_manifests/release/AndroidManifest.xml \
  && echo "FAIL: forbidden permission" && exit 1 || echo "PASS"

# iOS
grep -E "NSContactsUsageDescription|NSLocationWhenInUse" ios/Runner/Info.plist \
  && echo "REVIEW: location/contacts key present" || echo "PASS: no contacts/location plist keys"
```

---

## 3. Account & Category Requirements

### 3.1 Google Play

| Requirement | RxMind action |
| --- | --- |
| Verified **Organization** account | Submit only from corporate Play Console — not individual developer |
| App category | **Health & Fitness** (wellness organizer) — **not** Medical unless FDA-cleared SaMD |
| Health Apps Declaration | Complete per §5 — declare **non-medical device** |
| Privacy policy URL | Public HTML page (GitHub Pages) — not PDF, not geofenced |
| Data Safety form | Complete per `docs/store/google_data_safety_form.md` |

### 3.2 Apple App Store

| Requirement | RxMind action |
| --- | --- |
| Corporate developer account | Individual accounts prohibited for health-category apps |
| Regulated Medical Device status | Select **No** — app is a personal wellness organizer |
| Age Rating | Complete questionnaire; flag health/wellness topics |
| Privacy Nutrition Labels | Health data collected, linked to user, not used for tracking |
| App Privacy policy URL | Same public URL as Google Play |

---

## 4. Verbatim Disclaimers (In-App & Store)

### 4.1 Primary disclaimer — exact copy (mandatory)

Use this text **verbatim** for in-app first-run, store listing first paragraph, and privacy policy header. Do not paraphrase.

```
This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Always seek the advice of a licensed healthcare professional for medical questions.
```

**Store listing rule:** This paragraph must be the **first paragraph** of both Google Play and App Store descriptions, plain text, no markdown bolding in the store console text field.

### 4.2 Secondary AI disclaimer — exact copy

Display before first AI chat message (after primary disclaimer acknowledged):

```
You are interacting with an automated on-device AI system, not a human clinician. It can summarize information you provide but cannot diagnose conditions, recommend medication changes, or handle emergencies.
```

### 4.3 CHD consent panel — exact copy

Standalone screen (not combined with Terms checkbox):

```
RxMind stores health-related information you enter or scan (such as medications, recovery tasks, and appointment details) locally on this device only.

We do not sell your data or upload it to our servers. You can erase all data at any time in Settings.

Do you consent to RxMind collecting and processing this information on your device?
```

Buttons: **I Consent** (primary) | **Decline** (secondary — exits to limited mode or app close)

### 4.4 In-app disclaimer UI layout — first-run gate

**Screen:** `DisclaimerGateScreen` — blocks all navigation until acknowledged.

```
┌────────────────────────────────────────────────────────────┐
│  [RxMind logo]                                              │
│                                                             │
│  Important notice                                           │
│  ─────────────────                                          │
│                                                             │
│  This app is not a medical device and does not diagnose,    │
│  treat, cure, or prevent any medical condition. Always      │
│  seek the advice of a licensed healthcare professional      │
│  for medical questions.                                     │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │            I Understand                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [ View Privacy Policy ]                                    │
└────────────────────────────────────────────────────────────┘
```

| Layout spec | Value |
| --- | --- |
| Disclaimer body font | `bodyLarge`, minimum 16sp |
| Contrast | WCAG AA (4.5:1) against background |
| `I Understand` button | Full-width, min height 48dp |
| Dismiss without tap | **Forbidden** — no swipe-back, no `barrierDismissible` |
| Persistence | `disclaimer_ack_v1` in secure storage |
| Re-show after | Data wipe, fresh install |

### 4.5 Settings persistent disclaimer strip

Below Settings → About, always visible:

```
RxMind is a personal recovery organizer, not a substitute for professional medical care.
```

---

## 5. Google Play — Health Apps Declaration (Literal Answers)

Complete at: **Play Console → Policy → App content → Health apps**

Use these answers verbatim unless Play Console field labels differ — map to closest field.

### 5.1 App type & regulatory status

**Q: Is your app a medical device?**  
**A:** No. RxMind is a personal wellness and recovery organizer. It is not FDA-cleared or CE-marked as a medical device.

**Q: Does your app provide clinical decision support, diagnosis, or treatment recommendations?**  
**A:** No. The app helps users log and organize discharge paperwork, tasks, and medication schedules they enter or scan. On-device AI may rephrase user-provided text for clarity but does not diagnose, prescribe, or recommend treatment changes.

### 5.2 Health features provided (select only these)

- [x] Disease management and clinical care (**organizational only — user-entered logs**)
- [ ] Clinical decision support
- [ ] Telemedicine
- [ ] Medical device connectivity
- [ ] Human subject research
- [x] Health apps that access health and fitness data (**user-entered recovery data, local only**)

**Feature description (paste):**

```
RxMind helps users organize post-hospital discharge instructions. Users may photograph or import discharge documents; the app extracts text on-device and lets users review medications, tasks, and follow-up appointments. All health data is stored locally on the device with encryption. The app does not transmit health data to developer servers.
```

### 5.3 Data collection & sharing

**Q: Does your app collect health data?**  
**A:** Yes — user-entered and user-scanned recovery information (medications, tasks, appointments, optional profile fields).

**Q: Is health data shared with third parties?**  
**A:** No. All health data remains on the device. No analytics SDKs process health screens.

**Q: Is health data encrypted?**  
**A:** Yes — SQLCipher database with hardware-backed key derivation (Android Keystore StrongBox / iOS Secure Enclave).

### 5.4 Permission justifications

#### `POST_NOTIFICATIONS`

```
RxMind schedules local reminders for user-created recovery tasks (e.g., wound care, appointments). Notifications use generic text ("Recovery reminder") and do not display medication names or diagnoses on the lock screen. Users can disable notifications in Settings.
```

#### `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`

```
Used only to deliver user-configured recovery task reminders at specific times the user sets. Not used for background health data collection. User can disable reminders in app Settings.
```

#### `CAMERA` (when added to manifest)

```
The camera captures discharge document photos for on-device OCR text extraction only. Images are processed in volatile memory and are not uploaded to servers. User initiates each capture via an in-app disclosure modal before the system permission prompt.
```

#### Photo library / storage (via picker, not broad storage permission)

```
Users may select an existing PDF or image from the system document/photo picker to import discharge paperwork. RxMind receives only the user-selected file bytes; it does not scan the entire media library.
```

### 5.5 Permissions we do NOT use (declare explicitly in internal notes)

```
RxMind does NOT request: READ_CONTACTS, WRITE_CONTACTS, ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION, Health Connect permissions, or body sensor permissions. Medical contacts are entered manually or via the OS native contact picker (single-selection).
```

---

## 6. Apple App Store Connect — Declaration Guide

### 6.1 App Information

| Field | Value |
| --- | --- |
| **Subtitle** | Organize your recovery plan |
| **Category** | Primary: Health & Fitness |
| **Regulated Medical Device** | **No** |

### 6.2 Description — first paragraph (verbatim)

Paste §4.1 primary disclaimer as the opening paragraph, then:

```
RxMind is a private, on-device recovery organizer. Log medications, tasks, and follow-up appointments from your discharge paperwork. All data stays on your phone. Optional on-device AI helps clarify instructions you already uploaded — it does not provide medical advice.
```

### 6.3 App Review Notes (paste for reviewer)

```
RxMind is a non-medical wellness organizer.

TEST ACCOUNT: Not required — no login.

PERMISSIONS:
- Notifications: local task reminders only; generic lock-screen text.
- Camera/Photos: optional discharge document import; on-device OCR only.
- No Contacts, Location, HealthKit, or background location.

DISCLAIMER: First-launch full-screen medical disclaimer must be accepted before use.

AI: On-device only in production build; no cloud health data transmission.

ERASE DATA: Settings → Delete All Data performs full local wipe.

Contact: [support email]
```

### 6.4 Info.plist strings to add (verbatim)

```xml
<key>NSCameraUsageDescription</key>
<string>RxMind uses the camera to photograph discharge documents for on-device text extraction. Photos are not uploaded.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>RxMind lets you select a discharge document image or PDF from your library for on-device processing. Only the file you choose is accessed.</string>

<key>NSUserNotificationsUsageDescription</key>
<string>RxMind sends local reminders for recovery tasks you schedule. Notification text is generic and does not include medication names.</string>
```

---

## 7. Geofence Exclusion Map (WA MHMDA Compliance)

### 7.1 Regulatory requirement

Under the Washington My Health My Data Act and RxMind compliance policy: **do not execute virtual geofencing within 2,000 feet (609.6 meters) of physical healthcare or clinic facilities** unless the user has explicitly enabled a documented optional feature — and even then, location collection must hard-stop inside the exclusion zone.

**RxMind v1 default:** Location features **disabled** (`enableLocationFeatures = false`). No location permission in manifest.

### 7.2 When location is enabled (future optional feature)

Implement `GeofenceGuard` per `docs/roadmap.md` Phase 4.2:

| Rule ID | Specification |
| --- | --- |
| **GEO-01** | Exclusion radius: **609.6 m** (2,000 ft) from facility centroid |
| **GEO-02** | Facility index: bundled `assets/data/clinical_facilities_us.geojson` (≥500 POIs minimum viable) |
| **GEO-03** | Distance function: Haversine on WGS-84 coordinates |
| **GEO-04** | On `distance < 609.6m`: set `locationCollectionBlocked = true`; discard fix; no persistence |
| **GEO-05** | No background location — foreground-only, user-initiated |
| **GEO-06** | Log `GeofenceBlockedEvent` locally (timestamp + facility ID hash only) |

### 7.3 Technical implementation

```dart
// lib/core/location/geofence_guard.dart

class GeofenceGuard {
  static const exclusionRadiusMeters = 609.6; // 2,000 feet

  static Future<GeofenceResult> evaluate(double lat, double lon) async {
    final facilities = await FacilityIndex.load();
    for (final f in facilities) {
      final d = _haversineMeters(lat, lon, f.lat, f.lon);
      if (d < exclusionRadiusMeters) {
        return GeofenceResult.blocked(
          facilityId: f.id,
          distanceMeters: d,
        );
      }
    }
    return GeofenceResult.allowed();
  }

  static double _haversineMeters(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
```

### 7.4 Facility index schema

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "id": "us-hosp-00001",
        "name": "Example Medical Center",
        "type": "hospital"
      },
      "geometry": {
        "type": "Point",
        "coordinates": [-122.3321, 47.6062]
      }
    }
  ]
}
```

### 7.5 Play Console / App Store declaration if location ships

```
Location is used only when the user explicitly enables optional wellness features. RxMind does not collect location within 2,000 feet of hospitals or clinics. Coordinates are processed on-device and are not uploaded.
```

**If location is NOT shipped in v1:** Do not add location permission strings; answer "No location data collected" on Data Safety / Privacy Nutrition Labels.

---

## 8. Contact Picker Rules (No READ_CONTACTS)

### 8.1 Policy

- **Never** request `READ_CONTACTS`, `WRITE_CONTACTS`, or `NSContactsUsageDescription`
- **Never** use `flutter_contacts`, `contacts_service`, or bulk contact sync
- Users add clinical phone numbers via **manual entry** OR **OS native picker** (single selection)

### 8.2 Current codebase status

`lib/screens/settings/contacts_screen.dart` uses **manual CRUD only** — compliant. No device contacts permission required today.

### 8.3 Native picker integration (target)

**Android:**

```kotlin
// Intent.ACTION_PICK with ContactsContract.CommonDataKinds.Phone.CONTENT_URI
// Returns RESULT_OK with single contact URI — extract display name + one phone only
```

**iOS:**

```swift
// CNContactPickerViewController — implement CNContactPickerDelegate
// Return selected contact's givenName + phoneNumber string only
```

**Flutter wrapper:** `flutter_native_contact_picker` or custom platform channel `rxmind/contacts/pickSingle`.

### 8.4 Developer checklist

| Step | Action |
| --- | --- |
| 1 | Verify merged manifest has zero `READ_CONTACTS` / `WRITE_CONTACTS` |
| 2 | Verify `Info.plist` has no `NSContactsUsageDescription` |
| 3 | Replace "Import from contacts" (if added) with picker button — never full sync |
| 4 | Store only user-selected name + phone in SQLCipher `contacts` table |
| 5 | Do not upload contact hashes to analytics |

### 8.5 UI copy for picker button

```
Add from device contacts
```

Subtitle:

```
You'll choose one contact. RxMind cannot access your full contact list.
```

---

## 9. Neutral Notification Payload Standard

### 9.1 Policy

Notifications are visible on the **lock screen**. They must not reveal patient-specific diagnostics, medication names, dosages, or OCR-extracted clinical strings.

### 9.2 Current violation

`lib/services/notification_service.dart` line 180:

```dart
body: '$taskTitle is due in ${_formatDuration(minutesBefore)}',  // NON-COMPLIANT
```

Task titles may contain medication names or clinical instructions.

### 9.3 Approved payload (mandatory)

| Field | Allowed value | Forbidden |
| --- | --- | --- |
| **Title** | `Recovery reminder` | `Task Reminder`, `Medication`, drug names |
| **Body** | `You have a scheduled wellness entry` | Task title, med name, dosage, diagnosis |
| **Payload** | Opaque `task_id` (UUID) for in-app deep link after unlock | JSON with CHD fields |
| **Channel name (Android)** | `Recovery Reminders` | `Task Reminders` with clinical description |

```dart
// lib/core/notifications/neutral_notification_copy.dart

class NeutralNotificationCopy {
  static const title = 'Recovery reminder';
  static const body = 'You have a scheduled wellness entry';
}
```

```dart
// COMPLIANT scheduling
await _scheduleNotification(
  id: _getNotificationId(taskId, i),
  title: NeutralNotificationCopy.title,
  body: NeutralNotificationCopy.body,
  scheduledTime: notificationTime,
  payload: taskId, // opaque ID only
);
```

### 9.4 Localization

When translating, maintain neutral tone — no clinical terms:

| Language | Title | Body |
| --- | --- | --- |
| en | Recovery reminder | You have a scheduled wellness entry |
| es | Recordatorio de recuperación | Tiene una entrada de bienestar programada |

### 9.5 Verification test

```dart
test('notification body never contains task title', () async {
  await service.scheduleTaskNotifications(
    taskId: 't1',
    taskTitle: 'Take Metformin 500mg',
    dueTime: DateTime.now().add(Duration(hours: 1)),
  );
  final pending = await getPendingNotificationDetails();
  expect(pending.body, NeutralNotificationCopy.body);
  expect(pending.body, isNot(contains('Metformin')));
});
```

---

## 10. Store Listing Copy Rules (ASO Safety)

### 10.1 Forbidden words in title, subtitle, screenshots

```
diagnose, detect, treat, cure, prevent, prescribe, clinical decision,
HIPAA-certified, medical device, FDA-approved, doctor-approved,
smart document scanning, automatically extract (implies diagnostic AI)
```

### 10.2 Approved verb replacements

| Avoid | Use |
| --- | --- |
| Smart scanning | Document import |
| Automatically extract | Help organize text you scan |
| Health assistant | Recovery organizer |
| Detect anomalies | Log your entries |
| AI diagnosis | On-device clarification |

### 10.3 README / screenshot fix required

Current `README.md` contains **"Smart Document Scanning"** and **"automatically"** — replace before store submission per §10.1.

---

## 11. In-Context Permission Disclosure (Required Before System Prompt)

Show **RxMind disclosure modal** before `permission_handler` or system permission sheet.

### 11.1 Camera disclosure — verbatim

```
RxMind needs camera access so you can photograph discharge documents. Images are processed on your device only and are not uploaded to our servers.
```

Buttons: **Continue** → system camera prompt | **Not now** → cancel

### 11.2 Notifications disclosure — verbatim

```
RxMind can send local reminders for recovery tasks you schedule. Notification text stays generic and does not show medication names on your lock screen. You can turn this off in Settings.
```

### 11.3 Exact alarm disclosure (Android 12+) — verbatim

```
For timely reminders, RxMind may request permission to schedule alarms. Without it, reminders may arrive a few minutes early or late.
```

---

## 12. Pre-Submission Checklist

### 12.1 Binary & manifest

- [ ] Release merged manifest: no `READ_CONTACTS`, `ACCESS_FINE_LOCATION`, `INTERNET` (production)
- [ ] `android:allowBackup="false"`
- [ ] iOS plist: camera, photo, notification usage strings present
- [ ] iOS plist: no contacts, location, HealthKit keys (unless §7 shipped)
- [ ] App ID not `com.example.*`

### 12.2 In-app compliance

- [ ] §4.1 disclaimer gate on first launch
- [ ] CHD consent panel separate from Terms
- [ ] AI disclosure before first chat message
- [ ] Neutral notifications (§9)
- [ ] Native contact picker or manual entry only (§8)
- [ ] Erase All Data works (`SecureWipeService`)

### 12.3 Store console

- [ ] Organization account (both platforms)
- [ ] §4.1 disclaimer as first paragraph of listing
- [ ] Health Apps Declaration completed (§5)
- [ ] Privacy policy URL live (HTML, public)
- [ ] Data Safety / Privacy Nutrition Labels accurate
- [ ] App Review Notes pasted (§6.3)
- [ ] Screenshots show disclaimer overlay on screenshot 1

### 12.4 Metadata crawl safety

- [ ] No forbidden ASO words (§10)
- [ ] Category: Health & Fitness, not Medical device
- [ ] Regulated Medical Device = **No** (Apple)

---

## 13. Rejection Recovery Playbook

| Rejection reason | Fix |
| --- | --- |
| Misleading health claims | Revise metadata per §10; add in-app disclaimer |
| Excessive permissions | Run merged manifest audit; remove plugin bloat |
| Missing privacy policy | Publish `docs/site/privacy.html` to GitHub Pages |
| Health declaration incomplete | Resubmit with §5 literal answers |
| Contacts access without justification | Remove permission; ship picker (§8) |
| Location without core feature | Remove permission or ship geofence guard (§7) |
| AI without reporting | Implement Report Output per `safety_pipeline.md` §8 |

---

## 14. Roadmap Cross-Reference

| Section | Roadmap task |
| --- | --- |
| §4 Disclaimers | 1.3, 1.4 |
| §5 Play declaration | 1.7 |
| §6 Apple plist | 1.8 |
| §7 Geofence | 4.2 |
| §8 Contact picker | 4.1 |
| §9 Notifications | 4.3 |
| §11 Disclosure modals | 4.7 |

---

## 15. Revision Log

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| 1.0 | 2026-07-08 | App Store Release Specialist | Initial submission manual from manifest audit + Compliance §1/§4 |
