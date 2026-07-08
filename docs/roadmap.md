# RxMind Engineering Roadmap (2026 Compliance)

**Last audited:** 2026-07-08  
**Audience:** Cursor Agent / vibe-coding sessions  
**Authority:** This file is the active task backlog. Read it first every session. Update checkboxes and the *Active Task* block when work completes.

---

## Active Task

| Field | Value |
| --- | --- |
| **Phase** | 2 |
| **Task ID** | 2.1 |
| **Branch pattern** | `feature/phase2-task2.1` |
| **Status** | Not started |
| **Prerequisites** | Phase 1 complete |

---

## Codebase Audit Summary (Current State)

### What works today

| Area | Status | Notes |
| --- | --- | --- |
| Flutter shell & navigation | Functional | `MainNavigationShell` with 6 tabs (Dashboard, Charts, Tasks, Meds, Chat, Settings) |
| OCR text extraction | Partial | Tesseract + ML Kit paths exist; PDF rasterizes pages to JPEG on disk |
| Discharge parsing UI flow | Functional | Upload → Review → Parse → Summary pipeline wired |
| Local notifications | Partial | `lib/services/notification_service.dart` schedules task reminders; bodies include raw task titles |
| Theme / accessibility toggles | Partial | Light/dark/high-contrast, text scale, reduced motion in `main.dart` |
| Manual medical contacts | Functional | Manual CRUD in `contacts_screen.dart` (no device contacts permission) |

### Critical gaps vs 2026 compliance

| Gap | Severity | Evidence |
| --- | --- | --- |
| Cloud AI (Gemini via Cloudflare Worker) | **Blocker** | `gemini_backend_client.dart`, `cloudflare-worker/`, all chat/parsing flows |
| Diagnostic / clinical AI prompts | **Blocker** | `ai_chat_screen.dart` system prompt claims HIPAA medical assistant; `parsing_progress.dart` "medical data extraction specialist" |
| Unencrypted CHD in SharedPreferences | **Blocker** | `discharge_data_manager.dart` stores meds, tasks, raw OCR text in plain prefs |
| No SQLCipher / hardware-backed keys | **Blocker** | `local_storage.dart` uses plain `sqflite` + default `FlutterSecureStorage` |
| Ephemeral OCR violated | **Blocker** | `text_extraction_service.dart` writes PDF pages & tessdata to flash |
| No AI safety pipeline | **Blocker** | No pre-inference regex, post-inference strip, or report flag UI |
| Notifications leak clinical strings | **High** | `notification_service.dart` body: `'$taskTitle is due in …'` |
| Duplicate / dead code paths | **Medium** | Two notification services; `chat_screen.dart` vs `ai_chat_screen.dart`; unused `lib/core/ocr/ocr_service.dart` |
| Platform declarations incomplete | **High** | No camera/photo usage strings in iOS plist; no `allowBackup=false`; no Health Apps declaration artifacts |
| No geofencing exclusion | **High** | No location module exists yet (required only if location is added) |
| Store / landing / Data Safety | **High** | README ASO copy uses "Smart Document Scanning"; no GitHub Pages site |

### Broken or risky code

- `StorageManager.getUserProfile()` casts `jsonStr` (a `String`) to `Map<String, dynamic>` — runtime type failure.
- `AppReset.resetAll()` requires injected managers but settings delete path only calls `DischargeDataManager.clearDischargeData()` — inconsistent wipe semantics.
- `main.dart` privacy dialog is bundled with Terms acceptance; no standalone CHD opt-in panel.
- Bundled Worker URL in `backend_config.dart` will fail DNS until deployed — AI features non-functional out of box.

---

## Phase 1: Pure Compliance Purge & Platform Declarations

**Goal:** Remove SaMD-triggering language, cloud diagnostic AI, and non-compliant marketing copy. Establish store-ready platform declarations and in-app disclaimers before any security refactor.

---

### 1.1 — Remove cloud Gemini backend and all remote inference paths ✅

**Acceptance Criteria:**
- `flutter analyze` reports zero imports of `gemini_backend_client.dart`, `google_gemini`, or `http` from AI/chat/OCR parsing screens.
- `cloudflare-worker/` is deleted or moved to `archive/` with a README stating it is not used in production builds.
- `pubspec.yaml` removes `google_gemini` and documents that AI inference is local-only (Phase 3).
- App builds and launches without `.env` `BACKEND_BASE_URL` set.
- Unit test `test/compliance/no_cloud_ai_imports_test.dart` fails if any `lib/` file under `screens/ai/`, `screens/ocr/`, or `services/ai/` imports `package:http`.

