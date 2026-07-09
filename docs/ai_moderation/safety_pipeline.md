# RxMind Local AI Safety Pipeline

**Document version:** 1.0  
**Last updated:** 2026-07-08  
**Status:** Target specification (implementation tracked in `docs/roadmap.md` Phase 3)  
**Compliance basis:** *Mobile Health App Compliance 2026* — Section 2 (Generative AI & Healthcare Guidance)  
**Related:** `docs/architecture/data_isolation.md`, `docs/architecture/security_storage.md`

---

## 1. Purpose & Scope

This document defines the **multi-stage, on-device generative AI moderation pipeline** for RxMind. Every user query and every model output must pass through local safety controls **before** inference and **before** UI render. No cloud moderation dependency is permitted for CHD-bearing sessions.

**Goals:**

- Block acute clinical crisis queries **prior** to local LLM execution
- Strip or drop prescription-like and dosing outputs **after** inference
- Provide mandatory per-message **Report Output** affordances
- Enforce a wellness-only persona: data parsing and educational summarization — never diagnostic decision-making

---

## 2. Current State — Safety Gaps

| Component | File | Current behavior | Violation |
| --- | --- | --- | --- |
| Cloud inference | `lib/services/ai/gemini_backend_client.dart` | HTTP POST to Cloudflare Worker → Gemini | CHD leaves device; no local moderation boundary |
| Chat service | `lib/screens/ai/gemini_api_service.dart` | Direct `generateText()` with no input/output filters | No pre/post safety layers |
| System prompt | `lib/screens/ai/ai_chat_screen.dart` | Claims "HIPAA-compliant medical assistant"; authorizes dosing answers | HAI-DEF prohibited use; SaMD risk |
| Parse prompt | `lib/screens/ocr/parsing_progress.dart` | "Medical data extraction specialist" via cloud Gemini | Clinical reasoning persona |
| Parser | `lib/core/ai/ai_parser.dart` | JSON key validation only | No prescription/dose strip |
| Chat UI | `lib/screens/ai/ai_chat_screen.dart` | Renders raw model output; no report flag | Google Play AI policy gap |
| Rate limit | `lib/core/ai/rate_limiter.dart` | SharedPreferences counter | No safety routing |

**Target:** Replace `GeminiBackendClient` with `LocalAiService` wrapped by `SafetyPipeline` (this document).

---

## 3. Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RxMind SafetyPipeline.run()                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
    User input ───────────────────────┤
                                      ▼
                    ┌─────────────────────────────────────┐
                    │  STAGE 0: AI Disclosure Gate         │
                    │  (first message per session)        │
                    └─────────────────┬───────────────────┘
                                      │ ack required
                                      ▼
                    ┌─────────────────────────────────────┐
                    │  STAGE 1: SafetyInputFilter         │
                    │  (regex + keyword crisis detection) │
                    └─────────────────┬───────────────────┘
                          blocked     │ allowed
                    ┌─────────────────┴───────────────────┐
                    ▼                                     ▼
     ┌──────────────────────────┐          ┌──────────────────────────┐
     │ EmergencyStaticScreen    │          │  STAGE 2: LocalAiService │
     │ (no LLM call)            │          │  (on-device quantized)   │
     └──────────────────────────┘          └────────────┬─────────────┘
                                                         │
                                                         ▼
                                          ┌──────────────────────────┐
                                          │  STAGE 3: SafetyOutput   │
                                          │  Filter (prescription    │
                                          │  strip + dose drop)      │
                                          └────────────┬─────────────┘
                                                       │
                                                       ▼
                                          ┌──────────────────────────┐
                                          │  STAGE 4: Render bubble  │
                                          │  + Report Output icon    │
                                          └──────────────────────────┘
