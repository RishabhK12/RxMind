# RxMind Flutter App — Full UI Rebrand Guide

**Document version:** 1.0  
**Last updated:** 2026-07-09  
**Audience:** A single Cursor / coding agent tasked with rebranding the **entire Flutter app UI**  
**Goal:** Make the in-app experience feel like the same product as [`assets/hero-reference.png`](assets/hero-reference.png) and the marketing landing page — **without changing product functionality, routes, storage, OCR, AI safety, or compliance gates.**

| Read first (mandatory) | Why |
| --- | --- |
| [`brand_identity.md`](brand_identity.md) | Canonical colors, type, shape, voice |
| [`app_ui.md`](app_ui.md) | Token migration map & component rules |
| [`../website/AGENT_BUILD_BRIEF.md`](../website/AGENT_BUILD_BRIEF.md) | How the web surface interprets the same brand |
| [`../compliance/store_policies.md`](../compliance/store_policies.md) | Disclaimer / ASO / accessibility hard rules |
| [`../roadmap.md`](../roadmap.md) | Active task / branch |

**Visual north star:** soft white canvas, multicolor accents (blue / emerald / amber / violet / rose), pill CTAs, large soft cards, Plus Jakarta Sans, playful but calm recovery companion — **not** clinical Material blue-teal, **not** a port of the marketing hero into every screen.

---

## 0. Mission contract

### 0.1 You MUST

1. Rebrand **all user-visible Flutter UI** to the brand system in `brand_identity.md`.
2. Keep **identical functionality**: same tabs, routes, repositories, OCR pipeline, chat safety, wipe, settings toggles, permissions flows.
3. Route **all colors, radii, typography, and shadows** through `ThemeTokens` / `Theme.of(context)` / shared brand widgets — no new hardcoded `Colors.blue` / `Color(0x…)` in screens.
4. Preserve **high-contrast** palettes (black / yellow / cyan) and **reduced-motion** / text-scale behavior.
5. Keep compliance UI readable: disclaimer gate, CHD consent, AI disclosure, Report Content, emergency screen, erase-data type-to-confirm.
6. Update **contrast tests + goldens** so CI stays green.
7. Work on branch `feature/phase6-task6.3-app-rebrand` (or the Active Task branch in `docs/roadmap.md`). **Never commit to `main`.**

### 0.2 You MUST NOT

1. Change business logic, SQLCipher, Keystore, OCR buffer hygiene, AI prompts, or notification body rules.
2. Remove or hide Report Content, disclaimer, CHD consent, or emergency static screen.
3. Weaken HC contrast for “pretty” brand colors.
4. Port the full marketing hero (gradient toggle / floating emoji composition) into Dashboard or Chat.
5. Add analytics, new paid fonts CDNs, or dependencies without human approval (font files in `assets/fonts/` are OK).
6. Rename public route strings or break `IndexedStack` tab indices.
7. “Clean up” by deleting the alternate `lib/screens/medications/medications_screen.dart` unless you verify zero imports — prefer leave unused file alone or mark deprecated; **shell uses `tracker/medications_screen.dart`.**
8. Commit unless the human asks (per user git rules) — but prepare atomic commits if asked.

### 0.3 Definition of done

An unfamiliar user who saw the landing page should open the app and feel: same logo language, same soft canvas, same blue/emerald accents, same pill buttons, same friendly cards — while every feature still works.

Checklist in §14 must be fully checked.

---

## 1. Current state (what you are changing)

### 1.1 Theme stack today

| File | Role |
| --- | --- |
| `lib/theme/theme_tokens.dart` | Colors, radii (8/12), spacing, Poppins `TextTheme`, WCAG helpers, `RxMindThemeExtension` |
| `lib/theme/app_theme.dart` | Builds light / dark / HC light / HC dark `ThemeData` |
| `lib/main.dart` | `AppTheme.resolve`, `themeMode`, text scale, `disableAnimations`, `RxMindSettings` |

