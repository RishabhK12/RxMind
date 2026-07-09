# RxMind Privacy Policy

**Effective date:** July 8, 2026  
**Last updated:** July 8, 2026  
**Applies to:** RxMind mobile application (Android and iOS) published by RxMind, Inc. (or the operating legal entity listed in App Store Connect and Google Play Console)

---

## Plain-Language Summary

RxMind is a **personal recovery organizer** that runs on your phone. The health information you enter or scan is stored **on your device only**. We do **not** operate cloud servers that receive, store, or process your Protected Health Information (PHI) or Consumer Health Data (CHD). You choose what to save, you can export a copy, and you can **permanently erase everything** in Settings at any time.

This app is **not a medical device** and does not diagnose, treat, cure, or prevent any medical condition. Always consult a licensed healthcare professional for medical advice.

---

## 1. Who We Are

**Data controller (for app operations):**  
RxMind, Inc.  
[Street address]  
[City, State, ZIP]  
**Privacy contact:** privacy@rxmind.app

This Privacy Policy explains how RxMind handles information when you use our mobile application. It is written to be published as a public web page (HTML) linked from Google Play, the Apple App Store, and inside the app.

---

## 2. Scope of This Policy

This policy covers:

- The RxMind mobile application
- Information processed **locally on your device**
- Our public website and privacy page (non-geofenced, standard HTML)

This policy does **not** cover:

- Websites or services operated by third parties (hospitals, insurers, app stores)
- Your device manufacturer’s or mobile OS provider’s own data practices

---

## 3. Zero-Cloud, Local-Only Architecture

### 3.1 Our commitment

RxMind is designed around a **Zero-Cloud Local-Only Storage** model:

| Principle | What it means for you |
| --- | --- |
| **No developer cloud database** | We do not upload your medications, discharge text, tasks, chat history, or documents to RxMind-operated servers. |
| **No sale of health data** | We do not sell, rent, or license your Consumer Health Data. |
| **No advertising profiles from health screens** | We do not use advertising SDKs, analytics pixels, or cross-app tracking on screens that display your health logs. |
| **On-device processing** | Optical character recognition (OCR), structured parsing, reminders, and optional on-device AI run on your phone. |

### 3.2 HIPAA context (informational)

RxMind is intended for **individual personal use** on a consumer-owned device. Because we do not transmit PHI to RxMind or to third-party cloud processors for storage or inference, **we are not acting as a HIPAA Business Associate** in connection with typical consumer use of the app. This does not change your hospital’s or clinician’s separate obligations. RxMind is **not** a HIPAA-certified platform and is **not** a healthcare provider.

### 3.3 Network use

Production RxMind builds are architected so that **routine health data processing does not require network connectivity**. Limited network access may exist only for non-health functions you explicitly initiate (for example, opening an external link or checking for optional app updates, if enabled in a future release). **Health data is not transmitted to our servers as part of core app operation.**

---

## 4. Information We Process

### 4.1 Categories of Consumer Health Data (CHD)

Depending on how you use RxMind, locally processed information may include:

| Category | Examples | Source |
| --- | --- | --- |
| **Recovery documents** | Discharge paperwork text you scan or import | You (camera, photo library, file picker) |
| **Medications** | Names, schedules, notes you approve | You / OCR-assisted extraction you review |
| **Tasks & instructions** | Wound care, therapy, dietary notes | You / OCR-assisted extraction you review |
| **Appointments & contacts** | Clinician names, phone numbers | You / manual entry / OS contact picker (single selection) |
| **Profile & scheduling** | Display name, bedtime, wake time (optional) | You |
| **AI interactions** | Questions and on-device AI responses | You |
| **Compliance logs** | Task completion history | Generated on-device from your use |

Under laws such as the **Washington My Health My Data Act (WA MHMDA)** and **Nevada SB 370**, this information is **Consumer Health Data** because it relates to your health, bodily functions, symptoms, or healthcare services.

### 4.2 Information we do not collect

We do **not** require an account, email, or phone number to use RxMind. We do **not** collect:

- Government identifiers
- Payment card data (if the app is free)
- Precise geolocation for core features (see Section 8)
- Full device contact lists
- Advertising identifiers tied to health log views

### 4.3 Ephemeral data (not retained)

Certain sensitive inputs exist only briefly in **volatile device memory (RAM)** and are **not written to persistent storage**:

| Input type | RAM lifecycle | Persistent copy |
| --- | --- | --- |
| **Camera frames** (discharge photos) | Loaded into memory → OCR extracts text → **memory zeroed** | Only user-reviewed **text fields** you choose to save (not raw images by default) |
| **PDF page renders** | Rendered in memory per page → OCR → **memory zeroed** | Structured fields you confirm |
| **Voice audio** (if enabled in a future release) | Streamed to on-device speech recognition → **buffer zeroed** | Transcript text only if you save it |

Raw prescription images, unredacted frame buffers, and voice waveforms **do not** remain on disk after processing completes, except where you explicitly export or share content through your device’s share sheet.

