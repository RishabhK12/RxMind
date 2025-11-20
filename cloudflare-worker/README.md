Cloudflare Worker: Gemini Proxy

This Worker holds the Gemini API key on the server and proxies requests from the app.

Setup

1. Install Wrangler (CLI): https://developers.cloudflare.com/workers/wrangler/install-and-update/
2. Authenticate: wrangler login
3. Set secrets:
   - wrangler secret put GEMINI_API_KEY
   - Optional: wrangler secret put BACKEND_SHARED_SECRET
4. (Optional) Set an explicit allowed origin in wrangler.toml via ALLOWED_ORIGIN var for CORS.
5. Deploy:
   - wrangler deploy
   - Copy the workers.dev URL. The mobile app already includes our production
     Worker URL, but you can override it via `.env` or `--dart-define` for
     staging/QA builds by setting `BACKEND_BASE_URL`.

API
POST /gemini/generate
Body: { "prompt": "Hello", "model": "gemini-1.5-flash" }
Headers: x-api-key: <BACKEND_SHARED_SECRET> (only if you set it)

Response: { "text": "...", "raw": { ...upstream response... } }

Notes

- Keep your Worker URL private and use secrets or other auth to prevent abuse if leaked.
- You can extend the Worker to support image input or streaming as needed.