**Problem:** Tokens exist, but most screens **ignore them** and hardcode Material colors. Rebrand = (1) update tokens + `AppTheme` component themes, (2) extract shared widgets, (3) migrate every screen off literals.

### 1.2 Navigation (do not restructure)

`MainNavigationShell` — 6 tabs via `IndexedStack`:

| Index | Label | Screen file |
| --- | --- | --- |
| 0 | Dashboard | `lib/screens/home/home_dashboard.dart` |
| 1 | Charts | `lib/screens/stats/compliance_stats.dart` |
| 2 | Tasks | `lib/screens/tracker/tasks_screen.dart` |
| 3 | Meds | `lib/screens/tracker/medications_screen.dart` |
| 4 | Chat | `lib/screens/ai/ai_chat_screen.dart` |
| 5 | Settings | `lib/screens/settings/settings_screen.dart` |

Entry: `/splash` → onboarding / consent gates → `/mainNav`.

### 1.3 Hardcoded-color hotspots (migrate these)

Approximate `Colors.*` / `Color(0x…)` density in `lib/screens/`:

| Priority | File | Notes |
| --- | --- | --- |
| P0 | `onboarding/onboarding_profile_flow.dart` | Scaffold `#F8FAFB`, many greys |
| P0 | `home/home_dashboard.dart` | Amber warnings, grey cards, red snackbars |
| P0 | `stats/compliance_stats.dart` | Chart series greens/ambers/reds |
| P0 | `tracker/tasks_screen.dart` | Status colors, FAB |
| P0 | `tracker/medications_screen.dart` | Cards, status |
| P0 | `onboarding/splash_screen.dart` | Forced white |
| P1 | `onboarding/permissions_prompt.dart` | Greys / shadows |
| P1 | `ai/ai_chat_screen.dart` + bubbles | Bubble fills, errors |
| P1 | `settings/settings_screen.dart` | Destructive buttons |
| P1 | `ocr/*`, `pdf/pdf_preview_screen.dart` | Snackbars, accents |
| P1 | `settings/contacts_screen.dart` | Blue/green icons |
| P2 | `home/main_navigation_shell.dart` | Black shadow; label TextStyle |
| P2 | `profile/profile_setup_screen.dart` | Legacy form |

There is **no `lib/widgets/`** today. Shared UI is colocated under screens + `lib/core/widgets/markdown_text.dart`.

### 1.4 Fonts today

`pubspec.yaml` → Poppins Regular/Medium/SemiBold/Bold under `assets/fonts/`.  
**Target:** Plus Jakarta Sans (same four weights minimum).

### 1.5 Assets today

- `assets/illus/logo.svg`, `onboard1.svg`–`onboard3.svg`
- Brand reference (docs only): `docs/design/assets/hero-reference.png`

---

## 2. Target design system (app adaptation)

Website can be louder. **App = quieter sibling of the same family.**

### 2.1 Color tokens (implement in `ThemeTokens`)

Add explicit brand constants, then point light/dark fields at them.

```dart
// Brand primitives (new)
static const Color brandBlue = Color(0xFF3B82F6);
static const Color brandEmerald = Color(0xFF10B981);
static const Color brandAmber = Color(0xFFFBBF24);
static const Color brandViolet = Color(0xFF8B5CF6);
static const Color brandRose = Color(0xFFF43F5E);
static const Color brandCyan = Color(0xFF67E8F9);
static const Color brandInk = Color(0xFF1E1E24);
static const Color brandCanvas = Color(0xFFFFFFFF);
static const Color brandSoft = Color(0xFFF9FAFB);
static const Color brandMuted = Color(0xFFF3F4F6);
static const Color brandBorder = Color(0xFFE2E8F0);
static const Color brandFg = Color(0xFF111827);
static const Color brandFgSecondary = Color(0xFF4B5563);
static const Color brandFgMuted = Color(0xFF94A3B8);
```

**Light theme mapping:**

