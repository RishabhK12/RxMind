import Image from "next/image";
import Link from "next/link";
import { PLAY_STORE_URL } from "@/lib/config";

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
          Get RxMind
        </h2>
        <p className="text-lg font-medium leading-relaxed text-slate-600">
          Download on Google Play. App Store coming soon. Your recovery data
          stays on your device.
        </p>

        <div className="flex flex-col items-center justify-center gap-3 pt-2 sm:flex-row sm:gap-4">
          <a
            href={PLAY_STORE_URL}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex transition-transform hover:scale-[1.03] focus-visible:outline focus-visible:outline-3 focus-visible:outline-offset-2 focus-visible:outline-[#3B82F6]"
          >
            {/* Official Google Play badge asset */}
            <Image
              src="/badges/google-play.png"
              alt="Get it on Google Play"
              width={180}
              height={70}
              className="h-[60px] w-auto"
              unoptimized
              priority
            />
          </a>

          <div
            className="relative inline-flex cursor-default"
            aria-disabled="true"
            title="App Store listing coming soon"
          >
            {/* Official App Store badge — not linked until listing is live */}
            <Image
              src="/badges/app-store.svg"
              alt="Download on the App Store — Coming soon"
              width={148}
              height={50}
              className="h-[50px] w-auto opacity-45 grayscale"
              unoptimized
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
