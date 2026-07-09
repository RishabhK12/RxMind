/**
 * Marketing site config. Set NEXT_PUBLIC_PLAY_STORE_URL when the listing is live.
 * Placeholder keeps the badge linkable for layout/a11y until publish.
 */
export const PLAY_STORE_URL =
  process.env.NEXT_PUBLIC_PLAY_STORE_URL ??
  "https://play.google.com/store/apps/details?id=PLACEHOLDER";

export const SITE_NAME = "RxMind";

export const DISCLAIMER =
  "This app is not a medical device and does not diagnose, treat, cure, or prevent any medical condition. Always seek the advice of a licensed healthcare professional for medical questions.";