| Token field | New value |
| --- | --- |
| `lightPrimary` | `brandBlue` |
| `lightOnPrimary` | `#FFFFFF` |
| `lightSecondary` | `brandEmerald` |
| `lightOnSecondary` | `#FFFFFF` |
| `lightSurface` | `brandCanvas` |
| `lightOnSurface` | `brandFg` |
| `lightScaffold` | `brandSoft` |
| `lightError` | keep strong red ≈ `#DC2626` or current `#C62828` (verify ≥4.5:1) |
| `lightLink` | `#1D4ED8` (verify contrast) |
| `lightFocus` | `brandBlue` |
| `lightNavInactive` | `#64748B` |
| `lightHint` | `#64748B` |

**Dark theme mapping:**

| Token field | Guidance |
| --- | --- |
| Scaffold / surface | Keep near `#181A1B` / `#232526` |
| Primary | `#60A5FA` or `#64B5F6` |
| Secondary | `#34D399` (emerald lift) |
| On-surface | `#F9FAFB` |
| Error | Keep light red on dark (`#F87171` / current) |

**High-contrast:** **Do not recolor** `hcLight*` / `hcDark*` to brand pastels. HC stays black/yellow/cyan (or existing HC set). Brand rebrand applies to **default light/dark only**.

**Semantic aliases to add** (for screens — avoid raw Material):

| Alias | Light use |
| --- | --- |
| `success` | emerald |
| `warning` | amber (text on amber needs dark fg `#111827`) |
| `info` | blue |
| `aiAccent` | violet (chat chrome only) |
| `destructive` | error |

Extend `RxMindThemeExtension` with `success`, `warning`, `aiAccent`, `border`, `softShadow` if helpful — keep extension immutable + `lerp`.

### 2.2 Radii & spacing

Update `ThemeTokens`:

| Token | Old | New |
| --- | --- | --- |
| `radiusSm` | 8 | **12** (inputs, small chips) |
| `radiusMd` | 12 | **16** (list rows, dialogs) |
| `radiusLg` | — | **24** (feature cards) |
| `radiusPill` | — | **999** (`StadiumBorder` / `BorderRadius.circular(999)`) |
| Spacing | 4/8/16/24 | Keep; add `spacingXl = 32` |

### 2.3 Typography

1. Bundle **Plus Jakarta Sans** (Regular 400, Medium 500, SemiBold 600, Bold 700; ExtraBold 800 optional for splash wordmark only).
2. Set `ThemeTokens.fontFamily = 'PlusJakartaSans'` (or exact family name registered in `pubspec.yaml`).
3. Remove Poppins from pubspec only after goldens pass with new font (or keep Poppins as unused until cleanup — prefer one family).
4. **In-app titles: sentence case** (not marketing lowercase `master your recovery`).
5. Scale (approx):

| Role | Size | Weight |
| --- | --- | --- |
| Screen title | 22–24 | 700 |
| Section title | 18–20 | 600–700 |
| Body | 14–16 | 400–500 |
| Label / nav | 11–12 | 500–600 |
| Button | 14–16 | 700 |

All via `Theme.of(context).textTheme` — no one-off `TextStyle(fontFamily: 'Poppins')` except temporary during migration.

### 2.4 Elevation / shadows

Prefer one soft shadow recipe:

```dart
List<BoxShadow> get softCardShadow => [
  BoxShadow(
    color: Color(0x14000000), // ~8% black — or theme-aware
    blurRadius: 16,
    offset: Offset(0, 8),
  ),
];
```

Avoid stacked neon glows. Borders: `brandBorder` 1px often enough without shadow.

### 2.5 Motion

- Micro: 200–300ms ease; springs only for toggles / completion checkmarks.
- Always respect `MediaQuery.disableAnimationsOf(context)` / `RxMindSettings.reducedMotion`.
- Splash: if reduced motion → skip fade/scale, show static logo then navigate.
- Do **not** add ambient floating hero ornaments on main tabs.

---

## 3. Architecture of the rebrand (how to structure code)

### 3.1 Recommended new files

