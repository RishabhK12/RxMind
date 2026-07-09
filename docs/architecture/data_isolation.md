# RxMind Data Isolation Architecture

**Document version:** 1.0  
**Last updated:** 2026-07-08  
**Status:** Target specification (implementation tracked in `docs/roadmap.md` Phase 2.7–2.8, Phase 4.3)  
**Compliance basis:** *Mobile Health App Compliance 2026* — Sections 1 (SaMD boundary), 3 (CHD minimization), 4 (neutral notifications)  
**Related:** `docs/architecture/security_storage.md` (SQLCipher persistence layer)

---

## 1. Purpose & Scope

This document specifies how RxMind **isolates Protected Health Information (PHI) and Consumer Health Data (CHD)** from:

- Untrusted OS processes and other applications
- Unencrypted filesystem locations (SharedPreferences, temp dirs, photo roll caches)
- Cloud endpoints and third-party analytics SDKs
- Unregulated wellness UI code paths that must never read raw clinical buffers

It defines the **Ephemeral Memory Processing** contract for camera OCR (prescription / discharge label scans) and future voice inputs, and maps the **code boundary** between safe configuration data and sensitive clinical models.

---

## 2. Regulatory Data-Minization Requirements

From *Mobile Health App Compliance 2026*:

| Rule | Source | RxMind implication |
| --- | --- | --- |
| Raw frame buffers live only in volatile RAM, zeroed after text extraction | §1 Architecture Impact, §3 Architecture Impact | No JPEG/PNG/PDF raster writes during OCR |
| No raw image data to flash or external caches | §1, §3 Must-Avoid | Ban `writeAsBytes` on OCR intermediates |
| No CHD in unencrypted dirs, UserDefaults, or cloud config | §3 Must-Avoid | Migrate CHD off SharedPreferences |
| Modular separation of wellness UI from analytical/parsing pipelines | §1 SaMD boundary | Package-level import firewall |
| Notifications use neutral strings, not raw clinical logs | §1, §4 | Notification layer cannot read med names from CHD store |
| No cloud transmission of raw biometric, diagnostic, or image files | §3 Architecture Impact | OCR bytes never sent to network stack |
| Voice waveforms ephemeral unless in SQLCipher | §3 Architecture Impact | ASR pipeline mirrors OCR RAM rules |

**Data minimization principle:** Persist the **minimum structured fields** the user needs (task title, schedule, contact phone). Do **not** persist full raw OCR dumps by default.

---

## 3. Current State — Isolation Violations

### 3.1 OCR pipeline audit

| File | Violation | Line-of-sight evidence |
| --- | --- | --- |
| `lib/services/ocr/text_extraction_service.dart` | Tessdata copied to **Application Documents** | `getApplicationDocumentsDirectory()` + `engFile.writeAsBytes(...)` |
| `lib/services/ocr/text_extraction_service.dart` | PDF pages written as **JPEG to temp disk** | `getTemporaryDirectory()` → `page_${i}.jpg` → `writeAsBytes` |
| `lib/services/ocr/text_extraction_service.dart` | Tesseract reads from **file path**, forcing disk residency | `FlutterTesseractOcr.extractText(imagePath, ...)` |
| `lib/core/ocr/ocr_service.dart` | ML Kit reads from **`File` on disk** | `InputImage.fromFile(imageFile)` |
| `lib/screens/ocr/upload_options.dart` | `image_picker` / `file_picker` retain paths in `_selectedFilePaths` | User photos may remain in system cache |
| `lib/services/discharge_data_manager.dart` | Full **`rawOcrText`** persisted in SharedPreferences | `_keyRawOcrText` unencrypted |
| `lib/services/discharge_data_manager.dart` | All CHD (meds, tasks, contacts) in **SharedPreferences** | Plain JSON strings on disk |

### 3.2 Persistence vs ephemeral intent

```
CURRENT (NON-COMPLIANT)                         TARGET (THIS SPEC)
─────────────────────────                       ────────────────────
Camera/File ──► disk path ──► OCR ──► text     Camera ──► Uint8List RAM ──► OCR ──► text
                      │                                              │
                      ▼                                              ▼
              temp JPEG / PDF pages                          zeroize buffers
                      │                                              │
                      ▼                                              ▼
           SharedPreferences (raw OCR)                  SQLCipher structured rows ONLY
```

