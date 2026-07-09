import Link from "next/link";
import { PLAY_STORE_URL, assetPath } from "@/lib/config";

/** Matched visual height for both store badges (official assets differ in padding). */
const BADGE_HEIGHT_CLASS = "h-10 md:h-11";

export function DownloadSection() {
  return (
    <section
      id="download"
      className="relative overflow-hidden bg-[#F9FAFB] px-4 py-24 text-center md:py-32"
    >
      <div
        className="pointer-events-none absolute left-1/2 top-1/2 h-[600px] w-[600px] -translate-x-1/2 -translate-y-1/2 rounded-full bg-blue-100/40 blur-3xl"
        aria-hidden="true"
      />

      <div className="relative z-10 mx-auto max-w-2xl space-y-8">
        <span className="inline-block rounded-full bg-blue-100 px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-blue-800">
          Download
        </span>
        <h2 className="text-4xl font-extrabold leading-tight tracking-tight text-slate-900 md:text-5xl">
          Get rxmind
        </h2>
        <p className="text-lg font-medium leading-relaxed text-slate-600">
          Download on Google Play. App Store coming soon. Your recovery data
          stays on your device.
        </p>

        <div className="flex flex-col items-center justify-center gap-4 pt-2 sm:flex-row sm:items-center sm:gap-5">
          <a
            href={PLAY_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center transition-transform hover:scale-[1.03] focus-visible:outline focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-[#3B82F6]"
          >
            {/* eslint-disable-next-line @next/next/no-img-element -- plain img so basePath is applied reliably on static export */}
            <img
              src={assetPath("/badges/google-play.png")}
              alt="Get it on Google Play"
              width={135}
              height={40}
              className={`${BADGE_HEIGHT_CLASS} w-auto`}
              decoding="async"
            />
          </a>

          <div
            className="relative inline-flex cursor-default items-center"
            aria-disabled="true"
            title="App Store listing coming soon"
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={assetPath("/badges/app-store.svg")}
              alt="Download on the App Store — Coming soon"
              width={120}
              height={40}
              className={`${BADGE_HEIGHT_CLASS} w-auto opacity-50 grayscale`}
              decoding="async"
            />
            <span className="pointer-events-none absolute -bottom-1 left-1/2 -translate-x-1/2 translate-y-full whitespace-nowrap rounded-full bg-slate-200/90 px-2.5 py-0.5 text-[10px] font-bold uppercase tracking-wider text-slate-600">
              Coming soon
            </span>
          </div>
        </div>

        <p className="pt-6 text-sm font-medium text-slate-400">
          <Link href="/privacy/" className="underline underline-offset-2 hover:text-slate-600">
            Privacy
          </Link>
          {" · "}
          <Link
            href="/data-safety/"
            className="underline underline-offset-2 hover:text-slate-600"
          >
            Data Safety
          </Link>
        </p>
      </div>
    </section>
  );
}