Create a small shared UI layer (ask human only if you want a different folder name):

```
lib/theme/theme_tokens.dart          # expand
lib/theme/app_theme.dart             # pill buttons, card theme, FAB
lib/theme/brand_shadows.dart         # optional
lib/widgets/rx_card.dart             # soft surface card
lib/widgets/rx_primary_button.dart   # pill filled
lib/widgets/rx_secondary_button.dart # pill outlined
lib/widgets/rx_section_header.dart
lib/widgets/rx_empty_state.dart
lib/widgets/rx_status_chip.dart      # success/warning/info
lib/widgets/rx_app_bar_logo.dart     # bubble + optional wordmark
```

**Rule:** Screens compose these widgets; they do not invent new radii/colors.

### 3.2 `AppTheme` component themes to rewrite

In `_buildTheme`:

| Component | Target |
| --- | --- |
| `elevatedButtonTheme` / `filledButtonTheme` | `StadiumBorder()`, min height 48, padding H24 V14, elevation 0–2, primary or ink fill |
| `outlinedButtonTheme` | Stadium, border `brandBorder` / outline, onSurface label |
| `textButtonTheme` | Link color; no underline required |
| `cardTheme` | radiusLg, surface tint transparent, elevation 0, optional side border |
| `inputDecorationTheme` | radiusSm/Md, focus border 3px `focus` color |
| `appBarTheme` | surface/scaffold, no huge elevation, title from textTheme |
| `floatingActionButtonTheme` | circle or soft round; primary/emerald; white icon |
| `chipTheme` | pill, muted fill |
| `dialogTheme` | radiusLg |
| `snackBarTheme` | behavior floating, radiusMd — map success/error via content, not random Material |
| `bottomSheetTheme` | radiusLg top corners |

Bottom nav is **custom** in `main_navigation_shell.dart` — style it manually to match tokens (selected = primary blue; completed-feel accents may use secondary).

### 3.3 Migration pattern (per file)

For each screen:

1. Remove `Color(0x…)` / `Colors.green` etc.
2. Use `Theme.of(context).colorScheme.*` and `RxMindThemeExtension.of(context)`.
3. Replace local `BorderRadius.circular(8)` buttons with shared pill buttons.
4. Replace ad-hoc cards with `RxCard` (or `Card` + `cardTheme`).
5. Keep keys, callbacks, repository calls, and navigation **byte-identical in behavior**.
6. Run focused widget tests for that area if they exist.

### 3.4 Atomic work order (mandatory sequence)

Do **not** restyle all 30 screens in one untested dump. Follow phases in §4–§11.

After each phase:

```bash
dart format .
flutter analyze
flutter test test/theme/
flutter test test/goldens/
# plus any widget tests touched
```

---

## 4. Phase A — Foundation (tokens, font, AppTheme)

**Branch:** `feature/phase6-task6.3-app-rebrand`

### A1. Fonts

1. Add Plus Jakarta Sans TTF/OTF files under `assets/fonts/` (obtain licensed/open files; OFL OK).
2. Register in `pubspec.yaml` under `fonts:` with family name matching `ThemeTokens.fontFamily`.
3. Update `ThemeTokens.fontFamily`.
4. Keep weight mapping: 400/500/600/700.

### A2. Tokens

1. Add brand primitives + new radii + semantic colors.
2. Remap light/dark fields per §2.1.
3. Update `test/theme/contrast_ratio_test.dart` expectations for new pairs (still ≥4.5:1 body).
4. **Leave HC tokens unchanged.**

### A3. AppTheme

1. Apply pill buttons, card radius, FAB, inputs, snackbars (§3.2).
2. Ensure `RxMindThemeExtension` focus ring width stays **3.0**.

### A4. Shared widgets

Implement `lib/widgets/rx_*.dart` minimal set (§3.1).

### A5. Verify

```bash
flutter test test/theme/contrast_ratio_test.dart
flutter test test/goldens/
```