---

## 4. Trust Zones & Classification

### 4.1 Data classification tiers

| Tier | Label | Examples | Allowed storage | Allowed transit |
| --- | --- | --- | --- | --- |
| **T0** | Public config | Theme mode, text scale, onboarding version | SharedPreferences | None |
| **T1** | Sensitive prefs | Notification lead times (minutes), disclaimer ack flags | FlutterSecureStorage or SharedPreferences | None |
| **T2** | Wellness profile | Display name, bedtime (non-clinical scheduling) | SQLCipher `profile` table | None |
| **T3** | **CHD / PHI** | Medications, tasks, warnings, contacts, parsed OCR fields, chat content | SQLCipher only | None (local UI render) |
| **T4** | **Ephemeral raw** | Camera frames, PDF raster bytes, PCM audio chunks | **Volatile RAM only** | Never persisted |

### 4.2 Process trust model

| Zone | Trust level | Components |
| --- | --- | --- |
| **Trusted — RxMind CHD core** | Highest | `lib/core/chd/`, `lib/core/ocr/` (ephemeral), SQLCipher repositories |
| **Trusted — Crypto** | Highest | `lib/core/storage/`, native Keystore / Secure Enclave channels |
| **Semi-trusted — Wellness UI** | Medium | Dashboard, theme, onboarding (reads CHD via repository interfaces only) |
| **Untrusted — Third-party plugins** | Low | Tesseract, ML Kit, image_picker (must receive pre-copied RAM buffers; never own file paths to CHD) |
| **Forbidden** | None | Cloud HTTP clients, analytics SDKs, SharedPreferences for T3/T4 |

---

## 5. Code Boundary Map

### 5.1 Module dependency firewall

```
lib/
├── config/                          [T0] App constants, no CHD imports
├── theme/                           [T0] Visual tokens only
│
├── core/
│   ├── config/                      [T0–T1] UserSettingsRepository (theme, notif times)
│   ├── chd/                         [T3]     ► CLINICAL SANDBOX ◄
│   │   ├── repositories/            MedicationRepository, TaskRepository, ...
│   │   ├── models/                  Medication, RecoveryTask, ClinicalContact
│   │   └── chd_gate.dart            Single export; asserts caller authorization
│   ├── ocr/                         [T4→T3]  Ephemeral ingest ONLY
│   │   ├── ephemeral_buffer.dart    SecureBytes wrapper
│   │   ├── ocr_pipeline.dart        RAM-in → text-out → zeroize
│   │   └── ocr_cleaner.dart         Text normalization (no disk I/O)
│   ├── voice/                       [T4→T3]  Future ASR (same contract as OCR)
│   │   └── ephemeral_audio_buffer.dart
│   └── storage/                     [T3]     SQLCipher (see security_storage.md)
│
├── services/
│   ├── notifications/               [T1]     NeutralNotificationScheduler
│   │   └── (MUST NOT import core/chd/models with clinical strings)
│   └── discharge_data_manager.dart  [DEPRECATED → migrate to core/chd/repositories]
│
└── screens/
    ├── settings/                    [T0–T1]  Theme, notification timing UI
    ├── ocr/                         [T4]     Invokes OcrPipeline; no direct DB writes
    └── tracker/                     [T3]     Reads via repository interfaces
```

### 5.2 Import rules (enforced by lint + test)

| From | May import | Must NOT import |
| --- | --- | --- |
| `lib/theme/**` | Flutter, theme tokens | `core/chd`, `services/discharge_data_manager` |
| `lib/core/config/**` | SharedPreferences, secure storage | `core/chd/models`, OCR pipeline |
| `lib/services/notifications/**` | Task IDs, due timestamps | Medication names, OCR text, `DischargeDataManager.loadMedications` |
| `lib/core/ocr/**` | ML Kit / Tesseract adapters, `ephemeral_buffer` | SQLCipher directly (returns DTO to caller) |
| `lib/core/chd/**` | `core/storage`, models | `image_picker`, `file_picker`, `http` |
| `lib/screens/ocr/**` | `OcrPipeline`, UI | SharedPreferences, raw `File` path persistence |