**Impacted Files:**
- `lib/services/ai/gemini_backend_client.dart` (delete)
- `lib/screens/ai/gemini_api_service.dart` (delete or stub)
- `lib/core/ai/ai_service.dart`
- `lib/screens/ai/ai_chat_screen.dart`
- `lib/screens/chat/chat_screen.dart`
- `lib/screens/ocr/parsing_progress.dart`
- `lib/config/backend_config.dart` (delete)
- `lib/gemini_api_key.dart` (delete if present)
- `cloudflare-worker/` (delete or archive)
- `pubspec.yaml`
- `README.md`
- `BACKEND_SETUP.md` (delete or rewrite)
- `test/compliance/no_cloud_ai_imports_test.dart` (create)

---

### 1.2 — Purge diagnostic AI system prompts and clinical decision language ✅

**Acceptance Criteria:**
- Grep across `lib/` for `(?i)(hipaa-compliant|diagnos|dosage|prescri|clinical decision|medical advice|treatment plan|medical assistant)` returns zero matches in AI prompt strings.
- `parsing_progress.dart` prompt reframed as neutral **wellness document organizer** (extract tasks, dates, contact phone numbers for user reference only — no dosing extraction mandates).
- `ai_chat_screen.dart` system instruction replaced with wellness-clarification scope: explicitly states non-medical-device, no dosing, no diagnosis.
- `test/compliance/prompt_language_test.dart` asserts banned regex list is absent from prompt source files.

**Impacted Files:**
- `lib/screens/ai/ai_chat_screen.dart`
- `lib/screens/ocr/parsing_progress.dart`
- `lib/screens/chat/chat_screen.dart`
- `test/compliance/prompt_language_test.dart` (create)

---

### 1.3 — Add mandatory non-medical-device disclaimer (first-use, non-dismissible until acknowledged) ✅

**Acceptance Criteria:**
- On cold start, before any health data entry, a full-screen modal displays verbatim first paragraph: *"This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Consult a licensed healthcare professional for medical advice."*
- User must tap **I Understand**; choice persisted in encrypted storage key `disclaimer_ack_v1`.
- Disclaimer re-shown after app data wipe.
- Widget test verifies disclaimer appears when `disclaimer_ack_v1` is absent.

**Impacted Files:**
- `lib/main.dart`
- `lib/screens/onboarding/disclaimer_gate_screen.dart` (create)
- `lib/core/storage/local_storage.dart`
- `test/widgets/disclaimer_gate_test.dart` (create)

---

### 1.4 — Replace bundled Privacy/Terms acceptance with standalone CHD consent panel ✅

**Acceptance Criteria:**
- Separate standalone screen (not combined with Terms checkbox) explains Consumer Health Data categories collected, local-only storage, and withdrawal via Settings → Erase All Data.
- Consent recorded with timestamp in secure storage key `chd_consent_v1`.
- App cannot proceed to upload/OCR until consent granted.
- `privacy_terms_screen.dart` updated to remove claims of automatic analytics collection and cloud Gemini transmission.

**Impacted Files:**
- `lib/main.dart`
- `lib/screens/onboarding/chd_consent_screen.dart` (create)
- `lib/screens/settings/privacy_terms_screen.dart`
- `test/widgets/chd_consent_test.dart` (create)

---

### 1.5 — ASO and in-app copy purge (diagnostic verbs & absolute claims) ✅

**Acceptance Criteria:**
- Grep repo (excluding this roadmap and compliance doc) for `(?i)(smart document|automatically extract|detect|diagnose|HIPAA-certified|medical device)` returns zero user-facing strings.
- `README.md` first paragraph matches store disclaimer wording.
- `welcome_carousel.dart` slide titles/descriptions use neutral verbs: *log*, *organize*, *remind* — not *smart*, *detect*, *analyze*.
- `web/manifest.json` description updated to wellness positioning.
- `docs/store/listing_copy.md` (create) contains Google Play and App Store descriptions with disclaimer as unformatted first paragraph.

**Impacted Files:**
- `README.md`
- `lib/screens/onboarding/welcome_carousel.dart`
- `lib/screens/onboarding/splash_screen.dart`
- `lib/screens/home/home_dashboard.dart`
- `web/manifest.json`
- `docs/store/listing_copy.md` (create)

---