Goldens will fail — that is expected; regenerate after visual sign-off of harnesses (`test/goldens/theme_harness.dart`).

**Exit criteria:** App launches; theme switches still work; no screen migration required yet except anything broken by button shape.

---

## 5. Phase B — Shell, splash, onboarding

Order matters: first impression surfaces.

### B1. Splash (`onboarding/splash_screen.dart`)

| Keep | Change |
| --- | --- |
| Timing / routing logic | Scaffold uses `colorScheme.surface` or scaffold bg (support dark) |
| Logo asset (update SVG if needed) | Optional wordmark `rxmind` under logo in brand fg |
| | Honor reduced motion (no fade/scale) |

Logo direction: blue speech-bubble mark consistent with web SVG path in `brand_identity.md` §6. Update `assets/illus/logo.svg` if current mark mismatches.

### B2. Onboarding wizard (`onboarding_wizard_screen.dart`)

- Progress bar: track muted, fill primary or emerald; taller soft radius.
- Pages: soft scaffold; illustration in pastel wells (blue-50 / emerald-50 / violet-50).
- Primary CTA: `RxPrimaryButton` / themed `FilledButton` pill.
- Keep 5-step order and disclaimer/CHD content **verbatim**.

### B3. Disclaimer + CHD (`disclaimer_gate_screen.dart`, `chd_consent_screen.dart`)

- Typography first; generous padding; high readability.
- Brand only on primary Continue; secondary Outlined pill for decline paths.
- Do not add playful ornaments.

### B4. Welcome carousel + profile flow + permissions

- `welcome_carousel.dart`: soft pages; indicator uses primary; reduced motion skips parallax.
- `onboarding_profile_flow.dart`: **largest hardcoded set** — migrate all `#F8FAFB` / grey selection cards to theme; selection state = primary border + soft primary fill at low opacity; radius 16–24.
- `permissions_prompt.dart`: same card language; no raw grey hex.

### B5. Tests

- `test/widgets/onboarding_wizard_test.dart`
- `test/widgets/disclaimer_gate_test.dart`
- `test/widgets/chd_consent_test.dart`

**Exit criteria:** Full first-run path looks on-brand; consent copy unchanged; tests pass.

---

## 6. Phase C — Main shell + Dashboard

### C1. `main_navigation_shell.dart`

| Keep | Change |
| --- | --- |
| 6 tabs, IndexedStack, height ≥56 | Selected icon/label = `colorScheme.primary` (blue) |
| Semantics labels | Inactive = extension.navInactive |
| | Soft top shadow using theme-aware color (not raw `Colors.black`) |
| | Labels via `textTheme.labelSmall` (remove hardcoded Poppins 11) |
| | Optional: subtle selected pill behind icon (muted primary fill) — keep tap targets ≥48 |

### C2. `home_dashboard.dart`

Target layout language (functionality unchanged):

- Scaffold soft bg.
- Greeting: titleLarge / brand fg.
- Warning banners: amber soft fill + dark text (not screaming Material amber without contrast).
- Task preview cards: `RxCard` radius 16–24, soft shadow.
- Upload / PDF CTAs: pill primary + secondary outlined.
- Replace `Colors.red` snackbars with `colorScheme.error` / themed SnackBar.
- Logo in AppBar: `RxAppBarLogo`.

Private widgets `_TaskCard`, `_ActionTile` should consume theme.

### C3. Tests

- `test/widgets/main_navigation_shell_test.dart`
- Regenerate `dashboard_*` goldens.

---

## 7. Phase D — Tasks, Meds, Charts

### D1. Tasks (`tracker/tasks_screen.dart`)

- List cards: soft card; completed = emerald check / strikethrough muted fg.
- Due / snooze accents: amber warning token; never random orange.
- FAB: primary circle, white icon.
- Slidable actions: keep behavior; restyle backgrounds to brand emerald / amber / error as appropriate.
- Empty state: friendly illustration well + pill CTA.

### D2. Meds (`tracker/medications_screen.dart`)