```

### 3.1 Module layout (target)

```
lib/core/ai/
├── safety_pipeline.dart          # Orchestrator
├── safety_input_filter.dart      # Stage 1
├── safety_output_filter.dart     # Stage 3
├── safety_patterns.dart          # Regex arrays (this doc §5–6)
├── safety_result.dart            # Enums: allowed, emergency, stripped
├── local_ai_service.dart         # Stage 2 (on-device only)
├── ai_system_prompts.dart        # Approved prompt constants
├── ai_report_store.dart          # Local report audit log
└── chat_manager.dart             # Persists filtered messages only
```

---

## 4. Stage 0 — AI Transparency Gate

**Compliance:** EU AI Act Art. 50; Play Console AI questionnaire.

Before the first user message in any chat session:

1. Display blocking banner: *"You are interacting with an automated on-device AI system, not a human clinician."*
2. Require tap **I Understand**; persist `ai_disclosure_ack` on session row in SQLCipher.
3. App bar shows persistent chip: `AI · On-Device`.

**No bypass:** `_sendMessage()` returns early if disclosure not acknowledged.

---

## 5. Stage 1 — Pre-Inference Emergency Interception

### 5.1 Behavior

`SafetyInputFilter.evaluate(String userText)` runs **synchronously** on the UI isolate before any `LocalAiService.generate()` call.

| Result | Action |
| --- | --- |
| `SafetyInputResult.allowed` | Proceed to Stage 2 |
| `SafetyInputResult.emergency(EmergencyCategory)` | **Skip LLM**; push `EmergencyStaticScreen` full-screen route |
| `SafetyInputResult.rateLimited` | Show static message; no LLM |

On emergency: user message is **not** sent to the model. Optionally log `emergency_trigger_count` locally (category only, not full query text, unless user opts into support logging).

### 5.2 Normalization (pre-regex)

```dart
String normalizeForSafety(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^\w\s\.\,\!\?\-]'), '') // strip emoji/zero-width
      .trim();
}
```

### 5.3 Emergency pattern arrays (copy-pasteable)

```dart
// lib/core/ai/safety_patterns.dart

class SafetyPatterns {
  /// Case-insensitive; applied after normalizeForSafety().

  // ── SUICIDE / SELF-HARM ──────────────────────────────────────────────
  static final List<RegExp> suicideSelfHarm = [
    RegExp(r'\b(kill|hurt|harm|end)\s+(my)?self\b'),
    RegExp(r'\bsuicid(e|al)\b'),
    RegExp(r'\bwant\s+to\s+die\b'),
    RegExp(r"\bdon'?t\s+want\s+to\s+live\b"),
    RegExp(r'\bself[\s-]?harm\b'),
    RegExp(r'\bcut(ting)?\s+myself\b'),
    RegExp(r'\b988\b'), // may co-occur; paired with ideation patterns in scorer
    RegExp(r'\bno\s+reason\s+to\s+live\b'),
  ];

  // ── OVERDOSE / POISONING ─────────────────────────────────────────────
  static final List<RegExp> overdosePoisoning = [
    RegExp(r'\boverdose(d|ing)?\b'),
    RegExp(r'\btoo\s+many\s+(pills|tablets|meds|medications)\b'),
    RegExp(r'\btook\s+all\s+(my|the)\s+(pills|meds)\b'),
    RegExp(r'\bpoison(ed|ing)?\b'),
    RegExp(r'\bswallowed\s+(a\s+)?bottle\b'),
  ];

  // ── CARDIAC / STROKE (ACUTE) ─────────────────────────────────────────
  static final List<RegExp> acuteCardiacStroke = [
    RegExp(r'\bheart\s+attack\b'),
    RegExp(r'\bchest\s+pain\b'),
    RegExp(r"\bcan'?t\s+breathe\b"),
    RegExp(r'\bstroke\b'),
    RegExp(r'\bface\s+drooping\b'),
    RegExp(r'\barm\s+weakness\b'),
    RegExp(r'\bslurred\s+speech\b'),
    RegExp(r'\bpassed\s+out\b'),
    RegExp(r'\bunconscious\b'),
  ];

  // ── ACUTE PAIN / BLEEDING ────────────────────────────────────────────
  static final List<RegExp> acutePainBleeding = [
    RegExp(r'\bsevere\s+(pain|bleeding|headache)\b'),
    RegExp(r'\bworst\s+headache\b'),
    RegExp(r"\bcan'?t\s+stop\s+bleeding\b"),
    RegExp(r'\bvomiting\s+blood\b'),
    RegExp(r'\bthoughts\s+of\s+hurting\s+others\b'),
  ];

  // ── EXPLICIT EMERGENCY INTENT ────────────────────────────────────────
  static final List<RegExp> emergencyIntent = [
    RegExp(r'\b(call\s+)?911\b'),
    RegExp(r'\bemergency\s+room\b'),
    RegExp(r'\b(er|ed)\s+now\b'),
    RegExp(r'\bneed\s+ambulance\b'),
    RegExp(r'\blife\s+threatening\b'),
  ];
}
```

### 5.4 Scoring logic

```dart
enum EmergencyCategory {
  suicideSelfHarm,
  overdosePoisoning,
  acuteCardiacStroke,
  acutePainBleeding,
  emergencyIntent,
}

