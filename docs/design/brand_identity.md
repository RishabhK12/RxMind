# RxMind Brand Identity

**Document version:** 2.0  
**Last updated:** 2026-07-09  
**Authority:** Visual source of truth for the Flutter app and the public marketing website.  
**Visual reference:** [`assets/hero-reference.png`](assets/hero-reference.png)  
**Implementation reference:** [`aistudio-reference/`](aistudio-reference/) (AI Studio export — layout & motion patterns)

When this document conflicts with older theme comments in code or the static `docs/site/` stub, **this file wins**. Compliance language in `docs/compliance/store_policies.md` and `docs/store/listing_copy.md` still wins for medical claims and ASO wording.

---

## 1. Brand essence

| Attribute | Direction |
| --- | --- |
| **Name lockup** | Lowercase wordmark: `rxmind` |
| **Personality** | Soft, bubbly, friendly recovery companion — not clinical SaaS, not hospital portal |
| **Promise** | Private, on-device recovery organization with delightful, tactile UI |
| **Hero line** | `master your recovery.` (lowercase, extrabold) |
| **Tagline (supporting)** | Private, on-device recovery plans, medication schedules, and progress tracking — stored on your phone |

**Do not** present RxMind as a medical device, diagnostic AI, or cloud health platform.

---

## 2. Hero composition (canonical)

The first viewport is **one composition**: brand + interactive headline + one short supporting sentence + one CTA group. No dashboard chrome, no stats strips, no clinic logo walls.

```
┌─────────────────────────────────────────────────────────────┐
│  [💬] rxmind     Features  How It Works  Privacy  FAQ   CTA │
│                                                             │
│         master  (●→)  [═══════ toggle ═══════]              │
│         (●─────) your  [💊 ❤️🩺]                            │
│         (◐◐ plan details) recovery  ⌇heartbeat              │
│                                                             │
│         Supporting sentence (max ~2 lines)                  │
│         [ Primary CTA ]   See how it works                  │
└─────────────────────────────────────────────────────────────┘
```

### 2.1 Interactive hero ornaments (required)

These are brand marks, not decoration-only. Keep them **interactive** (hover / tap / spring motion). Respect `prefers-reduced-motion`.

| Element | Spec | Interaction |
| --- | --- | --- |
| **Emerald arrow disc** | `#10B981` circle, dark arrow | Hover scale 1.05; tap 0.95 |
| **Gradient toggle** | Pill: `#3B82F6` → `#A855F7` → `#F43F5E`; white knob with blue center dot | Click toggles knob L/R with spring |
| **Amber disc + track** | `#FBBF24` disc with `#3B82F6` center; white frosted track + emerald thumb | Click disc / track toggles thumb |
| **Icon capsule** | White frosted pill, soft shadow; pill + heart icons | Hover lift `y: -5` |
| **Plan details chip** | White pill over rose/purple + cyan overlapping discs; Asclepius mark + label | Hover scale 1.05 |
| **Ambient floaters** | Soft plus / bandage / stars at margins (md+) | Slow `y` float loops (4–6s) |

Dashed connector curves (lg+) are optional brand flourishes; keep low contrast and non-blocking.

### 2.2 What must not appear in the hero

- Fake or implied clinical partnerships (Mayo, Stanford, etc.)
- Email capture forms
- Diagnostic / dosing claim chips
- Dense card grids or metric dashboards
- Detached promo badges over the headline

---

## 3. Color system

### 3.1 Core surfaces & type

| Token | Hex | Usage |
| --- | --- | --- |
| `bg.canvas` | `#FFFFFF` | Marketing page background |
| `bg.soft` | `#F9FAFB` | Alternating sections (`slate-50` feel) |
| `bg.muted` | `#F3F4F6` | Chips, FAQ closed rows |
| `fg.primary` | `#111827` | Headlines, wordmark |
| `fg.secondary` | `#4B5563` / slate-600 | Body copy |
| `fg.muted` | `#94A3B8` / slate-400 | Eyebrows, footer meta |
| `border.subtle` | `#E2E8F0` / slate-200 | Outlined pills, dividers |