**Lint test:** `test/compliance/import_boundary_test.dart` parses `package:analyzer` or greps imports and fails if `lib/theme/` imports `lib/core/chd/`.

### 5.3 Decoupling table — wellness config vs clinical logs

| Concern | Wellness / unregulated module | Clinical / CHD module | Coupling mechanism |
| --- | --- | --- | --- |
| App theme | `RxMindSettings` in `main.dart`, `AppTheme` | — | None |
| Notification timing | `NotificationService.getNotificationTimes()` → `[120, 30, 5]` minutes | Task due dates in SQLCipher | Scheduler receives **opaque task ID + DateTime** only |
| Notification copy | `NeutralNotificationCopy.body` static string | — | Scheduler never reads task title |
| User display name | `profile.display_name` (T2) | — | Dashboard greets by name; no med data |
| Recovery tasks | — | `TaskRepository` (T3) | UI widgets consume view models |
| OCR ingest | `UploadOptionsScreen` camera UX | `OcrPipeline.extractText(SecureBytes)` | One-shot DTO crossing boundary |
| AI chat context | — | Structured rows via `ChdContextBuilder` | Never passes `rawOcrText` blob |

---

## 6. Ephemeral Memory Processing Specification

### 6.1 Design goals

1. **Single RAM lifetime:** Raw bytes exist only from capture/import decode until UTF-8 text is extracted.
2. **No flash spill:** Zero calls to `File.writeAsBytes`, `getTemporaryDirectory`, or `getApplicationDocumentsDirectory` inside the OCR hot path.
3. **Deterministic zeroization:** All byte buffers overwritten in `finally` blocks before scope exit.
4. **Structured handoff:** Only `OcrTextResult` (Dart `String`) crosses into the CHD sandbox; caller decides what structured fields to persist.

### 6.2 Camera frame path (prescription / label scan)

```
┌──────────────┐    ┌─────────────────┐    ┌──────────────────┐    ┌─────────────┐
│ CameraX /    │    │ SecureBytes     │    │ OcrEngine        │    │ OcrCleaner  │
│ AVCapture    │───►│ (Uint8List RAM) │───►│ ML Kit / Tess    │───►│ normalize   │
│ ImageBytes   │    │ + zeroize()     │    │ InputImage.      │    │ text only   │
└──────────────┘    └─────────────────┘    │ fromBytes()      │    └──────┬──────┘
                                            └──────────────────┘           │
                                                                             ▼
                                                                    ┌────────────────┐
                                                                    │ OcrTextResult  │
                                                                    │ (String only)  │
                                                                    └────────┬───────┘
                                                                             │
                         ═════════════════ ZEROIZE BOUNDARY ══════════════════╪
                                                                             ▼
                                                                    ┌────────────────┐
                                                                    │ Parse / Review │
                                                                    │ UI (screens)   │
                                                                    └────────┬───────┘
                                                                             ▼
                                                                    ┌────────────────┐
                                                                    │ SQLCipher T3   │
                                                                    │ structured rows│
                                                                    └────────────────┘
```

**Step-by-step:**

| Step | Action | Memory state |
| --- | --- | --- |
| 1 | `image_picker` returns `XFile`; immediately `readAsBytes()` into `SecureBytes` | RAM allocated |
| 2 | Delete reference to temp path; do not store path in State | Path discarded |
| 3 | `InputImage.fromBytes(bytes, metadata)` for ML Kit | Engine reads RAM |
| 4 | `textRecognizer.processImage()` → `recognizedText.text` | String on heap |
| 5 | `secureBytes.zeroize()` in `finally` | RAM wiped |
| 6 | Pass `String` to review screen via in-memory route `arguments` only | No serializing image |

### 6.3 PDF import path (memory-only rasterization)

| Current (violate) | Target |
| --- | --- |
| `PdfDocument.openFile` + write JPEG per page | `PdfDocument.openData(Uint8List)` if API supports, else stream page render to `SecureBytes` |
| Tesseract reads file path | Tesseract byte-mode adapter or ML Kit on `fromBytes` |
| Temp directory `pdf_pages_*` | **Forbidden** — use per-page `SecureBytes` loop |