- Same card system as tasks.
- FontAwesome pills icon OK; tint with primary/secondary.
- Do not restyle unused `medications/medications_screen.dart` unless linked — if you touch it, apply same tokens for consistency.

### D3. Charts (`stats/compliance_stats.dart`)

Map Syncfusion series colors to brand:

| Meaning | Color |
| --- | --- |
| Good / done | emerald `#10B981` |
| Mid | amber `#FBBF24` |
| Low / miss | error / rose (ensure legend readable) |
| Accent series | blue, violet |

Header gradient: soft blue→emerald wash at low opacity — not loud Instagram gradient. White text on gradient only if contrast ≥4.5:1; else dark text on soft wash.

### D4. Tests

Run any tracker/stats widget tests if present; manual smoke: add task, complete, open charts.

---

## 8. Phase E — Chat / AI / Emergency

### E1. Chat (`ai_chat_screen.dart`, `assistant_message_bubble.dart`)

| Keep | Change |
| --- | --- |
| Local AI wiring, safety redirects | User bubble: primary soft fill or blue-50 |
| Report Content visible | Assistant bubble: surface + border; violet-50 tint OK |
| Disclosure banner | Larger bubble radius (16–20) |
| | Input bar: pill/rounded field; send button circle primary |
| | Errors via colorScheme.error |

### E2. `ai_disclosure_banner.dart` / `report_output_sheet.dart`

- Calm, readable; brand violet only as small accent icon.
- Sheet uses dialog/sheet radiusLg.

### E3. Emergency (`emergency_static_screen.dart`, `emergency_call_tile.dart`)

- **Static, high clarity, no playful motion.**
- Prefer error/high-contrast styling; do not apply bubbly hero aesthetics.
- Functionality (tel links, copy) unchanged.

### E4. Tests

- `test/widgets/ai_disclosure_banner_test.dart`
- `test/widgets/report_output_sheet_test.dart`
- Regenerate `chat_*` goldens.

---

## 9. Phase F — OCR, PDF, Settings, Contacts

### F1. OCR flow

Files: `upload_options.dart`, `review_text.dart`, `parsing_progress.dart`, `parsed_summary.dart`.

- Upload option tiles: soft cards + icon wells (blue/emerald/amber).
- Progress: emerald/primary indicators; keep copy neutral (wellness organizer — no diagnostic language).
- Summary lists: same cards as meds/tasks.
- Snackbars themed.

### F2. PDF (`pdf_preview_screen.dart`)

- Preview chrome themed; share/export buttons pills.
- Note: `lib/services/pdf_export_service.dart` uses `PdfColors` — optionally align exported PDF header accent to brand blue; **do not break layout**. Treat as P2.

### F3. Settings (`settings_screen.dart`)

- Grouped list / cards on soft scaffold.
- Theme / HC / text scale / reduced motion controls unchanged in behavior.
- HC preview dialog must still show real HC theme.
- **Erase All My Data:** error-colored pill; type-to-confirm `DELETE` unchanged.
- Privacy/terms entry rows: chevron list tiles, not marketing hero.

### F4. Contacts + privacy terms + profile setup

- `contacts_screen.dart`: replace raw blue/green with primary/secondary.
- `privacy_terms_screen.dart`: readable serif-not-required; use textTheme; brand header only.
- `profile_setup_screen.dart`: align if still reachable via routes.

### F5. Permission disclosure

- `permission_disclosure_dialog.dart`: keep verbatim disclosure strings from store policies; style dialog with radiusLg + pill buttons.

### F6. Tests

- Settings wipe / PDF a11y tests as applicable.
- `test/widgets/permission_disclosure_test.dart`

---

## 10. Phase G — Illustrations, logo, store screenshots

1. Update `assets/illus/logo.svg` to blue bubble mark (+ optional wordmark usage in splash).
2. Restyle or replace `onboard1–3.svg` with soft pastel illustrations matching web feature wells (pink/emerald/blue). Keep Semantics labels.
3. Update `docs/store/screenshots/README.md` notes if colors change; screenshot 1 still needs disclaimer overlay.
4. Do not change Android/iOS launcher icons unless human requests (separate asset pass).