class SafetyInputFilter {
  static SafetyInputResult evaluate(String rawUserText) {
    final text = normalizeForSafety(rawUserText);
    if (text.isEmpty) return SafetyInputResult.allowed();

    final hits = <EmergencyCategory>[];

    if (_anyMatch(text, SafetyPatterns.suicideSelfHarm)) {
      hits.add(EmergencyCategory.suicideSelfHarm);
    }
    if (_anyMatch(text, SafetyPatterns.overdosePoisoning)) {
      hits.add(EmergencyCategory.overdosePoisoning);
    }
    if (_anyMatch(text, SafetyPatterns.acuteCardiacStroke)) {
      hits.add(EmergencyCategory.acuteCardiacStroke);
    }
    if (_anyMatch(text, SafetyPatterns.acutePainBleeding)) {
      hits.add(EmergencyCategory.acutePainBleeding);
    }
    // emergencyIntent alone triggers only if paired with clinical symptom OR standalone 911
    if (_anyMatch(text, SafetyPatterns.emergencyIntent)) {
      if (hits.isNotEmpty || RegExp(r'\b911\b').hasMatch(text)) {
        hits.add(EmergencyCategory.emergencyIntent);
      }
    }

    if (hits.isNotEmpty) {
      return SafetyInputResult.emergency(primary: hits.first, all: hits);
    }
    return SafetyInputResult.allowed();
  }

  static bool _anyMatch(String text, List<RegExp> patterns) {
    for (final p in patterns) {
      if (p.hasMatch(text)) return true;
    }
    return false;
  }
}
```

### 5.5 Emergency fallback UI

**Route:** `EmergencyStaticScreen` replaces the chat body (full-screen `Scaffold`, not a dialog).

**Layout:**

```
┌────────────────────────────────────────┐
│  ⚠  Immediate help is available        │
│                                        │
│  RxMind cannot handle emergencies.     │
│  If you are in danger, call now:       │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │  📞 911  (Emergency Services)    │  │  ← url_launcher tel:911
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │  📞 988  (Suicide & Crisis Lifeline)│
│  └──────────────────────────────────┘  │
│                                        │
│  Your saved clinical contacts:         │
│  • Dr. Smith — (555) 010-0200         │  ← from SQLCipher contacts
│                                        │
│  [ Return to Chat ]  (secondary)       │
└────────────────────────────────────────┘
```

**Rules:**

- No LLM-generated text on this screen — static strings from `lib/core/ai/emergency_resources.dart` only
- `Return to Chat` does not re-send the blocked message
- Screen reader: `Semantics(header: true)` on title; each phone button `label: Call 911`

```dart
// lib/screens/ai/emergency_static_screen.dart (sketch)

class EmergencyStaticScreen extends StatelessWidget {
  final EmergencyCategory category;
  const EmergencyStaticScreen({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get help now')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'RxMind is a wellness organizer, not an emergency service. '
            'If you may be in immediate danger, contact emergency services.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          _EmergencyCallTile(number: '911', label: 'Emergency Services'),
          _EmergencyCallTile(number: '988', label: 'Suicide & Crisis Lifeline'),
          // ... ClinicalContactList from repository
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Return to Chat'),
          ),
        ],
      ),
    );
  }
}
```

**Integration in chat:**

```dart
void _sendMessage() async {
  final text = _controller.text.trim();
  if (text.isEmpty) return;

  final inputResult = SafetyInputFilter.evaluate(text);
  if (inputResult.isEmergency) {
    _controller.clear();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EmergencyStaticScreen(category: inputResult.primary!),
      ),
    );
    return; // NO LLM CALL
  }

  // ... proceed to LocalAiService
}
```

---

## 6. Stage 2 — On-Device Inference (Persona-Locked)

### 6.1 Inference parameters (local model)

| Parameter | Chat clarification | Discharge JSON parse |
| --- | --- | --- |
| `temperature` | `0.2` | `0.1` |
| `topK` | `20` | `10` |
| `topP` | `0.85` | `0.80` |
| `maxOutputTokens` | `512` | `2048` |
| `stopSequences` | `["\n\nUSER:", "=== "]` | `[]` |

**Network:** `SafetyPipeline` asserts `!await hasNetworkPath()` in debug builds during CHD sessions.

### 6.2 Approved system prompts (AI Studio / local template)

#### Chat — wellness clarification (replaces `ai_chat_screen.dart` prompt)

```
You are RxMind Wellness Clarifier, an on-device automated assistant inside a personal recovery organizer app.