```dart
// Target pattern — lib/core/ocr/ocr_pipeline.dart

Future<OcrTextResult> extractFromPdfBytes(SecureBytes pdfBytes) async {
  final buffer = pdfBytes; // ownership transfer
  try {
    final document = await PdfDocument.openData(buffer.asUint8List());
    final sb = StringBuffer();
    for (var i = 0; i < min(document.pagesCount, 10); i++) {
      final page = await document.getPage(i + 1);
      final render = await page.render(format: PdfPageImageFormat.raw);
      final frame = SecureBytes.fromUint8List(render!.bytes);
      try {
        sb.writeln(await _recognizeFrame(frame));
      } finally {
        frame.zeroize();
      }
      await page.close();
    }
    await document.close();
    return OcrTextResult(text: OcrCleaner.cleanText(sb.toString()));
  } finally {
    buffer.zeroize();
  }
}
```

### 6.4 Voice input path (future / same contract)

| Stage | Buffer | Persistence |
| --- | --- | --- |
| Microphone capture | Ring buffer of PCM `Int16List` in RAM | None |
| On-device ASR | Model reads streaming chunks | None |
| Transcript string | Dart `String` | SQLCipher only if user saves note |
| Voiceprint / embedding | — | **Forbidden** outside SQLCipher |

```dart
// lib/core/voice/ephemeral_audio_buffer.dart (future)

class EphemeralAudioBuffer {
  final Int16List _pcm;
  bool _zeroed = false;

  void zeroize() {
    if (_zeroed) return;
    for (var i = 0; i < _pcm.length; i++) {
      _pcm[i] = 0;
    }
    _zeroed = true;
  }
}
```

---

## 7. Programming Guidelines — Zeroization & GC

### 7.1 `SecureBytes` wrapper (mandatory for all T4 data)

```dart
// lib/core/ocr/ephemeral_buffer.dart

import 'dart:typed_data';

/// Owns a mutable byte buffer that MUST be zeroized after use.
class SecureBytes {
  SecureBytes._(this._data);
  Uint8List _data;
  bool _released = false;

  factory SecureBytes.fromUint8List(Uint8List source) {
    // Copy into private buffer so caller cannot retain a view
    return SecureBytes._(Uint8List.fromList(source));
  }

  Uint8List asUint8List() {
    _assertAlive();
    return _data;
  }

  void zeroize() {
    if (_released) return;
    for (var i = 0; i < _data.length; i++) {
      _data[i] = 0;
    }
    _released = true;
  }

  void _assertAlive() {
    if (_released) throw StateError('SecureBytes already zeroized');
  }
}
```

### 7.2 Mandatory coding rules

| Rule ID | Requirement |
| --- | --- |
| **ISO-01** | Every function accepting `SecureBytes` must `zeroize()` in a `finally` block or use `using`-style helper |
| **ISO-02** | Never assign T4 buffers to instance fields on `StatefulWidget` State objects |
| **ISO-03** | Never pass file paths derived from camera/gallery into Tesseract; convert to bytes first |
| **ISO-04** | Never log, print, or `debugPrint` byte lengths of frames alongside user identifiers |
| **ISO-05** | After OCR, call `SecureBytes.zeroize()` **before** navigating to next route |
| **ISO-06** | Do not use `compute()` isolate for OCR unless isolate receives copied buffer and zeroizes copy before exit |
| **ISO-07** | Tessdata language models may load from **read-only asset bundle** (`rootBundle.load`); if cached on disk, path must be app-private and contain **no user document data** |
| **ISO-08** | `OcrTextResult.text` is the only OCR artifact eligible for persistence; default policy stores structured parse, not full blob |

### 7.3 `usingSecureBytes` scope helper

```dart
Future<T> usingSecureBytes(
  SecureBytes bytes,
  Future<T> Function(SecureBytes b) action,
) async {
  try {
    return await action(bytes);
  } finally {
    bytes.zeroize();
  }
}
```

### 7.4 Garbage collection guidance

Dart does not guarantee immediate memory reclamation. Zeroization is the **primary** control; GC is secondary.

| Action | When |
| --- | --- |
| `bytes.zeroize()` | Always, in `finally`, before returning from OCR function |
| Null large references | `buffer = null` after zeroize (helps GC root clearing) |
| `await Future.delayed(Duration.zero)` | Optional yield after large buffer release to allow GC cycle between PDF pages |
| Avoid retaining `RecognizedText` | Extract `.text` string, then allow recognizer object to go out of scope |
| `textRecognizer.close()` | Always await engine shutdown (ML Kit) |