### 1.6 — Consolidate duplicate chat and notification entry points ✅

**Acceptance Criteria:**
- Only one chat screen remains in navigation (`ai_chat_screen.dart`); `chat_screen.dart` deleted or redirected.
- Only one notification service remains (`lib/services/notification_service.dart`); `lib/services/notifications/notification_service.dart` deleted.
- All imports resolve to the surviving files; `flutter analyze` clean.

**Impacted Files:**
- `lib/screens/chat/chat_screen.dart` (delete)
- `lib/services/notifications/notification_service.dart` (delete)
- `lib/main.dart`
- `lib/screens/settings/settings_screen.dart`
- `lib/screens/tracker/tasks_screen.dart`

---

### 1.7 — Android platform declarations (manifest hardening) ✅

**Acceptance Criteria:**
- `AndroidManifest.xml` sets `android:allowBackup="false"` and `android:fullBackupContent="false"` on `<application>`.
- `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM` retained with inline XML comments documenting Play Console justification.
- `CAMERA` permission added with `android:required="false"` only if camera capture remains; no `READ_CONTACTS`, `ACCESS_FINE_LOCATION`, or Health Connect permissions present.
- `./gradlew :app:processReleaseManifest` succeeds.
- `docs/store/play_health_declaration.md` (create) drafts Health Apps Declaration answers.

**Impacted Files:**
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `docs/store/play_health_declaration.md` (create)

---

### 1.8 — iOS platform declarations (Info.plist & entitlements) ✅

**Acceptance Criteria:**
- `Info.plist` includes `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and `NSUserNotificationsUsageDescription` with user-benefit strings (no diagnostic language).
- No `NSContactsUsageDescription`, `NSLocationWhenInUseUsageDescription`, or HealthKit keys unless explicitly scoped in a later phase.
- `Runner.entitlements` sets `com.apple.developer.healthkit` absent; iCloud document storage disabled for app container.
- `docs/store/app_store_medical_status.md` (create) documents "not a regulated medical device" declaration inputs.

**Impacted Files:**
- `ios/Runner/Info.plist`
- `ios/Runner/Release.entitlements` (create or modify)
- `ios/Runner/DebugProfile.entitlements`
- `docs/store/app_store_medical_status.md` (create)

---

### 1.9 — Rename application ID from example namespace ✅

**Acceptance Criteria:**
- `applicationId` / `PRODUCT_BUNDLE_IDENTIFIER` changed from `com.example.rxmind_app` to organization-owned ID (default: `org.rxmind.app` unless overridden in task branch).
- `flutter build apk` and `flutter build ios --no-codesign` succeed after namespace migration.
- Kotlin `MainActivity` package path matches new namespace.

**Impacted Files:**
- `android/app/build.gradle.kts`
- `android/app/src/main/kotlin/**/MainActivity.kt`
- `ios/Runner.xcodeproj/project.pbxproj`
- `macos/Runner/Configs/AppInfo.xcconfig`

---

## Phase 2: Secure Database & Ephemeral OCR

**Goal:** Hardware-backed encryption for all Consumer Health Data; OCR pipelines that never persist raw frames to flash.

**Prerequisites:** Phase 1 complete.

---

### 2.1 — Android StrongBox-backed master key (Kotlin platform channel)

**Acceptance Criteria:**
- Platform channel `rxmind/crypto` exposes `generateMasterKey()` returning 256-bit AES key handle stored in Android Keystore with `setIsStrongBoxBacked(true)` when `PackageManager.FEATURE_STRONGBOX_KEYSTORE` is true; falls back to TEE with logged warning.
- Key requires user authentication (biometric or device PIN) via `setUserAuthenticationRequired(true)`.
- Instrumented test on API 28+ emulator verifies key generation and rejects access when device locked (simulated).
- Dart wrapper `MasterKeyService` returns opaque key alias, never raw key bytes to Dart heap.

**Impacted Files:**
- `android/app/src/main/kotlin/**/crypto/MasterKeyModule.kt` (create)
- `android/app/src/main/kotlin/**/MainActivity.kt`
- `lib/core/storage/master_key_service.dart` (create)
- `test/core/storage/master_key_service_test.dart` (create)

---

### 2.2 — iOS Secure Enclave master key (Swift platform channel)

**Acceptance Criteria:**
- Platform channel generates P-256 key with `kSecAttrTokenIDSecureEnclave` and accessibility `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- ECDH-based derivation API exposed to Dart as `deriveDatabaseKey()`.
- Unit test (iOS simulator) verifies key creation; Secure Enclave unavailable simulator falls back with explicit `SecureEnclaveUnavailableException`.
- No key material written to UserDefaults or unencrypted files.

