# RxMind Website — Agent Build Brief

**Document version:** 1.0  
**Last updated:** 2026-07-09  
**Audience:** A separate Cursor / coding agent that will implement the public landing site  
**Status:** Spec only — do not treat the AI Studio export as production-ready as-is  
**Brand source of truth:** [`../design/brand_identity.md`](../design/brand_identity.md)  
**Hero reference image:** [`../design/assets/hero-reference.png`](../design/assets/hero-reference.png)  
**Layout / motion reference:** [`../design/aistudio-reference/app/page.tsx`](../design/aistudio-reference/app/page.tsx)  
**Compliance:** [`../compliance/store_policies.md`](../compliance/store_policies.md), [`../store/listing_copy.md`](../store/listing_copy.md)

---

## 0. Mission (read first)

Build a **single marketing landing page** for RxMind that:

1. Visually matches the hero in `hero-reference.png` and the interactive patterns in the AI Studio export.
2. Explains app features with **store-safe** copy (no diagnostic / dosing claims).
3. Provides a **download area** with the **Google Play** badge now, and a clear slot for **App Store** later.
4. Keeps hero ornaments **interactive** (not a static screenshot).
5. Links to Privacy / Terms / Data Safety (can reuse or restyle existing `docs/site/*.html` content).
6. Ships with the **mandatory medical disclaimer visible without JavaScript**.

This is a lean site — **one landing page + legal subpages**, not a multi-product marketing system.

---

## 1. Clarified product decisions (defaults)

These defaults are locked unless the human orchestrator overrides them:

| Decision | Default |
| --- | --- |
| Scope | Single landing page + Privacy, Terms, Data Safety |
| Hosting | Prefer GitHub Pages from `docs/site/` **or** a small Next.js/static export under `website/` that deploys to Pages — pick one stack and document it |
| Stack preference | **Static-friendly**: Next.js static export **or** Vite + React. Reuse motion patterns from AI Studio (`motion` / Framer-style). Avoid requiring a Gemini API key. |
| Auth / Login | **No real login.** Header “Get Started” scrolls to download. Remove or relabel “Login” → “Download” |
| Email capture | **Do not ship** email waitlist forms (privacy + no backend) |
| Clinic logos | **Do not ship** Mayo / Stanford / etc. logo row |
| Play badge | Official Google Play badge asset; link URL placeholder until listing live |
| App Store | Placeholder disabled button or “Coming soon” — no fake link |
| Language | English only for v1 |
| Analytics | None (no GA, no pixels) |

---

## 2. Information architecture

```
/                 → Landing (this brief)
/privacy          → Privacy Policy (from docs/compliance + existing docs/site/privacy.html)
/terms            → Terms
/data-safety      → Data Safety summary
```

In-page anchors on `/`:

| ID | Section |
| --- | --- |
| `#features` | Feature cards |
| `#how-it-works` | Companion explainer + soft UI mock |
| `#privacy` | On-device privacy story |
| `#download` | Store badges (primary CTA target) |
| `#faq` | Accordion FAQ |

Nav labels: **Features**, **How It Works**, **Privacy First**, **FAQ**.  
Header CTA: **Get Started** → `#download`.

---

## 3. Page sections (build order)

### 3.1 Global chrome

- Sticky or static top nav: logo (blue bubble + `rxmind`) | center links | Get Started pill.
- Mobile: collapse links into a simple menu or anchor list; keep logo + CTA visible.
- Footer: logo, section links, Privacy / Terms / Data Safety, © 2026 RxMind.

### 3.2 Disclaimer strip (required, no-JS)

Immediately under nav (or as first element in `<main>`), render the exact §4.1 disclaimer in HTML. Style as a calm left-border or soft chip — not a modal.

### 3.3 Hero (canonical — match reference)

Implement from `brand_identity.md` §2 and `aistudio-reference/app/page.tsx` hero block:

- Headline composition: **master** + emerald arrow + gradient toggle / **amber+slider** + **your** + icon capsule / **plan details** + **recovery**.
- Keep toggle, slider, and hover springs **interactive**.
- Subcopy (approved):

> RxMind helps you organize post-hospital recovery on your phone — private recovery plans, medication schedules, and progress tracking that stay on-device.

- CTAs: primary **Get the app** → `#download`; secondary text link **See how it works** → `#how-it-works`.
- Ambient floaters OK on md+; honor `prefers-reduced-motion`.
- **Omit** clinical partner logo row from the AI Studio draft.

### 3.4 Features (`#features`)

Eyebrow: e.g. “Smarter home recovery”  
H2: “Your recovery schedule, under your control.”

Three cards (safe copy):

| Title | Body |
| --- | --- |
| Medication schedule reminders | Log your medications and get timely, **generic** reminders that fit your day — without putting drug names on your lock screen. |
| Wellness & recovery logs | Track how you feel, tasks, and milestones with simple, friendly logging. |
| Discharge checklists | Import discharge documents for on-device text extraction and turn them into checklists you can organize yourself. |

Use soft white cards on `#F9FAFB`, large radius, accent icon wells (pink / emerald / blue).

### 3.5 How it works (`#how-it-works`)

- Left: short story — recovery shouldn’t feel like a hospital chore; RxMind turns instructions into trackable tasks.
- Right: decorative soft mock UI (floating cards) from the AI Studio reference — **illustrative only**, no real PHI.
- CTA: scroll to `#download`.

### 3.6 Privacy First (`#privacy`)

