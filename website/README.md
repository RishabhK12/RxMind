# RxMind Marketing Website

Public landing page + legal pages for RxMind (Task 6.2).

## Stack

- Next.js 15 (App Router) with **static export** (`output: 'export'`)
- Tailwind CSS 4
- Motion (`motion/react`) for hero ornaments
- Plus Jakarta Sans

## Develop

```bash
cd website
npm install
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

## Build (static)

```bash
cd website
npm ci
npm run build
```

Output is written to `website/out/` for GitHub Pages.

## Configuration

| Variable | Purpose | Default |
| --- | --- | --- |
| `NEXT_PUBLIC_PLAY_STORE_URL` | Google Play listing URL for the download badge | `https://play.google.com/store/apps/details?id=PLACEHOLDER` |
| `NEXT_PUBLIC_BASE_PATH` | Set if the site is served under a subpath (e.g. `/RxMind`) | empty (site root) |

Store badges live in `public/badges/`:

- `google-play.png` — official Google Play badge (linked)
- `app-store.svg` — official App Store badge (muted, not linked; “Coming soon”)


Example for a project Pages URL `https://org.github.io/RxMind/`:

```bash
NEXT_PUBLIC_BASE_PATH=/RxMind NEXT_PUBLIC_PLAY_STORE_URL=https://play.google.com/store/apps/details?id=com.example.rxmind npm run build
```

Play URL is also readable from [`lib/config.ts`](lib/config.ts).

## Routes

| Path | Page |
| --- | --- |
| `/` | Landing |
| `/privacy/` | Privacy Policy |
| `/terms/` | Terms of Use |
| `/data-safety/` | Data Safety summary |

## Brand & compliance

- Visual tokens: [`../docs/design/brand_identity.md`](../docs/design/brand_identity.md)
- Build brief: [`../docs/website/AGENT_BUILD_BRIEF.md`](../docs/website/AGENT_BUILD_BRIEF.md)
- Medical disclaimer is server-rendered (visible with JS disabled)
- No analytics, email capture, or clinic partnership logos

## Deploy

GitHub Actions workflow [`.github/workflows/pages.yml`](../.github/workflows/pages.yml) builds this package and deploys `website/out` to GitHub Pages.