**Impacted Files:**
- `ios/Runner/Crypto/MasterKeyModule.swift` (create)
- `ios/Runner/AppDelegate.swift`
- `lib/core/storage/master_key_service.dart`
- `test/core/storage/master_key_service_test.dart`

---

### 2.3 — SQLCipher integration with PBKDF2 100k derivation

**Acceptance Criteria:**
- Replace plain `sqflite` with `sqflite_sqlcipher` (or approved SQLCipher FFI wrapper).
- Database passphrase derived via PBKDF2-HMAC-SHA256, ≥100,000 iterations, random 32-byte salt stored alongside wrapped key in secure storage.
- `LocalStorage.initDb()` opens `rxmind.db` only after successful passphrase derivation.
- Test: deleting Keystore/Keychain master key causes `initDb()` to throw `DatabaseKeyException` and no plaintext SQLite file is readable via hex dump.

**Impacted Files:**
- `pubspec.yaml`
- `lib/core/storage/local_storage.dart`
- `lib/core/storage/sqlcipher_database.dart` (create)
- `lib/core/storage/key_derivation.dart` (create)
- `test/core/storage/sqlcipher_database_test.dart` (create)

---

### 2.4 — Migrate DischargeDataManager from SharedPreferences to encrypted SQLCipher tables

**Acceptance Criteria:**
- Schema tables: `medications`, `tasks`, `follow_ups`, `instructions`, `contacts`, `warnings`, `profile`, `ocr_text` (structured fields only).
- Zero health fields remain in SharedPreferences after migration; grep `SharedPreferences` in `discharge_data_manager.dart` returns zero write calls for CHD keys.
- One-time migration runs on upgrade: reads legacy prefs, inserts into SQLCipher, deletes legacy keys.
- Integration test seeds legacy prefs, launches migration, verifies row counts and prefs removal.

**Impacted Files:**
- `lib/services/discharge_data_manager.dart`
- `lib/core/storage/schema.dart` (create)
- `lib/core/storage/migration_v1.dart` (create)
- `lib/screens/home/home_dashboard.dart`
- `test/integration/migration_v1_test.dart` (create)

---

### 2.5 — Secure chat history storage (encrypted, not JSON in secure storage)

**Acceptance Criteria:**
- `ChatManager` persists messages to SQLCipher table `chat_messages` instead of `LocalStorage.writeSecure('ai_chats', ...)`.
- Message content encrypted at rest via SQLCipher page encryption.
- Test verifies chat history unreadable when DB passphrase unavailable.

**Impacted Files:**
- `lib/core/ai/chat_manager.dart`
- `lib/core/storage/schema.dart`
- `test/core/ai/chat_manager_test.dart` (create)

---

### 2.6 — Multi-pass cryptographic "Erase All My Data"

**Acceptance Criteria:**
- Settings **Delete All Data** invokes `SecureWipeService.wipeAll()`: cancels notifications, deletes SQLCipher DB file, overwrites with random bytes (3 passes) before unlink, clears secure storage, clears temp directories.
- `StorageManager.resetApp()` delegates to `SecureWipeService`; fixes `getUserProfile` JSON parse bug.
- Test verifies after wipe: no `rxmind.db`, no secure storage keys, `dischargeUploaded` false.

**Impacted Files:**
- `lib/core/storage/secure_wipe_service.dart` (create)
- `lib/core/storage/storage_manager.dart`
- `lib/core/storage/app_reset.dart`
- `lib/screens/settings/settings_screen.dart`
- `test/core/storage/secure_wipe_test.dart` (create)

---

### 2.7 — Ephemeral OCR pipeline (RAM-only frames, no flash writes)

**Acceptance Criteria:**
- Refactor `TextExtractionService` to accept in-memory `Uint8List` frames; prohibit `writeAsBytes` for OCR intermediates.
- PDF path renders pages to memory buffers only; no `getTemporaryDirectory()` usage in OCR flow.
- Tesseract tessdata loaded read-only from assets bundle each session OR stored in encrypted app-private dir with explicit compliance comment — never world-readable.
- `OcrService` (ML Kit) refactored to use `InputImage.fromBytes` with explicit buffer disposal after extraction.
- Test mocks file I/O during OCR and asserts zero calls to `File.writeAsBytes` in OCR code path.

