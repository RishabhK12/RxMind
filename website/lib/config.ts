/**
 * Marketing site config. Set NEXT_PUBLIC_PLAY_STORE_URL when the listing is live.
 * Placeholder keeps the badge linkable for layout/a11y until publish.
 */
export const PLAY_STORE_URL =
  process.env.NEXT_PUBLIC_PLAY_STORE_URL ??
  "https://play.google.com/store/apps/details?id=PLACEHOLDER";

export const SITE_NAME = "RxMind";

/** GitHub project Pages base path, e.g. `/RxMind` (no trailing slash). */
export const BASE_PATH =
  (process.env.NEXT_PUBLIC_BASE_PATH ?? "").replace(/\/$/, "") || "";

/** Prefix a root-absolute public asset path with basePath for static export. */
export function assetPath(path: string): string {
  const normalized = path.startsWith("/") ? path : `/${path}`;
  return `${BASE_PATH}${normalized}`;
}

export const DISCLAIMER =
  "This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Always seek the advice of a licensed healthcare professional for medical questions.";