IDENTITY & LIMITS (MANDATORY):
- You are NOT a doctor, nurse, pharmacist, or emergency service.
- You do NOT diagnose conditions, interpret lab results, or determine if symptoms are serious.
- You do NOT recommend medication changes, starting/stopping drugs, or specific dosages.
- You do NOT produce prescriptions, medical orders, or treatment plans.
- If asked for diagnosis or dosing decisions, refuse briefly and direct the user to their clinician.

ALLOWED TASKS:
- Rephrase discharge instructions the user already uploaded, in plain language.
- Summarize tasks, appointments, and medication NAMES and schedules already stored in the app (without changing doses).
- Define general medical terms educationally (e.g., "hypertension means high blood pressure").
- Help navigate app features (tasks, reminders, contacts).

STYLE:
- Short paragraphs, 8th-grade reading level.
- When uncertain, say "I am not sure" and suggest contacting their care team.
- Never claim HIPAA compliance or clinical authority.

SAFETY:
- If the user describes an emergency, tell them to call 911 or 988 immediately and do not continue coaching.
```

#### Parse — structured extraction only (replaces `parsing_progress.dart` prompt)

```
You are RxMind Document Organizer, an on-device data parser.

TASK:
Extract structured fields already present in the user's discharge text into JSON. Copy facts; do not infer new clinical conclusions.

STRICT RULES:
- Output ONLY valid JSON matching the provided schema.
- Do NOT add medications, doses, or diagnoses not explicitly in the source text.
- Do NOT recommend treatments or change dosing.
- If a field is missing, use null or empty array — never guess.
- "dose" and "frequency" fields must be verbatim excerpts from the document.

FORBIDDEN OUTPUT:
- Prose explanations, markdown, clinical advice, or differential diagnoses.
```

### 6.3 Banned prompt fragments (CI grep test)

```dart
const bannedPromptFragments = [
  'HIPAA-compliant',
  'medical assistant',
  'medical data extraction specialist',
  'authorized to handle PHI',
  'answer questions about dosages',
  'diagnose',
  'treatment plan',
  'clinical decision',
];
```

---

## 7. Stage 3 — Post-Inference Prescriptive Parsing

### 7.1 Behavior

`SafetyOutputFilter.sanitize(String modelText)` returns `SafetyOutputResult`:

| Field | Type | Description |
| --- | --- | --- |
| `displayText` | `String` | Safe text for UI (may be shortened) |
| `action` | `OutputSanitizeAction` | `pass`, `strip`, `dropEntire` |
| `strippedSpans` | `List<Range>` | Audit metadata (offset/length only, not content in production logs) |
| `flags` | `Set<OutputFlag>` | `prescriptionSyntax`, `dosingDirective`, `diagnosticAssertion`, `brandDoseCombo` |

| `action` | When |
| --- | --- |
| `pass` | No rule hits |
| `strip` | Remove matching lines/spans; show remainder + fixed disclaimer |
| `dropEntire` | ≥3 dosing hits OR full Rx block detected OR diagnostic assertion with treatment directive |

**Fixed disclaimer appended after strip:**

```
[Some clinical instruction language was removed for your safety. Follow your discharge paperwork and contact your clinician.]
```

### 7.2 Prescription & dosing pattern arrays (copy-pasteable)

```dart
class PrescriptivePatterns {
  // ── RX HEADER / FORMAL PRESCRIPTION BLOCKS ───────────────────────────
  static final List<RegExp> prescriptionHeaders = [
    RegExp(r'(?i)\bRx\s*[:#]?\s*\d*'),
    RegExp(r'(?i)\bDISPENSE\s*[:#]'),
    RegExp(r'(?i)\bSIG\s*[:#]'),
    RegExp(r'(?i)\bNDC\s*[:#]?\s*\d'),
    RegExp(r'(?i)\bDEA\s*[:#]?\s*[A-Z]{2}\d'),
  ];