### 3.2 Brand accents (hero palette)

| Token | Hex | Role |
| --- | --- | --- |
| `accent.blue` | `#3B82F6` | Logo mark, links, knob center, focus |
| `accent.emerald` | `#10B981` | Forward / success / arrow disc |
| `accent.amber` | `#FBBF24` | Playful energy / slider disc |
| `accent.violet` | `#A855F7` / `#8B5CF6` | Gradient mid, section chips |
| `accent.rose` | `#F43F5E` | Gradient end, soft urgency (sparingly) |
| `accent.cyan` | `#67E8F9` / cyan-300 | Overlap disc with blue |
| `cta.ink` | `#1E1E24` | Primary filled button fill |
| `cta.onInk` | `#FFFFFF` | Primary button label |

### 3.3 Gradients

| Name | CSS |
| --- | --- |
| `gradient.heroToggle` | `linear-gradient(to right, #3B82F6, #A855F7, #F43F5E)` |
| `gradient.planRose` | `linear-gradient(to top right, #FB7185, #A855F7)` |
| `gradient.planCyan` | `linear-gradient(to top right, #60A5FA, #67E8F9)` |
| `gradient.privacyWash` | Soft indigo/emerald washes behind mock UI only |

### 3.4 Accessibility

- Body text on white/soft backgrounds: contrast ≥ **4.5:1** (WCAG 2.2 AA).
- Large display headlines (`#111827` on `#FFFFFF`) exceed AA.
- Do not place light gray body text on colored accent discs.
- High-contrast app mode remains a separate cascade (`lib/theme/theme_tokens.dart` HC palettes) — marketing site should still offer `prefers-contrast` and visible focus rings (`accent.blue`, ≥3px).

---

## 4. Typography

| Role | Family | Weight | Notes |
| --- | --- | --- | --- |
| **Brand / UI (canonical)** | **Plus Jakarta Sans** | 400–800 | Website + future app migration target |
| **App (current)** | Poppins | 400–700 | Keep until Flutter font swap task; match weights/sizes to this scale |
| Display / hero | Plus Jakarta Sans | 800 (extrabold) | Lowercase; tracking tight; ~64–110px responsive |
| Section H2 | Plus Jakarta Sans | 800 | ~36–48px |
| Body | Plus Jakarta Sans | 500 | 16–20px; relaxed leading |
| Nav / labels | Plus Jakarta Sans | 600 | 14px |
| Eyebrow chips | Plus Jakarta Sans | 700 | 12px; uppercase; wide tracking |

Fallback stack: `Plus Jakarta Sans, ui-sans-serif, system-ui, sans-serif`.

---

## 5. Shape, depth, motion

### 5.1 Shape language

- **Default radius:** full pills (`rounded-full`) for CTAs, nav CTA, hero ornaments.
- **Content cards (features/FAQ):** large soft rectangles `rounded-[2rem]`–`rounded-[2.5rem]` — use only when the container holds interaction or a discrete feature block.
- **Circles:** perfect discs for icon wells and hero controls.

### 5.2 Shadows

Prefer soft, low-opacity elevation (not multi-layer neon glow):

```css
/* Hero ornament */
box-shadow: 0 12px 24px rgba(0, 0, 0, 0.08);

/* Toggle knob */
box-shadow: 0 8px 16px rgba(0, 0, 0, 0.10);

/* Colored tint examples */
box-shadow: 0 10px 20px rgba(16, 185, 129, 0.20); /* emerald */
```

Frosted glass: `bg-white/80`–`bg-white/95` + light `backdrop-blur` + `border-white/50` or `border-slate-100`.

### 5.3 Motion principles

| Principle | Rule |
| --- | --- |
| Presence, not noise | 2–4 intentional loops max in hero; spring for toggles |
| Reduced motion | Disable float loops and spring travel; keep instant state changes |
| Duration | Ambient float 4–6s ease-in-out; springs stiffness ~300 damping ~25 |
| Hover | Subtle scale/lift only — no bouncing emoji storms |

---

## 6. Logo & iconography

### 6.1 Wordmark

