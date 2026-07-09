# rxmind

**Private on-device recovery organizer**

**Live site:** [rishabhk12.github.io/RxMind](https://rishabhk12.github.io/RxMind/) · built from [`website/`](website/) (see [`website/README.md`](website/README.md) for Play URL and `NEXT_PUBLIC_BASE_PATH`).

This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Always seek the advice of a licensed healthcare professional for medical questions.

rxmind helps you organize post-hospital recovery on your phone — private recovery plans, medication schedules, and progress tracking that stay on-device.

## Brand

| Asset | Location |
| --- | --- |
| Mark (icon only) | [`assets/brand/rxmind-mark.svg`](assets/brand/rxmind-mark.svg) |
| Logo (mark + wordmark) | [`assets/brand/rxmind-logo.svg`](assets/brand/rxmind-logo.svg) |
| App launcher source | [`assets/icons/app_icon.png`](assets/icons/app_icon.png) |
| Regenerate PNGs | `python scripts/generate_brand_assets.py` |

Wordmark is always lowercase: **rxmind**. The mark is a blue speech bubble with a medical cross (`#3B82F6`).

## What it does

- **Discharge organization** — photograph or import documents; on-device text extraction
- **Medication & task logging** — schedules and generic reminders
- **Wellness tracking** — recovery logs and progress on your phone
- **Privacy by design** — health data stays local; no RxMind cloud database

## Repository layout

| Path | Purpose |
| --- | --- |
| [`lib/`](lib/) | Flutter app |
| [`website/`](website/) | Marketing site (Next.js static export → GitHub Pages) |
| [`docs/`](docs/) | Compliance, design, and engineering specs |
| [`assets/brand/`](assets/brand/) | Canonical brand SVGs |

## Website (local)

```bash
cd website
npm install
npm run dev
```

Production build for GitHub Pages (`/RxMind` base path):

```bash
cd website
printf 'NEXT_PUBLIC_BASE_PATH=/RxMind\n' > .env.production.local
npm run build
```

## Flutter app (local)

### Prerequisites

- Flutter SDK 3.0+
- Android Studio or VS Code

### Run

```bash
flutter pub get
dart run flutter_launcher_icons   # after updating assets/icons/app_icon.png
flutter run
```

### Launcher icons

After changing the mark, regenerate PNGs and refresh platform icons:

```bash
python scripts/generate_brand_assets.py
dart run flutter_launcher_icons
```

## Privacy & security

- Recovery data is stored **on your device**
- No account required for core use
- Encrypted local storage is the target architecture (see [`docs/architecture/security_storage.md`](docs/architecture/security_storage.md))
- Marketing copy and store listings must follow [`docs/compliance/store_policies.md`](docs/compliance/store_policies.md)

## Contributing

Open an issue or pull request on GitHub. For agent workflows, see [`AGENTS.md`](AGENTS.md) and [`docs/roadmap.md`](docs/roadmap.md).

## License

MIT — see [LICENSE](LICENSE).

---

**Disclaimer:** rxmind is a personal recovery organizer, not a substitute for professional medical advice.
