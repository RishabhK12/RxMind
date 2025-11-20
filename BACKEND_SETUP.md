# Quick Setup: Deploy Backend & Enable AI Features

The RxMind app requires a **Cloudflare Worker** to proxy Gemini API requests securely. Until you deploy this worker, AI features (OCR parsing, health chat) will fail with DNS errors.

## Option 1: Deploy to Cloudflare (Recommended)

```bash
cd cloudflare-worker
npm install
npx wrangler login
npx wrangler secret put GEMINI_API_KEY
# Paste your Gemini API key when prompted
npx wrangler deploy
```

After deploying, copy the `*.workers.dev` URL and either:

- Update `lib/config/backend_config.dart` line 17 with your live URL, **OR**
- Create a `.env` file (copy from `.env.example`) and set `BACKEND_BASE_URL=https://your-worker.workers.dev`

## Option 2: Use a Mock Backend (Testing Only)

If you want to test the app without deploying a real worker:

1. Set up a simple local server that responds to `POST /gemini/generate` with mock JSON
2. Create `.env` and set `BACKEND_BASE_URL=http://localhost:3000` (or your test server)
3. **Warning**: The app enforces HTTPS, so you'll need to temporarily disable that check in `gemini_backend_client.dart` for local testing

## Troubleshooting

**"Failed host lookup" error:**

- The bundled worker URL is not deployed yet
- Deploy the worker (Option 1) or override with a valid endpoint (Option 2)

**"Backend error 401/403":**

- Your worker's `GEMINI_API_KEY` secret is missing or invalid
- Re-run `wrangler secret put GEMINI_API_KEY`

**Still having issues?**

- Check `cloudflare-worker/README.md` for detailed worker setup
- Verify your Gemini API key is valid at [Google AI Studio](https://aistudio.google.com/apikey)