---

## 5. How We Use Information

We use on-device information solely to:

- Display and organize your recovery plan
- Schedule **local** reminders you configure
- Run **on-device** text extraction and optional AI clarification
- Generate PDF exports **you request**
- Improve reliability through **non-health** technical logs that never leave the device (crash diagnostics without health payload, if implemented)

We do **not** use your Consumer Health Data for:

- Targeted advertising
- Profiling for marketing
- Automated clinical diagnosis or treatment decisions
- Selling or licensing to data brokers

---

## 6. Legal Bases and Consent

### 6.1 Explicit opt-in for Consumer Health Data

Before you scan, import, or save health-related information, RxMind presents a **standalone consent screen** separate from general Terms of Service. The screen explains:

- What categories of health data are collected
- That data stays on your device
- How to withdraw consent (Section 12)

You must tap **I Consent** before health data features activate.

### 6.2 Non-health preferences

Theme, notification timing preferences, and similar non-clinical settings are processed under **legitimate interest** / **contract necessity** to operate the app you downloaded.

---

## 7. Local Storage and Security Architecture

### 7.1 Encrypted database (data at rest)

Consumer Health Data you save is stored in an encrypted local database (**SQLCipher**) on your device, not in plain-text app preferences.

| Layer | Android | iOS |
| --- | --- | --- |
| **Hardware root key** | 256-bit AES key in **Android Keystore**, StrongBox-backed when the device supports it | P-256 key in **Secure Enclave** (`kSecAttrTokenIDSecureEnclave`) |
| **Database key derivation** | PBKDF2-HMAC-SHA256, ≥100,000 iterations, unique salt | ECDH-based derivation on Secure Enclave + PBKDF2 |
| **Encryption** | SQLCipher full-database encryption | SQLCipher full-database encryption |
| **Access policy** | Key use may require device PIN/biometric unlock | `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` |

Cryptographic keys **never leave** the secure hardware boundary during normal operation. If the device is locked, RxMind may queue non-sensitive write operations in volatile memory until you unlock the device.

### 7.2 Backup restrictions

- **Android:** Application backup via Google backup / ADB is disabled (`allowBackup=false`).
- **iOS:** Database directories are marked **excluded from iCloud backup** where supported.

You remain responsible for device-level backups you configure outside RxMind (e.g., full phone backups to a personal computer).

### 7.3 Isolation from non-health data

Non-clinical configuration (theme, notification lead times) is stored separately from clinical tables. Lock-screen notifications use **generic text** and do not display medication names or diagnoses.

---

## 8. Location, Tracking, and State Privacy Laws

### 8.1 No routine location tracking

RxMind **does not** collect precise geolocation as part of core recovery features. We do **not** build advertising profiles from your health activities.

### 8.2 Washington My Health My Data Act (WA MHMDA)

For Washington residents, we affirm:

| MHMDA topic | RxMind practice |
| --- | --- |
| **Consent** | Standalone opt-in before CHD collection (Section 6) |
| **Sale / sharing** | We do not sell or share Consumer Health Data |
| **Geofencing near clinics** | We do **not** collect location within **2,000 feet** of hospitals or clinics. If optional location features are ever offered, they include a programmatic exclusion zone and remain off by default. |
| **Withdrawal of consent** | **Erase All My Data** (Section 12) immediately stops processing and deletes local CHD |
| **Private right of action** | We design the app to meet MHMDA technical requirements; violations may carry statutory damages under Washington law |

### 8.3 Nevada SB 370 (Consumer Health Data Privacy)

For Nevada consumers, we affirm:

- We are a **data controller** only for app operations metadata (e.g., support emails you send us), not for on-device CHD stored solely on your phone.
- We **do not sell** Consumer Health Data.
- You may **withdraw consent** and delete data via Section 12.

### 8.4 Other U.S. state laws

Residents of Colorado, Connecticut, Virginia, and other states with consumer health or privacy laws may contact **privacy@rxmind.app** to exercise applicable rights. Because health data remains on your device, many requests are fulfilled most quickly through **in-app erasure**.

### 8.5 No web tracking on health pages

Our public privacy policy page is a **static HTML document** without geofencing, editing gates, or embedded third-party trackers that fingerprint visitors.

---

## 9. On-Device Artificial Intelligence

If you enable AI features:

- Inference runs **on your device** using a quantized local model (production architecture).
- AI is labeled as **automated**, not human clinical advice.
- Safety filters block emergency medical triage and strip prescription-like outputs when possible.
- You may **report** any AI output from within the chat interface; reports are stored locally unless you contact support.

AI does **not** diagnose conditions, recommend medication changes, or replace emergency services. If you describe an emergency, the app directs you to **911** or **988**.

---

## 10. Sharing and Disclosure

### 10.1 We do not share Consumer Health Data with third parties

RxMind does **not** disclose your on-device Consumer Health Data to:

- Cloud AI providers
- Analytics vendors
- Advertising networks
- Data brokers

