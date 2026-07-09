# RxMind App UI Design Spec

**Document version:** 2.0  
**Last updated:** 2026-07-09  
**Audience:** Flutter / Cursor agents touching `lib/theme/` and product UI  
**Parent:** [`brand_identity.md`](brand_identity.md)  
**Code today:** `lib/theme/theme_tokens.dart`, `lib/theme/app_theme.dart`

This document is the **compact** in-app token map and component rules for the AI Studio / hero brand.

For a full, screen-by-screen rebrand executed by one agent (phased migration, grep gates, regression matrix), use **[`app_rebrand_guide.md`](app_rebrand_guide.md)** — that runbook wins on execution detail when the two differ.

---

## 1. Goals

1. Share one brand identity with the marketing site (colors, shape, voice).
2. Preserve WCAG 2.2 AA body contrast and high-contrast / reduced-motion modes.
3. Keep clinical compliance UI (disclaimers, report flags, erase-data) visually clear — never cute at the expense of readability.

---

## 2. Token migration map

Map current `ThemeTokens` → brand tokens. Prefer introducing named brand constants, then pointing light theme at them.

| Brand token | Hex | Current light token | Action |
| --- | --- | --- | --- |
| `accent.blue` | `#3B82F6` | `lightPrimary` `#1565C0` | **Replace** primary |
| `fg.primary` | `#111827` | `lightOnSurface` `#212121` | Align |
| `bg.canvas` / soft | `#FFFFFF` / `#F9FAFB` | `lightSurface` / `lightScaffold` `#F4F6F8` | Align scaffold to `#F9FAFB` |
| `accent.emerald` | `#10B981` | `lightSecondary` `#00897B` | **Replace** secondary / success |
| `cta.ink` | `#1E1E24` | — | Add for filled ink buttons (optional) |
| `accent.violet` | `#8B5CF6` | — | Accent chips / AI chrome only |
| `accent.amber` | `#FBBF24` | — | Highlights / progress playfulness |
| `accent.rose` | `#F43F5E` | — | Sparse (errors stay `lightError`) |
| Focus ring | `#3B82F6`, 3px | `lightFocus` `#1565C0` | Match primary |
| Link | `#0D47A1` → prefer `#1D4ED8` | `lightLink` | Keep ≥4.5:1 on white |

**Do not weaken** high-contrast palettes (`hcLight*` / `hcDark*`) for brand color — HC modes stay black/yellow/cyan for accessibility.

### 2.1 Dark mode

Keep dark surfaces near current (`#181A1B` / `#232526`). Lift primary to a lighter blue (`#60A5FA` or current `#64B5F6`) so accents remain playful without washing out.

### 2.2 Typography

| Surface | Current | Target |
| --- | --- | --- |
| App font | Poppins | **Plus Jakarta Sans** (bundle as Flutter font when ready) |
| Until swap | Poppins | Match brand **weights and sizes**; do not introduce a third family |

Display sizes in-app stay smaller than web hero (use `displayLarge` ~32–36). Lowercase marketing headlines are **website-only**; in-app titles use sentence case for clarity (TalkBack / localization).

---

## 3. Component rules (Flutter)

### 3.1 Buttons

- Primary: filled, **stadium / pill** shape, `cta.ink` or `accent.blue` fill, white label, soft shadow optional.
- Secondary: outlined pill, `border.subtle`, `fg.primary` label.
- Min height ≥ 48 dp; focus ring 3px.

### 3.2 Cards & lists

- Corner radius **16–24** (brand soft cards); avoid tiny 4–8 Material defaults for primary content cards.
- Soft border `#E2E8F0` + light shadow; no heavy elevation stacks.
- Cards only when they group an interaction or a discrete feature — not decorative wrappers.

### 3.3 Navigation

- Bottom nav ≥ 56 dp; selected state uses `accent.blue` or emerald for “done” semantics.
- Icons: simple stroke / filled; no emoji in chrome.

### 3.4 Chat / AI surfaces

- Bubbles: large radius, soft gray/white; assistant vs user differentiation via subtle tint (violet-50 / blue-50), not neon.
- Persistent **Report Content** control remains visible (compliance) — style as quiet text button, not hidden overflow-only.
- Emergency layout: high-contrast, static, no playful hero ornaments.

### 3.5 Onboarding & splash

- Splash may use wordmark + blue bubble mark.
- Onboarding illustrations: soft pastel wells (pink/emerald/blue) matching feature cards on the site.
- Disclaimer gate: high-contrast text block first; brand color only on Continue CTA.

### 3.6 Motion

- Micro-interactions OK (toggle springs, list item lift) if `MediaQuery.disableAnimations` / reduced-motion is respected.
- Do not port the full marketing hero into the app shell.

---

## 4. Screen-level guidance

| Area | Brand application |
| --- | --- |
| Dashboard | Soft scaffold, pill CTAs, emerald progress, amber accents sparingly |
| Tasks / Meds | Checklist clarity first; emerald completed; blue focus |
| Charts | Use brand accent series: blue, emerald, violet, amber — not rainbow noise |
| Settings | Neutral; destructive erase uses error red + type-to-confirm |
| OCR / import | Ephemeral processing UI; no raw image gallery chrome |

---

## 5. Acceptance checks (when implementing theme migration)

- [ ] `test/theme/contrast_ratio_test.dart` still passes for all body pairs.
- [ ] Golden tests updated for light / dark / HC.
- [ ] Primary buttons and focus rings use brand blue.
- [ ] No new dependency without orchestrator approval.
- [ ] Store screenshot brief still shows disclaimer overlay on shot 1.

---

## 6. Out of scope here

- Rewriting every screen in this doc pass.
- Changing SQLCipher / storage / AI safety behavior.
- Adding cloud analytics or theming telemetry.