**Impacted Files:**
- `lib/services/ocr/text_extraction_service.dart`
- `lib/core/ocr/ocr_service.dart`
- `lib/core/ocr/ephemeral_buffer.dart` (create)
- `lib/screens/ocr/upload_options.dart`
- `test/services/ocr/ephemeral_ocr_test.dart` (create)

---

### 2.8 — Raw OCR text minimization (store structured fields, not full discharge blob)

**Acceptance Criteria:**
- After parsing, full raw OCR text purged from DB unless user explicitly pins it; default saves structured extractions only.
- `loadRawOcrText()` returns null after successful parse+save unless ` retain_raw_ocr` user setting enabled.
- AI context builder uses structured meds/tasks only, not full discharge dump.

**Impacted Files:**
- `lib/services/discharge_data_manager.dart`
- `lib/screens/ocr/parsed_summary.dart`
- `lib/screens/ai/ai_chat_screen.dart`
- `lib/core/storage/schema.dart`

---

### 2.9 — Rate limiter migration off SharedPreferences

**Acceptance Criteria:**
- `RateLimiter` stores counters in SQLCipher settings table or secure storage — not SharedPreferences.
- Remaining SharedPreferences usage limited to non-CHD UI flags (theme, onboarding version).

**Impacted Files:**
- `lib/core/ai/rate_limiter.dart`
- `lib/services/notification_service.dart`
- `test/core/ai/rate_limiter_test.dart` (create)

---

## Phase 3: Generative AI Safety Containment

**Goal:** On-device quantized LLM with pre/post inference safety filters, emergency bypass UI, and mandatory reporting affordances.

**Prerequisites:** Phase 2 complete (local encrypted storage ready).

---

### 3.1 — Integrate on-device quantized LLM runtime

**Acceptance Criteria:**
- Add approved local inference package (e.g., `flutter_gemma` / `llama_cpp_dart` — exact package gated by orchestrator approval in `pubspec.yaml`).
- Model weights bundled or downloaded once to encrypted app storage; inference runs with zero network calls (verified via integration test with network disabled).
- `LocalAiService.generate()` replaces all Gemini call sites.
- Fallback static message if model fails to load.

**Impacted Files:**
- `pubspec.yaml`
- `lib/core/ai/local_ai_service.dart` (create)
- `lib/core/ai/ai_service.dart`
- `lib/screens/ai/gemini_api_service.dart` (replace with `local_ai_service.dart`)
- `test/core/ai/local_ai_service_test.dart` (create)

---

### 3.2 — Pre-inference regex emergency trigger gate

**Acceptance Criteria:**
- `SafetyInputFilter.evaluate(query)` blocks inference when query matches configured acute patterns (minimum: suicide/self-harm, overdose, heart attack/chest pain, stroke keywords).
- On trigger: skip LLM, navigate to `EmergencyStaticScreen` with localized crisis lines (988, 911) and user's saved clinical contacts.
- Test fixture with 20 blocked and 20 allowed queries achieves 100% expected routing.

**Impacted Files:**
- `lib/core/ai/safety_input_filter.dart` (create)
- `lib/core/ai/safety_patterns.dart` (create)
- `lib/screens/ai/emergency_static_screen.dart` (create)
- `lib/screens/ai/ai_chat_screen.dart`
- `test/core/ai/safety_input_filter_test.dart` (create)

---

### 3.3 — Post-inference prescription and dosing strip parser

**Acceptance Criteria:**
- `SafetyOutputFilter.sanitize(text)` removes lines matching: Rx header patterns, `mg/` dosage directives, "take X tablets", brand-name + numeric dose combos.
- Replaced segments logged locally (metadata only, not user content) for audit count.
- Test corpus of 50 synthetic LLM outputs strips 100% of dosing lines while preserving neutral educational text.

**Impacted Files:**
- `lib/core/ai/safety_output_filter.dart` (create)
- `lib/core/ai/safety_patterns.dart`
- `lib/screens/ai/ai_chat_screen.dart`
- `test/core/ai/safety_output_filter_test.dart` (create)

---

### 3.4 — AI transparency gate (pre-first-message)

**Acceptance Criteria:**
- Before first user message in any chat session, blocking banner requires acknowledgment: *"You are interacting with an automated on-device AI system, not a human clinician."*
- Persisted per chat session in DB field `ai_disclosure_ack`.
- EU AI Act Art. 50 label visible in chat app bar.