### 10.2 User-initiated sharing only

You may export a PDF or use your device’s share sheet to send information to your clinician or family. **You control** those transmissions.

### 10.3 OS contact picker

If you add a clinician from your address book, the operating system shows a **single-contact picker**. RxMind receives only the contact you select—not your full contacts database.

### 10.4 Legal process

Because we do not hold your on-device health database in the cloud, we generally **cannot** produce your recovery logs in response to legal requests. We may disclose limited account or support metadata if required by valid legal process directed at RxMind as a company.

---

## 11. Data Retention

| Data type | Retention |
| --- | --- |
| Consumer Health Data on device | Until you delete it, erase all data, or uninstall the app |
| Ephemeral camera/audio buffers | Seconds — destroyed after OCR/ASR completes |
| Consent records | Until erasure or uninstall |
| Support emails you send us | Up to [24] months, then deleted |

---

## 12. Your Rights — Access, Export, and Permanent Erasure

### 12.1 Access and portability

You can view all stored recovery information inside the app. You may **export** a PDF summary from Settings for your personal records.

### 12.2 Withdraw consent and erase all data

You may **withdraw consent** and permanently delete Consumer Health Data at any time:

**In-app permanent erasure**

1. Open **Settings**
2. Tap **Delete All Data**
3. Type **DELETE** to confirm
4. RxMind will:
   - Cancel scheduled notifications
   - Close the encrypted database
   - **Overwrite and delete** local database files (multi-pass secure wipe)
   - Remove encryption keys from Android Keystore / iOS Secure Enclave
   - Clear secure storage, caches, and temporary files
   - Return you to the first-run disclaimer screen

After completion, **no Consumer Health Data remains recoverable through the app**. Uninstalling RxMind also removes app sandbox data subject to OS behavior.

### 12.3 No retention after erasure

We do not retain copies of your on-device Consumer Health Data after you execute **Delete All Data**, because we do not host that data on our servers.

### 12.4 Questions and requests

Email **privacy@rxmind.app** with the subject line **Privacy Request**. We respond within **45 days** (or the timeframe required by your state law, if shorter).

---

## 13. Permissions

| Permission | Purpose | Health data leaves device? |
| --- | --- | --- |
| **Camera** (optional) | Photograph discharge documents for on-device OCR | No |
| **Photo library / files** (optional) | Import a document you select | No |
| **Notifications** (optional) | Local recovery reminders (generic text) | No |
| **Exact alarms** (Android, optional) | Timely reminders you schedule | No |
| **Contacts** | **Not requested** — single-contact OS picker only | No |
| **Location** | **Not collected** in default configuration | No |

You may deny permissions and still use non-dependent features. We show an **in-context disclosure** before each system permission prompt explaining local-only storage.

---

## 14. Children’s Privacy

RxMind is **not directed to children under 13** (or 16 where applicable). We do not knowingly collect Consumer Health Data from children. If you believe a child has provided information, contact **privacy@rxmind.app** and uninstall the app from the child’s device.

---

## 15. International Users

RxMind is currently offered in the United States. If you use RxMind outside the U.S., your data still remains on your device under the architecture described here. Local laws may grant additional rights.

---

## 16. Changes to This Policy

We may update this Privacy Policy to reflect product, legal, or regulatory changes. We will:

- Update the **Last updated** date above
- Provide notice inside the app for material changes
- Post the revised policy at the same public URL

Continued use after the effective date constitutes acceptance of the updated policy.

---

## 17. Contact Us

**RxMind Privacy Team**  
Email: privacy@rxmind.app  
Web: https://[your-org].github.io/RxMind/privacy.html

For app support (non-legal): support@rxmind.app

---

## Appendix A — Definitions

| Term | Meaning |
| --- | --- |
| **Consumer Health Data (CHD)** | Personal information linked or reasonably linkable to a consumer that identifies past, present, or future physical or mental health status, as defined under WA MHMDA, Nevada SB 370, and similar laws. |
| **PHI** | Protected Health Information as defined under HIPAA, which RxMind does not store on behalf of covered entities. |
| **Zero-Cloud Local-Only** | Architecture where health data processing and storage occur on the user’s device without transmission to RxMind-operated cloud infrastructure. |
| **Ephemeral processing** | Short-lived RAM-only handling of raw images or audio with explicit memory zeroing after text extraction. |

---

## Appendix B — HTML Deployment Notes (Internal)

When publishing to GitHub Pages:

- Convert this document to `docs/site/privacy.html`
- Use semantic HTML5 (`<main>`, `<h1>`–`<h3>`, `<section>`)
- No login wall, no geofencing, no PDF-only distribution
- Link from Play Console, App Store Connect, and in-app Settings → Privacy Policy
- Replace bracketed placeholders `[Street address]`, `[your-org]` before go-live

---

*This document is a product-aligned privacy policy draft prepared for RxMind’s on-device architecture. It is not legal advice. Have qualified counsel review before publication.*
