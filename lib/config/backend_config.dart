/// Centralized configuration for the backend proxy that holds the Gemini API key.
///
/// The app prefers values from runtime env (`.env`) when present, but it also
/// ships with a baked-in Cloudflare Worker URL so production builds do not rely
/// on local files. You can override either value with `--dart-define`
/// (RXMIND_BACKEND_BASE_URL / RXMIND_BACKEND_SHARED_SECRET) during build time.
class BackendConfig {
  const BackendConfig._();

  /// Default Worker endpoint that we deploy for production builds.
  /// NOTE: This must be deployed via `wrangler deploy` before the app can use AI features.
  /// Until deployed, this URL will fail with a DNS error. For local dev, override with
  /// a valid endpoint in `.env` as BACKEND_BASE_URL.
  static const String _bundledWorkerUrl =
      'https://rxmind-gemini-proxy.rishabhk12.workers.dev';

  /// Base URL resolved in the following order:
  /// 1. `--dart-define=RXMIND_BACKEND_BASE_URL=...`
  /// 2. Bundled Worker URL above
  static const String backendBaseUrl = String.fromEnvironment(
    'RXMIND_BACKEND_BASE_URL',
    defaultValue: _bundledWorkerUrl,
  );

  /// Optional shared secret header to lock down the Worker.
  static const String backendSharedSecret = String.fromEnvironment(
    'RXMIND_BACKEND_SHARED_SECRET',
    defaultValue: '',
  );
}