**Impacted Files:**
- `lib/screens/ai/ai_disclosure_banner.dart` (create)
- `lib/screens/ai/ai_chat_screen.dart`
- `lib/core/ai/chat_manager.dart`

---

### 3.5 — "Report Output" flag on every assistant bubble

**Acceptance Criteria:**
- Each assistant message bubble includes accessible **Report Output** control (min 48×48 dp tap target).
- Tap opens bottom sheet with reason codes; submission writes anonymized report record to local `ai_reports` SQLCipher table (timestamp, reason code, message hash — not full text).
- No network transmission of reports in v1 (local audit trail only).

**Impacted Files:**
- `lib/screens/ai/ai_chat_screen.dart`
- `lib/screens/ai/report_output_sheet.dart` (create)
- `lib/core/ai/ai_report_store.dart` (create)
- `lib/core/storage/schema.dart`
- `test/widgets/report_output_sheet_test.dart` (create)

---

### 3.6 — Neutral wellness-only parsing prompts for local model

**Acceptance Criteria:**
- `parsing_progress.dart` uses local model with JSON schema validation via `AiParser.validateJson`.
- Prompt explicitly forbids inferring diagnoses, adding meds not in source text, or fabricating doses.
- Parse failure shows manual entry fallback, not retry with cloud.

**Impacted Files:**
- `lib/screens/ocr/parsing_progress.dart`
- `lib/core/ai/ai_parser.dart`
- `lib/core/ai/local_ai_service.dart`

---

### 3.7 — Bias testing dataset stub (audit documentation)

**Acceptance Criteria:**
- `test/fixtures/ai_bias_validation_set.json` contains ≥30 anonymized synthetic discharge snippets spanning age/sex/ethnicity labels for offline evaluation harness.
- `docs/ai_moderation/bias_testing_log.md` documents last run date, pass/fail criteria, and model version.

**Impacted Files:**
- `test/fixtures/ai_bias_validation_set.json` (create)
- `docs/ai_moderation/bias_testing_log.md` (create)
- `tool/run_bias_harness.dart` (create)

---

## Phase 4: Native Contact Pickers & Geofencing Perimeter Exclusion

**Goal:** Least-privilege contact selection, healthcare-facility geofence exclusion, and lock-safe background write buffers.

**Prerequisites:** Phase 2 complete.

---

### 4.1 — Native contact picker integration (no READ_CONTACTS)

**Acceptance Criteria:**
- Adding a medical contact opens OS-native picker (`flutter_native_contact_picker` or platform channel using `Intent.ACTION_PICK` / `CNContactPickerViewController`).
- App receives only user-selected name + phone; no bulk contacts access.
- Android merged manifest contains zero `READ_CONTACTS` / `WRITE_CONTACTS` permissions (verify with `aapt dump permissions`).
- Manual entry fallback remains for devices without picker support.

**Impacted Files:**
- `pubspec.yaml`
- `lib/screens/settings/contacts_screen.dart`
- `lib/services/contacts/native_contact_picker_service.dart` (create)
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`
- `test/services/contacts/native_contact_picker_test.dart` (create)

---

### 4.2 — Clinical facility geofence exclusion module

**Acceptance Criteria:**
- If any location feature is added, `GeofenceGuard` checks coordinates against bundled static facility index (OpenStreetMap-derived, ≥500 US hospital/clinic points minimum viable; expandable).
- When user location is within 2,000 ft (609.6 m) of any facility, location-dependent features hard-disable and log `GeofenceBlockedEvent` locally.
- Default app build does not request location permission; module is no-op unless user enables optional feature flag `enableLocationFeatures` (default false).
- Unit test feeds known hospital coordinate, asserts block triggers at 1,500 ft and clears at 2,500 ft.

**Impacted Files:**
- `lib/core/location/geofence_guard.dart` (create)
- `assets/data/clinical_facilities_us.geojson` (create)
- `lib/core/location/facility_index.dart` (create)
- `test/core/location/geofence_guard_test.dart` (create)

---

### 4.3 — Neutral notification copy (no clinical strings on lock screen)

**Acceptance Criteria:**
- All scheduled notifications use static title `"Recovery reminder"` and body `"You have a scheduled wellness entry"` — never include medication names, dosages, or diagnosis-related task titles.
- `taskId` passed only in encrypted payload for in-app deep link after unlock.
- Test verifies notification builder output excludes user task title strings.

**Impacted Files:**
- `lib/services/notification_service.dart`
- `lib/core/notifications/neutral_notification_copy.dart` (create)
- `test/services/notification_service_test.dart` (create)

---

### 4.4 — Lock-safe RAM cache buffer for background notification rescheduling

**Acceptance Criteria:**
- When device locked (secure storage inaccessible), background reschedule writes pending task IDs to in-memory `LockSafeWriteBuffer` singleton (max 256 entries, volatile).
- On unlock/`AppLifecycleState.resumed`, buffer drains to SQLCipher within 5 seconds.
- If process killed, buffer loss is acceptable; next foreground launch rebuilds schedule from DB.
- Widget test simulates lifecycle locked→unlocked and verifies DB row count matches.

**Impacted Files:**
- `lib/core/storage/lock_safe_write_buffer.dart` (create)
- `lib/services/notification_service.dart`
- `lib/main.dart`
- `test/core/storage/lock_safe_write_buffer_test.dart` (create)

---

### 4.5 — Android WorkManager background maintenance worker

**Acceptance Criteria:**
- `ReminderSyncWorker` registered via WorkManager; runs only when app notifications enabled and device unlocked.
- Worker duration <30 seconds; no network access declared.
- Manifest includes `FOREGROUND_SERVICE` only if required by target SDK — otherwise omitted.

**Impacted Files:**
- `android/app/src/main/kotlin/**/workers/ReminderSyncWorker.kt` (create)
- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle.kts`
- `lib/services/background/reminder_sync_scheduler.dart` (create)