**Anti-pattern (current codebase):**

```dart
// lib/core/ocr/ocr_service.dart — NON-COMPLIANT
final inputImage = InputImage.fromFile(imageFile); // disk-backed
```

**Compliant replacement:**

```dart
Future<String> extractTextFromFrame(SecureBytes frame, InputImageMetadata meta) async {
  return usingSecureBytes(frame, (b) async {
    final recognizer = TextRecognizer();
    try {
      final input = InputImage.fromBytes(bytes: b.asUint8List(), metadata: meta);
      final result = await recognizer.processImage(input);
      return OcrCleaner.cleanText(result.text);
    } finally {
      await recognizer.close();
    }
  });
}
```

---

## 8. CHD Persistence Boundary (RAM → SQLCipher)

### 8.1 What may cross the boundary

| Artifact | Cross? | Destination |
| --- | --- | --- |
| Raw JPEG/PNG/PDF bytes | **Never** | — |
| Full raw OCR string | **Opt-in only** | `ocr_text` table, user setting `retain_raw_ocr=false` default |
| Parsed medication name/dose fields | Yes | `medications` table |
| Task title / due time | Yes | `tasks` table |
| Clinical contact phone | Yes | `contacts` table |
| Ephemeral parse DTO in RAM during review | Yes, transient | Discarded after user confirms save |

### 8.2 Data minimization on save

```dart
// lib/core/chd/repositories/discharge_repository.dart (target)

Future<void> saveParsedDischarge(ParsedDischarge dto, {bool retainRawOcr = false}) async {
  await _db.transaction((txn) async {
    await _medRepo.replaceAll(txn, dto.medications);
    await _taskRepo.replaceAll(txn, dto.tasks);
    // ...
    if (retainRawOcr && dto.rawText != null) {
      await txn.insert('ocr_text', {'body': dto.rawText});
    }
    // Explicitly do NOT write raw text when retainRawOcr == false
  });
  dto.zeroizeSensitiveFields(); // clears any held raw text in DTO
}
```

### 8.3 DischargeDataManager migration

`lib/services/discharge_data_manager.dart` is **legacy**. All T3 reads/writes route through `core/chd/repositories/*` backed by SQLCipher. SharedPreferences keys `_keyMedications`, `_keyRawOcrText`, etc. are removed after one-time migration (Roadmap 2.4).

---

## 9. ASCII Diagram — Full Isolation Boundary

```
                         UNTRUSTED / SEMI-TRUSTED ZONE
    ┌────────────────────────────────────────────────────────────────────────┐
    │  image_picker   file_picker   OS Camera Cache   Third-party OCR libs     │
    └───────┬─────────────────┬───────────────────────────┬──────────────────┘
            │ bytes only       │                           │ RAM API only
            ▼                  ▼                           ▼
    ════════════════════════ T4 EPHEMERAL VOLATILE RAM ═══════════════════════
    │  SecureBytes (camera frame)   SecureBytes (PDF page raster)            │
    │  EphemeralAudioBuffer (PCM)    [ NO DISK WRITE — ISO-01..08 enforced ] │
    │                                                                          │
    │   ┌──────────────┐    zeroize()    ┌──────────────┐    zeroize()        │
    │   │ OCR Engine   │ ───────────────►│ OcrCleaner   │ ───────────────►    │
    │   │ MLKit/Tess   │   post-extract  │ text normalize│   post-normalize   │
    │   └──────────────┘                 └──────┬───────┘                     │
    ════════════════════════════════════════════╪══════════════════════════════
                                                │  OcrTextResult (String)
                                                │  ParsedDischarge DTO
                         TRUSTED CHD SANDBOX   ▼
    ┌────────────────────────────────────────────────────────────────────────┐
    │  lib/core/chd/          lib/core/ai/ (local model, filtered I/O)       │
    │  repositories ───────► SQLCipher (rxmind.db) ◄── hardware-derived key  │
    │       ▲                     ▲                                          │
    │       │                     │ lock-safe RAM buffer if device locked    │
    │  screens/tracker/     (see security_storage.md §8)                   │
    │  screens/ocr/review   NO raw frames ever reach this layer              │
    └────────────────────────────────────────────────────────────────────────┘
            ▲                                  │
            │ read-only view models            │ neutral IDs + timestamps
    ┌───────┴──────────────────────────────────┴─────────────────────────────┐
    │  WELLNESS / CONFIG ZONE (T0–T1)                                         │
    │  theme/   main.dart RxMindSettings   NotificationService (neutral copy) │
    │  SharedPreferences: themeMode, notificationTimes, onboardingVersion     │
    │  *** MUST NOT contain medication names, OCR text, or image paths ***    │
    └────────────────────────────────────────────────────────────────────────┘

    ╳ ╳ ╳ FORBIDDEN BOUNDARY ╳ ╳ ╳
    │  Cloud HTTP    Analytics SDKs    SharedPreferences(T3)    Temp JPEG dirs │
    └──────────────────────────────────────────────────────────────────────────┘
```