- Text: `rxmind` (all lowercase)
- Color: `fg.primary` (`#111827`)
- Weight: extrabold / 800
- Companion mark: filled speech-bubble glyph in `accent.blue` (`#3B82F6`), left of wordmark

SVG path reference (from AI Studio export):

```svg
<svg width="28" height="28" viewBox="0 0 24 24" fill="currentColor">
  <path d="M21 11.5C21 16.1944 16.9706 20 12 20C10.7424 20 9.5441 19.7618 8.44857 19.3323C8.10659 19.198 7.72895 19.2319 7.4116 19.4267L4.54226 21.1873C3.76639 21.6635 2.80216 21.011 2.94639 20.109L3.38575 17.3626C3.4542 16.9348 3.32831 16.5021 3.05374 16.1706C1.7825 14.6366 1 13.149 1 11.5C1 6.80558 5.02944 3 10 3C14.9706 3 19 6.80558 19 11.5Z" />
</svg>
```

### 6.2 Icon style

- Lucide-style stroke icons in accent wells (pink/emerald/blue soft fills) for feature cards.
- Emoji allowed sparingly in marketing hero capsules only; prefer SVG in production app chrome.
- Medical serpent (Rod of Asclepius) only as a small decorative mark on “plan details” — never imply regulated clinical authority.

---

## 7. Voice & copy (brand + compliance)

### 7.1 Tone

Warm, clear, empowering. Lowercase display headlines are a brand choice; body sentences use normal capitalization.

### 7.2 Mandatory disclaimer (visible without JS)

Exact store copy from `docs/compliance/store_policies.md` §4.1 — place near top of landing (below nav or as first content strip):

> This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Consult a licensed healthcare professional for medical advice.

### 7.3 Approved verbs

Use: *log, organize, remind, track, clarify, export, store locally*.  
Avoid: *diagnose, treat, prescribe, smart scanning, clinical decision, HIPAA-certified* (see store policies §10).

### 7.4 Feature naming (marketing-safe)

| Avoid (AI Studio draft) | Use |
| --- | --- |
| Smart Prescription Dosing | Medication schedule reminders |
| Symptom & Vital Logs | Wellness & recovery logs |
| Clear Care Regimens | Discharge checklists you organize |
| Fully automated recovery | Recovery schedule you control |

---

## 8. Cross-surface consistency matrix

| Element | Website | Flutter app |
| --- | --- | --- |
| Wordmark + bubble | Header / footer | Splash, about, settings header |
| Accent blue `#3B82F6` | Logo, links, focus | Map to primary (migrate from `#1565C0`) |
| Emerald `#10B981` | Success / forward | Map to secondary / success (migrate from `#00897B`) |
| Soft white canvas | Landing bg | Light scaffold / surfaces |
| Pill CTAs | Primary ink fill | Primary buttons `StadiumBorder` / high radius |
| Soft cards | Features / FAQ | Dashboard cards with large radius |
| Motion | Hero interactivity | Respect reduced-motion; playful micro-interactions only |

Detailed Flutter mapping: [`app_ui.md`](app_ui.md).  
Website build instructions for agents: [`../website/AGENT_BUILD_BRIEF.md`](../website/AGENT_BUILD_BRIEF.md).

---

## 9. Anti-patterns (explicit)

1. Purple-on-white generic AI SaaS without the multicolor hero ornaments.
2. Flat single-accent Material blue without emerald/amber/rose accents.
3. Clinic logo walls or “Designed with [hospital]” claims.
4. Email waitlist as the only CTA (use store download badges).
5. Static hero with all ornaments frozen (unless reduced-motion).
6. Overclaiming encryption or HIPAA certification in marketing chrome.

---

## 10. Source files

| Path | Role |
| --- | --- |
| `docs/design/assets/hero-reference.png` | Approved hero screenshot |
| `docs/design/aistudio-reference/app/page.tsx` | Layout, motion, section structure |
| `docs/design/aistudio-reference/app/globals.css` | CSS variable starting point |
| `docs/design/aistudio-reference/app/layout.tsx` | Plus Jakarta Sans wiring |
| `aistudio-ui.zip` (repo root) | Original export archive |
