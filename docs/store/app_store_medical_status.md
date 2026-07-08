# App Store Medical Status Declaration — Draft Inputs

**App:** RxMind (`com.rxmind.app`)  
**Last updated:** 2026-07-08

## Regulated medical device?

**No.** RxMind is a personal wellness recovery organizer, not a Software as a Medical Device (SaMD).

## App Store Connect — Health & Fitness

- **Primary purpose:** Help users log, organize, and remind recovery tasks from discharge documents
- **Not intended for:** Diagnosis, treatment decisions, dosing guidance, or emergency triage

## In-app disclaimer

Verbatim first paragraph shown on cold start before health data entry:

> This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Consult a licensed healthcare professional for medical advice.

## HealthKit

- **Not used.** `com.apple.developer.healthkit` absent from entitlements.

## Privacy Nutrition Labels (summary)

- Health & Fitness data: collected, linked to user, **not** used for tracking
- Data not collected off-device for core app operation

## Background modes

- Reminder rescheduling only (Phase 4); no location or HealthKit background access in v1