**Legend:**

- `═══` = hard isolation boundary; memory zeroed at crossing from T4 → T3
- `───►` = allowed one-way data flow
- `╳` = forbidden persistence / transit paths

---

## 10. Notification Isolation (Clinical Decoupling)

Notifications are **semi-trusted**. They interact with OS surfaces visible on the lock screen.

| Field | Allowed | Forbidden |
| --- | --- | --- |
| Title | `"Recovery reminder"` (static) | `"Take Metformin 500mg"` |
| Body | `"You have a scheduled wellness entry"` | Task title from SQLCipher |
| Payload | Encrypted/opaque `task_id` for in-app deep link | Raw CHD JSON |

```dart
// lib/core/notifications/neutral_notification_copy.dart

class NeutralNotificationCopy {
  static const title = 'Recovery reminder';
  static const body = 'You have a scheduled wellness entry';
}
```

The scheduler in `lib/services/notification_service.dart` must be refactored to **remove** `'$taskTitle is due in …'` (current violation).

---

## 11. Third-Party Plugin Hardening

| Plugin | Risk | Mitigation |
| --- | --- | --- |
| `flutter_tesseract_ocr` | Requires file path | Wrap with in-memory temp adapter or replace with ML Kit `fromBytes` |
| `google_ml_kit` | May cache internally | Use `fromBytes`; zeroize input; call `close()` |
| `image_picker` | Writes to cache dir | Read bytes immediately; never store returned path in CHD tier |
| `file_picker` | Copies to cache | Read bytes, zeroize, discard path |
| `pdfx` | Renders to bytes (good) if not written to disk | Use in-memory render loop only |
| `path_provider` | Temp/docs dirs | **Banned** inside `lib/core/ocr/` hot path |

---

## 12. Testing & Verification

| Test ID | Description | Pass criteria |
| --- | --- | --- |
| T-ISO-01 | OCR disk write detector | Mock `File.writeAsBytes`; assert zero invocations during `OcrPipeline.extract` |
| T-ISO-02 | SecureBytes zeroize | After `zeroize()`, all bytes `0x00`; second read throws |
| T-ISO-03 | No raw OCR default | After parse+save, SQLCipher `ocr_text` empty when `retainRawOcr=false` |
| T-ISO-04 | Import boundary | `lib/theme/` does not import `lib/core/chd/` |
| T-ISO-05 | Notification neutrality | Scheduled body equals `NeutralNotificationCopy.body` |
| T-ISO-06 | SharedPreferences CHD grep | No `_keyMedications` / `_keyRawOcrText` after migration |
| T-ISO-07 | PDF page loop | Process 3-page PDF; temp dir file count unchanged |

---

## 13. Implementation Roadmap Cross-Reference

| This section | Roadmap task |
| --- | --- |
| §6 Ephemeral OCR | 2.7 |
| §8 Raw OCR minimization | 2.8 |
| §5 Module firewall | 2.4 (repository migration) |
| §10 Neutral notifications | 4.3 |
| §8 SQLCipher handoff | 2.3–2.5 (`security_storage.md`) |

---

## 14. Revision Log

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| 1.0 | 2026-07-08 | Secure Systems Architect | Initial isolation spec from OCR audit + Compliance §1/§3 |