- Headline: “Your health data. Protected locally.”
- Body: on-device processing/storage; no cloud sync of recovery logs; encrypted local database; erase anytime.
- Dark “sandbox” card visual from reference is OK if copy stays accurate (AES-256 / SQLCipher — do not invent certifications).
- Link out to `/privacy` and `/data-safety`.

### 3.7 Download (`#download`) — required

- Headline: “Get RxMind”
- Short line: Free download. Health data stays on your device.
- **Google Play** badge (official asset, sufficient contrast, `rel`/`target` as appropriate).
  - `href`: use placeholder `https://play.google.com/store/apps/details?id=PLACEHOLDER` or env/config constant documented in README.
- **App Store**: muted “Coming soon” badge or disabled Apple mark — do not deep-link until live.
- Optional: small text links to Privacy / Data Safety under badges.
- **No email field.**

### 3.8 FAQ (`#faq`)

Accordion; start from AI Studio questions but **sanitize** answers:

1. How does RxMind protect my privacy? → On-device / local sandbox; recovery data not uploaded to RxMind servers.
2. Can I import discharge instructions? → Photograph or import documents; on-device text extraction; you review and organize.
3. Does it work offline? → Yes for core logging/reminders/plans.
4. Is RxMind medical advice? → No; not a medical device; consult licensed professionals.

### 3.9 Legal pages

Port content from existing `docs/site/privacy.html`, `terms.html`, `data-safety.html` (and drafts under `docs/compliance/`). Keep HTML public, non-geofenced. Match brand chrome (nav/footer) but keep legal text readable (no hero gimmicks).

---

## 4. Visual & motion requirements

Follow [`../design/brand_identity.md`](../design/brand_identity.md) exactly for:

- Colors, gradients, Plus Jakarta Sans
- Pill shapes, soft shadows, frosted capsules
- Hero interactivity + reduced motion

**Quality bar:** Someone comparing the live hero to `hero-reference.png` should recognize the same composition, ornaments, and color energy.

---

## 5. Technical requirements

| Requirement | Detail |
| --- | --- |
| Disclaimer without JS | Present in initial HTML |
| No secrets | No Gemini keys, no `.env` required for build |
| No PHI | No sample patient data in mocks |
| A11y | Keyboard FAQ, focus rings, alt text on badges, Lighthouse a11y ≥ 90 |
| Perf | Lazy-load non-critical motion; optimize fonts |
| SEO | Title/description from brand; Open Graph optional |
| CI | If using `docs/site/`, keep or update `.github/workflows/pages.yml` |

### 5.1 Suggested file layout (if new app under `website/`)

```
website/
  package.json
  README.md
  public/badges/google-play.svg
  public/badges/app-store-coming-soon.svg
  src/… or app/…
docs/website/AGENT_BUILD_BRIEF.md   ← this file (do not delete)
```

If enhancing static `docs/site/` instead, replace the minimal stub with branded CSS/JS modules but keep URLs stable for store privacy policy links.

### 5.2 Dependencies

- Reuse patterns from `docs/design/aistudio-reference/` (Tailwind, motion).
- **Do not** add analytics SDKs or AI Studio Gemini client.
- Ask the human before adding paid font CDNs if offline/build constraints matter; Google Fonts Plus Jakarta Sans is acceptable for the marketing site.

---

## 6. Copy deck (paste-ready)

**Nav CTA:** Get Started  

**Hero H1 structure:** master / your / recovery (with ornaments between)  

**Hero supporting:**  
RxMind helps you organize post-hospital recovery on your phone — private recovery plans, medication schedules, and progress tracking that stay on-device.

**Primary button:** Get the app  
**Secondary:** See how it works  

**Download H2:** Get RxMind  
**Download sub:** Download on Google Play. App Store coming soon. Your recovery data stays on your device.

**Footer blurb:** On-device recovery organizer. Not a medical device.

---

## 7. Explicit non-goals

- User accounts, login, billing
- Blog, docs portal, or multi-locale
- Embedding the Flutter app
- Cloud waitlists or CRM
- Claiming hospital partnerships or certifications
- Porting purple shadcn defaults from `globals.css` over the hero palette (hero palette wins)

---

## 8. Acceptance checklist (agent must verify)

- [ ] Hero matches reference composition and remains interactive
- [ ] `prefers-reduced-motion` disables ambient loops
- [ ] Disclaimer visible with JS disabled
- [ ] Google Play badge present; App Store slot present as coming soon
- [ ] No email capture; no clinic logo wall
- [ ] Feature/FAQ copy uses approved verbs only
- [ ] Privacy / Terms / Data Safety reachable from footer
- [ ] Lighthouse accessibility ≥ 90 on landing
- [ ] README documents how to set the Play Store URL
- [ ] Brand tokens align with `docs/design/brand_identity.md`

---

## 9. Handoff notes for the implementing agent

1. Open `docs/roadmap.md` and confirm whether a website task is active; if not, create/use branch `feature/website-landing-v1` (never commit to `main` unless instructed).
2. Read `brand_identity.md` + this brief fully before coding.
3. Diff against `aistudio-reference/app/page.tsx` — **port structure**, then **delete** non-compliant sections (email CTA, clinic logos, dosing claims, Login).
4. Present a short blueprint (stack choice + file list) to the human if AGENTS.md Plan→Review applies; then implement.
5. Do not push remote unless asked.

**Success look:** Soft white page, playful multicolor hero controls, calm feature sections, clear Play download, unmistakable privacy story — same brand as the Flutter app target in `docs/design/app_ui.md`.