---

## 11. Phase H — Sweep, a11y, cleanup

### H1. Repo-wide grep gates (must be clean for UI code)

Run from repo root:

```bash
# Fail if screens still use common Material literals (allowlist tests/theme if needed)
rg "Colors\.(blue|green|teal|orange|purple|red|amber)\b" lib/screens lib/widgets
rg "Color\(0x" lib/screens lib/widgets
rg "fontFamily:\s*'Poppins'" lib/
```

Exceptions:

- Emergency screen may use explicit high-contrast constants if documented.
- Shadows: prefer `Colors.black.withOpacity` **only** inside `brand_shadows.dart` or theme extension — not scattered.

### H2. Accessibility pass

- Contrast tests green.
- Focus ring 3px visible on buttons/inputs.
- Dynamic type 2.0×: Dashboard, Tasks, Chat, Settings no overflow (manual or existing tests).
- TalkBack: nav labels, Report Content, erase confirm still announced.
- `disableAnimations` true → splash/onboarding/chat micro-animations suppressed.

### H3. Dead code

- Do not drive-by delete AI/OCR services.
- Optional: comment that `medications/medications_screen.dart` is legacy if still unused.

### H4. Final test battery

```bash
dart format .
flutter analyze
flutter test
```

All must pass. Update goldens with `flutter test --update-goldens test/goldens/` only after visual review.

---

## 12. Screen-by-screen checklist

Copy this into the PR / session notes; check each when done.

### Theme / shared

- [ ] `theme_tokens.dart` brand remap + new radii
- [ ] `app_theme.dart` pills/cards/FAB/inputs
- [ ] `lib/widgets/rx_*` shared components
- [ ] Plus Jakarta Sans in `pubspec.yaml`
- [ ] `contrast_ratio_test.dart`
- [ ] Goldens dashboard + chat (L/D/HC)

### Onboarding

- [ ] `splash_screen.dart`
- [ ] `onboarding_wizard_screen.dart`
- [ ] `disclaimer_gate_screen.dart`
- [ ] `chd_consent_screen.dart`
- [ ] `welcome_carousel.dart`
- [ ] `onboarding_profile_flow.dart`
- [ ] `permissions_prompt.dart`

### Shell & home

- [ ] `main_navigation_shell.dart`
- [ ] `home_dashboard.dart`

### Core tabs

- [ ] `tasks_screen.dart`
- [ ] `tracker/medications_screen.dart`
- [ ] `compliance_stats.dart`
- [ ] `ai_chat_screen.dart`
- [ ] `assistant_message_bubble.dart`
- [ ] `ai_disclosure_banner.dart`
- [ ] `report_output_sheet.dart`
- [ ] `emergency_static_screen.dart`
- [ ] `emergency_call_tile.dart`
- [ ] `settings_screen.dart`

### Secondary flows

- [ ] `upload_options.dart`
- [ ] `review_text.dart`
- [ ] `parsing_progress.dart`
- [ ] `parsed_summary.dart`
- [ ] `pdf_preview_screen.dart`
- [ ] `contacts_screen.dart`
- [ ] `privacy_terms_screen.dart`
- [ ] `profile_setup_screen.dart`
- [ ] `permission_disclosure_dialog.dart`
- [ ] `core/widgets/markdown_text.dart` (inherits textTheme)

### Assets

- [ ] `logo.svg` (+ onboard SVGs as needed)

---

## 13. Functionality regression matrix

After visual rebrand, smoke these **behaviors** (UI only should differ):

