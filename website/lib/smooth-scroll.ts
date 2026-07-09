/**
 * Fluid in-page scroll with eased animation (falls back to instant when reduced-motion).
 */
export function smoothScrollToId(
  id: string,
  options?: { offset?: number; duration?: number }
) {
  if (typeof window === "undefined") return;

  const el = document.getElementById(id);
  if (!el) return;

  const offset = options?.offset ?? 80;
  const prefersReduced =
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  const targetY =
    el.getBoundingClientRect().top + window.scrollY - offset;

  if (prefersReduced) {
    window.scrollTo(0, targetY);
    return;
  }

  const startY = window.scrollY;
  const distance = targetY - startY;
  const duration = options?.duration ?? Math.min(1200, Math.max(500, Math.abs(distance) * 0.55));
  let startTime: number | null = null;

  // easeInOutCubic — polished, not snappy
  const ease = (t: number) =>
    t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

  const step = (now: number) => {
    if (startTime === null) startTime = now;
    const elapsed = now - startTime;
    const progress = Math.min(elapsed / duration, 1);
    window.scrollTo(0, startY + distance * ease(progress));
    if (progress < 1) requestAnimationFrame(step);
  };

  requestAnimationFrame(step);
}