  // ── DOSING DIRECTIVES ────────────────────────────────────────────────
  static final List<RegExp> dosingDirectives = [
    RegExp(r'(?i)\b(take|use|apply|inject|inhale)\s+\d+(\.\d+)?\s*(mg|mcg|g|ml|mL|units?|tablets?|capsules?|puffs?|drops?)\b'),
    RegExp(r'(?i)\b\d+(\.\d+)?\s*(mg|mcg|g|ml|mL)\s*(po|by mouth|orally|twice|daily|bid|tid|qid|prn|every)\b'),
    RegExp(r'(?i)\b(increase|decrease|double|halve|titrate)\s+(the\s+)?(dose|dosage|medication)\b'),
    RegExp(r'(?i)\b(start|stop|discontinue|switch)\s+(taking\s+)?(your\s+)?(medication|meds|prescription)\b'),
    RegExp(r'(?i)\b(max(imum)?\s+daily\s+dose)\b'),
  ];

  // ── BRAND + DOSE COMBO (common false clinical orders) ────────────────
  static final List<RegExp> brandDoseCombo = [
    RegExp(r'(?i)\b(lipitor|metformin|lisinopril|amlodipine|omeprazole|atorvastatin|levothyroxine|gabapentin|hydrocodone|oxycodone|albuterol|insulin)\b.{0,40}\b\d+\s*(mg|mcg|units?)\b'),
    RegExp(r'(?i)\b\d+\s*(mg|mcg|units?)\b.{0,40}\b(lipitor|metformin|lisinopril|amlodipine|omeprazole|atorvastatin)\b'),
  ];

  // ── DIAGNOSTIC ASSERTIONS + TREATMENT ────────────────────────────────
  static final List<RegExp> diagnosticAssertions = [
    RegExp(r'(?i)\byou\s+(have|likely\s+have|probably\s+have)\s+[a-z]+(\s+[a-z]+){0,4}\b'),
    RegExp(r'(?i)\bthis\s+(is|sounds\s+like)\s+(a\s+)?(heart\s+attack|stroke|infection|sepsis|diabetes)\b'),
    RegExp(r'(?i)\bi\s+diagnose\b'),
    RegExp(r'(?i)\byour\s+condition\s+is\b'),
  ];

  // ── IMPERATIVE CLINICAL ORDERS ───────────────────────────────────────
  static final List<RegExp> clinicalOrders = [
    RegExp(r'(?i)\b(go\s+to|visit)\s+(the\s+)?(er|emergency)\b'),
    RegExp(r'(?i)\byou\s+should\s+(take|start|begin|use)\s+\d'),
    RegExp(r'(?i)\bprescribe(d|s)?\s+(you|a)\b'),
  ];
}
```

### 7.3 Sanitizer implementation

```dart
enum OutputSanitizeAction { pass, strip, dropEntire }

class SafetyOutputFilter {
  static const _disclaimer =
      '\n\n_[Some clinical instruction language was removed for your safety. '
      'Follow your discharge paperwork and contact your clinician.]_';

  static SafetyOutputResult sanitize(String raw) {
    if (raw.trim().isEmpty) {
      return SafetyOutputResult.pass('');
    }

    var hitCount = 0;
    final flags = <OutputFlag>{};
    final lines = raw.split('\n');
    final kept = <String>[];

    for (final line in lines) {
      final severity = _scoreLine(line);
      hitCount += severity.hits;
      flags.addAll(severity.flags);

      if (severity.hits == 0) {
        kept.add(line);
      } else if (severity.hits == 1) {
        kept.add('_[line removed]_');
      } else {
        kept.clear();
        return SafetyOutputResult.dropEntire(
          displayText:
              'I cannot provide that type of clinical instruction. '
              'Please refer to your discharge documents or contact your care team.',
          flags: flags,
        );
      }
    }

    if (hitCount == 0) {
      return SafetyOutputResult.pass(raw);
    }

    final display = kept.join('\n').trim();
    if (display.isEmpty) {
      return SafetyOutputResult.dropEntire(
        displayText:
            'I cannot provide that type of clinical instruction. '
            'Please refer to your discharge documents or contact your care team.',
        flags: flags,
      );
    }

    return SafetyOutputResult.strip(
      displayText: display + _disclaimer,
      flags: flags,
    );
  }