---

### 4.6 — iOS BGTaskScheduler registration for reminder sync

**Acceptance Criteria:**
- `BGAppRefreshTask` identifier `org.rxmind.app.reminder-sync` registered in `Info.plist` `BGTaskSchedulerPermittedIdentifiers`.
- Handler reschedules neutral notifications from SQLCipher when device unlocked.
- App Store review note documents background use in `docs/store/ios_background_justification.md`.

**Impacted Files:**
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/Info.plist`
- `lib/services/background/reminder_sync_scheduler.dart`
- `docs/store/ios_background_justification.md` (create)

---

### 4.7 — In-context permission disclosure modals

**Acceptance Criteria:**
- Before camera, photo library, or notification permission requests, show RxMind disclosure modal explaining data type, local storage, and user benefit (per Play / App Store 2026 guidance).
- Modal must be dismissed via **Continue** before `permission_handler` request invoked.
- Widget tests cover camera and notification disclosure order.

**Impacted Files:**
- `lib/screens/permissions/permission_disclosure_dialog.dart` (create)
- `lib/screens/ocr/upload_options.dart`
- `lib/screens/settings/settings_screen.dart`
- `test/widgets/permission_disclosure_test.dart` (create)

---

## Phase 5: UI/UX Accessible Redesign & Landing Page Setup

**Goal:** AI Studio–grade accessible themes, public compliance web presence, and store Data Safety documentation.

**Prerequisites:** Phases 1–3 complete (Phase 4 can parallelize).

---

### 5.1 — AI Studio high-contrast theme cascade

**Acceptance Criteria:**
- `AppTheme` refactored to token file `lib/theme/theme_tokens.dart` with WCAG 2.2 AA contrast ratios ≥4.5:1 for all body text combinations.
- High-contrast mode cascades: primary, surface, error, focus ring (3px), and link colors update together — no orphaned widgets.
- `golden_toolkit` or golden tests capture light/dark/high-contrast snapshots for Dashboard and Chat screens.

**Impacted Files:**
- `lib/theme/app_theme.dart`
- `lib/theme/theme_tokens.dart` (create)
- `lib/main.dart`
- `test/goldens/dashboard_theme_test.dart` (create)
- `test/goldens/chat_theme_test.dart` (create)

---

### 5.2 — Accessible navigation shell refactor

**Acceptance Criteria:**
- Bottom nav bar height ≥56 dp; each item has `Semantics` label, hint, and selected state.
- TalkBack / VoiceOver traversal order: top content → primary action → nav bar.
- Dynamic type supports up to 2.0× without layout overflow on primary screens (Dashboard, Tasks, Chat, Settings).

**Impacted Files:**
- `lib/screens/home/main_navigation_shell.dart`
- `lib/screens/home/home_dashboard.dart`
- `lib/screens/tracker/tasks_screen.dart`
- `lib/screens/ai/ai_chat_screen.dart`
- `lib/screens/settings/settings_screen.dart`

---

### 5.3 — Onboarding visual redesign (illustrations + disclaimer flow)

**Acceptance Criteria:**
- Onboarding integrates disclaimer gate (1.3) and CHD consent (1.4) into cohesive 5-step flow with progress indicator.
- All illustration SVGs include `Semantics` labels; reduced-motion skips parallax/transitions.
- Lighthouse accessibility score ≥90 on built web landing (see 5.5).

**Impacted Files:**
- `lib/screens/onboarding/welcome_carousel.dart`
- `lib/screens/onboarding/onboarding_profile_flow.dart`
- `lib/screens/onboarding/splash_screen.dart`
- `assets/illus/` (metadata only if SVGs updated)

---

### 5.4 — Settings accessibility and erase-data UX polish

**Acceptance Criteria:**
- **Erase All My Data** uses type-to-confirm pattern (`DELETE`) before wipe.
- Export PDF flow announces progress via screen reader live region.
- High-contrast toggle preview shows 3-second sample card before applying globally.

**Impacted Files:**
- `lib/screens/settings/settings_screen.dart`
- `lib/services/pdf_export_service.dart`
- `lib/screens/pdf/pdf_preview_screen.dart`

---

### 5.5 — GitHub Pages landing site (public privacy policy URL)

**Acceptance Criteria:**
- Static site published to `docs/site/` (or `gh-pages` branch) with pages: Home, Privacy Policy, Terms, Data Safety summary.
- Privacy policy URL is public, non-geofenced, HTML (not PDF), and matches in-app policy text version `2026-07-08`.
- `README.md` links to live GitHub Pages URL placeholder pattern: `https://<org>.github.io/RxMind/`.
- Includes first-paragraph medical disclaimer visible without JavaScript.