| Flow | Expect |
| --- | --- |
| Cold start → disclaimer → CHD → profile → main | Same gates |
| Tab switches 0–5 | State preserved (IndexedStack) |
| Add / complete / snooze task | Same persistence |
| Add medication | Same persistence |
| Upload → review → parse → summary → save | Same pipeline |
| Chat message + Report Content | Sheet opens; safety redirect still works |
| Trigger emergency keywords | Static emergency UI (not playful) |
| Settings theme / HC / text scale / reduced motion | All persist |
| Erase all data with `DELETE` | Wipe still runs |
| Export PDF | Still generates/shares |
| Contacts add via picker | No READ_CONTACTS permission creep |

If any behavior changes, **revert logic** and keep only styling.

---

## 14. Acceptance checklist (final)

- [ ] App light theme matches brand blue/emerald/soft canvas next to `hero-reference.png`
- [ ] Dark theme coherent; HC themes untouched in intent and still usable
- [ ] Pill primary/secondary buttons app-wide
- [ ] Cards 16–24 radius; soft shadows/borders
- [ ] Plus Jakarta Sans everywhere in UI text
- [ ] No stray Material color literals in `lib/screens` / `lib/widgets` (grep clean)
- [ ] Marketing hero ornaments **not** copied into main tabs
- [ ] Compliance controls present and readable
- [ ] `flutter analyze` clean; `flutter test` 100%
- [ ] Goldens updated for L/D/HC
- [ ] Store screenshot guidance still has disclaimer on shot 1
- [ ] Roadmap task 6.3 marked complete when human accepts

---

## 15. Suggested commit slices (if human requests commits)

1. `feat(p6-t6.3): add brand tokens, pills, and Plus Jakarta Sans`
2. `feat(p6-t6.3): rebrand onboarding and splash`
3. `feat(p6-t6.3): rebrand shell and dashboard`
4. `feat(p6-t6.3): rebrand tasks, meds, and charts`
5. `feat(p6-t6.3): rebrand chat and emergency chrome`
6. `feat(p6-t6.3): rebrand OCR, settings, and assets`
7. `test(p6-t6.3): update goldens and contrast tests`

---

## 16. Clarifications already decided (do not re-ask unless blocked)

| Topic | Decision |
| --- | --- |
| Font | Plus Jakarta Sans, bundled |
| Primary | `#3B82F6` |
| Secondary / success | `#10B981` |
| Scaffold light | `#F9FAFB` |
| Button shape | Pill / stadium |
| HC | Unchanged philosophy |
| Hero ornaments in app chrome | No |
| Functionality | Freeze |
| Alternate meds screen | Do not let it diverge if touched; shell uses tracker/ |
| New dependencies | No (except font files) |
| Website | Separate task; match brand docs only |

If something is truly unspecified (e.g. exact onboard illustration redraw), pick the closest soft pastel well style from the landing feature cards and note it in the PR.

---

## 17. Quick reference — do / don’t

| Do | Don’t |
| --- | --- |
| Use `colorScheme` + extensions | Sprinkle `Colors.teal` |
| Shared `RxPrimaryButton` | Per-screen `ElevatedButton.styleFrom` snowflakes |
| Soft white cards | Dense Material dense lists with 4px corners |
| Emerald completion | Random green shades |
| Quiet AI violet tint | Neon purple chat |
| Static emergency | Bubbly emergency |
| Sentence-case app titles | Lowercase marketing headlines in tabs |
| Update goldens | Force-push or commit to main |

---

## 18. Related docs

| Doc | Role |
| --- | --- |
| [`brand_identity.md`](brand_identity.md) | Brand source of truth |
| [`app_ui.md`](app_ui.md) | Short app token map |
| [`README.md`](README.md) | Design docs index |
| [`../website/AGENT_BUILD_BRIEF.md`](../website/AGENT_BUILD_BRIEF.md) | Web sibling |
| [`../store/listing_copy.md`](../store/listing_copy.md) | Safe verbs |
| [`../compliance/store_policies.md`](../compliance/store_policies.md) | Legal/a11y |

**This guide is the runbook.** `app_ui.md` remains the compact token summary; if they conflict on app implementation detail, **this file wins for rebrand execution**, and `brand_identity.md` still wins for color/type values.