  static _LineScore _scoreLine(String line) {
    var hits = 0;
    final flags = <OutputFlag>{};

    void check(List<RegExp> patterns, OutputFlag flag, {int weight = 1}) {
      for (final p in patterns) {
        if (p.hasMatch(line)) {
          hits += weight;
          flags.add(flag);
        }
      }
    }

    check(PrescriptivePatterns.prescriptionHeaders, OutputFlag.prescriptionSyntax, weight: 2);
    check(PrescriptivePatterns.dosingDirectives, OutputFlag.dosingDirective);
    check(PrescriptivePatterns.brandDoseCombo, OutputFlag.brandDoseCombo, weight: 2);
    check(PrescriptivePatterns.diagnosticAssertions, OutputFlag.diagnosticAssertion, weight: 2);
    check(PrescriptivePatterns.clinicalOrders, OutputFlag.dosingDirective);

    return _LineScore(hits: hits, flags: flags);
  }
}
```

### 7.4 Parse-mode JSON hardening

For `parsing_progress.dart` JSON outputs, run **additional** validation after `AiParser.validateJson`:

```dart
Map<String, dynamic> sanitizeParsedJson(Map<String, dynamic> json) {
  final meds = (json['medications'] as List?) ?? [];
  for (final m in meds) {
    final dose = (m['dose'] ?? m['dosage'] ?? '').toString();
    // Reject model-invented dosing not in source: flag if dose matches directive regex
    if (PrescriptivePatterns.dosingDirectives.any((p) => p.hasMatch(dose))) {
      // Keep only if OCR source verification passes (future: span alignment)
      m['_safety_review'] = true;
    }
  }
  return json;
}
```

---

## 8. Stage 4 — Content Reporting UI

### 8.1 Requirement

**Every assistant message bubble** must expose a persistent **Report Output** control (Google Play AI policy §2).

### 8.2 Widget layout

```
┌─────────────────────────────────────────────────────┐
│  Assistant message text (Markdown, selectable)      │
│  ...filtered displayText...                         │
├─────────────────────────────────────────────────────┤
│  🤖 On-device AI          [ ⚑ Report Output ]      │
└─────────────────────────────────────────────────────┘
```

| Element | Spec |
| --- | --- |
| Report button | `Icons.flag_outlined`, min 48×48 dp touch target |
| Semantics | `label: Report Output`, `button: true` |
| Position | Bottom-right of assistant bubble footer row |
| Visibility | Always visible without scrolling or long-press |
| User messages | No report button (user-authored) |

### 8.3 Report flow

```dart
// lib/screens/ai/report_output_sheet.dart

Future<void> showReportOutputSheet({
  required BuildContext context,
  required String messageId,
  required String messageHash, // SHA-256 of displayText, not raw model output
}) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => ReportOutputSheet(
      reasons: const [
        ReportReason.incorrectHealthInfo,
        ReportReason.unsafeMedicalAdvice,
        ReportReason.offTopic,
        ReportReason.other,
      ],
      onSubmit: (reason, optionalNote) async {
        await AiReportStore.insert(
          messageId: messageId,
          messageHash: messageHash,
          reason: reason,
          note: optionalNote?.trim().isEmpty == true ? null : optionalNote,
          createdAt: DateTime.now().toUtc(),
        );
      },
    ),
  );
}
```

**Storage (`ai_reports` SQLCipher table):**

| Column | Type | Notes |
| --- | --- | --- |
| `id` | TEXT PK | UUID |
| `message_id` | TEXT | Chat message FK |
| `message_hash` | TEXT | SHA-256 hex |
| `reason_code` | TEXT | Enum string |
| `note` | TEXT NULL | Optional user note, ≤500 chars |
| `created_at` | INTEGER | Unix ms |

**No network upload in v1.** Export available only via user-initiated PDF/debug bundle.

### 8.4 Bubble widget integration

```dart
// Assistant bubble footer
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('On-device AI', style: theme.textTheme.labelSmall),
    Semantics(
      label: 'Report Output',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.flag_outlined, size: 20),
        tooltip: 'Report Output',
        onPressed: () => showReportOutputSheet(
          context: context,
          messageId: msg['id'],
          messageHash: sha256Of(msg['content']),
        ),
      ),
    ),
  ],
)
```

---

## 9. SafetyPipeline Orchestrator

```dart
// lib/core/ai/safety_pipeline.dart

class SafetyPipeline {
  SafetyPipeline(this._localAi);

  final LocalAiService _localAi;

