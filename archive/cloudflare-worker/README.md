# Archived Cloudflare Worker (Not Used in Production)

This directory contains the former RxMind Gemini API proxy worker. It is **archived** and is **not used in production builds**.

RxMind AI inference is **local-only** per the Phase 3 engineering roadmap. No health data is transmitted to cloud inference endpoints.

Do not deploy this worker for current RxMind releases.

## Historical Reference

The original worker proxied `POST /gemini/generate` to the Gemini API. See `src/index.ts` and `wrangler.toml` for the archived implementation.