**Impacted Files:**
- `docs/site/index.html` (create)
- `docs/site/privacy.html` (create)
- `docs/site/terms.html` (create)
- `docs/site/data-safety.html` (create)
- `.github/workflows/pages.yml` (create)
- `README.md`

---

### 5.6 — Google Play Data Safety Form documentation

**Acceptance Criteria:**
- `docs/store/google_data_safety_form.md` lists every data type collected, encrypted in transit/at rest, user deletion method, and confirms **No data shared with third parties**.
- Documents camera/photo use for on-device OCR only; no analytics SDKs.
- Cross-check against actual `AndroidManifest.xml` permissions — zero undeclared collectors.

**Impacted Files:**
- `docs/store/google_data_safety_form.md` (create)
- `android/app/src/main/AndroidManifest.xml` (read-only verify)

---

### 5.7 — App Store Privacy Nutrition Labels documentation

**Acceptance Criteria:**
- `docs/store/apple_privacy_labels.md` maps RxMind data practices to App Store Connect questionnaire answers.
- Declares Health & Fitness data linked to user, not used for tracking, not collected off-device.

**Impacted Files:**
- `docs/store/apple_privacy_labels.md` (create)

---

### 5.8 — Store screenshot and metadata asset pack (neutral ASO)

**Acceptance Criteria:**
- `docs/store/screenshots/` contains template brief: no diagnostic claims, show disclaimer overlay on screenshot 1.
- `docs/store/listing_copy.md` finalized with keyword-safe copy ( verbs: *track*, *log*, *organize*, *remind*).

**Impacted Files:**
- `docs/store/screenshots/README.md` (create)
- `docs/store/listing_copy.md`

---

## Cross-Phase Quality Gates

Every task must pass before its checkbox is marked complete:

1. `flutter format .`
2. `flutter analyze` — zero issues
3. `flutter test` — 100% pass
4. Atomic git commit: `feat(pX-tX.Y): <description>` (agent protocol; human may disable auto-commit)

---

## Dependency & Risk Register

| Risk | Mitigation Task |
| --- | --- |
| Local LLM package size / device RAM | 3.1 — profile on 4 GB RAM device; quantize to ≤2 GB model |
| SQLCipher migration data loss | 2.4 — backup export before migration; rollback test |
| StrongBox unavailable on older Android | 2.1 — TEE fallback with user-visible security notice |
| Geofence false positives | 4.2 — conservative radius; manual override in Settings |
| Play Store org account requirement | 1.7 docs + human orchestrator account verification |

---

## Revision Log

| Date | Author | Change |
| --- | --- | --- |
| 2026-07-08 | Cursor Agent | Initial roadmap from codebase audit + 2026 compliance report |