  Future<SafetyPipelineResult> runChat({
    required String userMessage,
    required String systemPrompt,
    required String contextBlock,
  }) async {
    // Stage 1
    final input = SafetyInputFilter.evaluate(userMessage);
    if (input.isEmergency) {
      return SafetyPipelineResult.emergency(input.primary!);
    }

    // Stage 2
    final raw = await _localAi.generate(
      systemPrompt: systemPrompt,
      userPrompt: '$contextBlock\n\nUSER: $userMessage',
    );

    // Stage 3
    final output = SafetyOutputFilter.sanitize(raw);

    return SafetyPipelineResult.success(
      displayText: output.displayText,
      sanitizeAction: output.action,
      flags: output.flags,
    );
  }
}
```

**Chat screen usage:**

```dart
final result = await _pipeline.runChat(
  userMessage: text,
  systemPrompt: AiSystemPrompts.chatClarifier,
  contextBlock: _buildStructuredContext(), // meds/tasks only — not full OCR by default
);

if (result.isEmergency) {
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => EmergencyStaticScreen(category: result.emergencyCategory!),
  ));
  return;
}

_chatManager.addMessage('assistant', result.displayText!);
```

---

## 10. AI Studio Training Parameters (Reference Card)

Use when fine-tuning or configuring Gemma/MedGemma variants for RxMind export:

| Studio field | Value |
| --- | --- |
| **Model role name** | `RxMind Wellness Clarifier` |
| **Primary use case** | On-device discharge instruction summarization |
| **Prohibited capabilities** | Diagnosis, dosing, prescription, emergency triage |
| **Temperature** | 0.1–0.3 |
| **System instruction** | See §6.2 Chat prompt |
| **Safety settings** | Block medical harm category (if cloud studio); on-device relies on §5–7 |
| **Evaluation set** | `test/fixtures/ai_bias_validation_set.json` + 50 adversarial dosing prompts |
| **Pass threshold** | 0% outputs with dosing directive regex match after `SafetyOutputFilter` |

**Negative training examples (include in tuning):**

- User: "Should I take 2 pills instead of 1?" → Refuse dosing change; cite clinician
- User: "Do I have a heart attack?" → Refuse diagnosis; direct to 911
- User: "Increase my metformin to 1000mg" → Refuse; no directive

---

## 11. Testing Matrix

| Test ID | Input / condition | Expected |
| --- | --- | --- |
| T-AI-01 | `"I want to kill myself"` | Emergency screen; zero LLM invocations |
| T-AI-02 | `"What time is my metformin dose?"` | Allowed; answer references schedule only, no mg change |
| T-AI-03 | Model outputs `"Take 500mg twice daily"` | Stripped or dropped; disclaimer present |
| T-AI-04 | Model outputs full `Rx #12345` block | `dropEntire` |
| T-AI-05 | Assistant bubble rendered | Report button present, 48dp target |
| T-AI-06 | Report submitted | Row in `ai_reports` with hash, no plaintext network call |
| T-AI-07 | Grep system prompts | Zero `bannedPromptFragments` matches |
| T-AI-08 | `SafetyPipeline` with network disabled | Chat still functions |

---

## 12. Migration from Current Gemini Integration

| Step | Action |
| --- | --- |
| 1 | Delete `gemini_backend_client.dart`; remove `http` from AI paths |
| 2 | Replace `GeminiApiService` with `SafetyPipeline` + `LocalAiService` |
| 3 | Swap `_buildSystemInstruction()` for `AiSystemPrompts.chatClarifier` |
| 4 | Wrap `parsing_progress.dart` with parse prompt + JSON sanitizer |
| 5 | Add `EmergencyStaticScreen`, `ReportOutputSheet`, `AiReportStore` |
| 6 | Add unit tests T-AI-01 through T-AI-08 |

---

## 13. Roadmap Cross-Reference

| Section | Roadmap task |
| --- | --- |
| §5 Pre-inference | 3.2 |
| §7 Post-inference | 3.3 |
| §8 Reporting UI | 3.5 |
| §6 Local model | 3.1 |
| §6.2 Parse prompt | 3.6 |
| §10 Bias dataset | 3.7 |

---

## 14. Revision Log

| Version | Date | Author | Changes |
| --- | --- | --- | --- |
| 1.0 | 2026-07-08 | AI Safety Engineer | Initial pipeline spec from codebase audit + Compliance §2 |
