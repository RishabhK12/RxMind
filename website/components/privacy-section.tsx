import Link from "next/link";
import { ShieldCheck, Sparkles } from "lucide-react";

export function PrivacySection() {
  return (
    <section
      id="privacy"
      className="relative overflow-hidden bg-gradient-to-b from-white to-slate-50 px-4 py-24 md:py-32"
    >
      <div className="mx-auto flex max-w-5xl flex-col items-center gap-16 md:flex-row-reverse">
        <div className="flex-1 space-y-6">
          <span className="inline-block rounded-full bg-emerald-100 px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-emerald-800">
            On-device privacy
          </span>
          <h2 className="text-4xl font-extrabold leading-tight tracking-tight text-slate-900 md:text-5xl">
            Your health data. Protected locally.
          </h2>
          <p className="text-lg font-medium leading-relaxed text-slate-600">
            Recovery logs, medication schedules, and extracted discharge text
            stay on your phone. rxmind does not sync Consumer Health Data to
            cloud servers. You can erase everything anytime in Settings.
          </p>
          <div className="flex flex-wrap gap-4 pt-2">
            <div className="flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-800 shadow-sm">
              <ShieldCheck className="h-4 w-4 text-emerald-500" aria-hidden="true" />
              Fully local engine
            </div>
            <div className="flex items-center gap-2 rounded-full border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-800 shadow-sm">
              <Sparkles className="h-4 w-4 text-emerald-500" aria-hidden="true" />
              Encrypted local database
            </div>
          </div>
          <div className="flex flex-wrap gap-4 pt-2 text-sm font-semibold">
            <Link
              href="/privacy/"
              className="text-[#3B82F6] underline underline-offset-4 hover:text-blue-700"
            >
              Privacy Policy
            </Link>
            <Link
              href="/data-safety/"
              className="text-[#3B82F6] underline underline-offset-4 hover:text-blue-700"
            >
              Data Safety
            </Link>
          </div>
        </div>

        <div className="relative w-full flex-1">
          <div className="relative flex min-h-[380px] flex-col justify-between overflow-hidden rounded-[3rem] bg-slate-900 p-8 text-slate-100 shadow-2xl md:p-10">
            <div
              className="pointer-events-none absolute right-0 top-0 h-64 w-64 rounded-full bg-indigo-500/10 blur-3xl"
              aria-hidden="true"
            />
            <div className="relative z-10 flex items-start justify-between">
              <div className="rounded-2xl border border-slate-700 bg-slate-800 p-3">
                <svg
                  className="h-6 w-6 text-indigo-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  strokeWidth="2"
                  aria-hidden="true"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                  />
                </svg>
              </div>
              <span className="rounded-full border border-emerald-500/20 bg-emerald-400/10 px-3 py-1 font-mono text-xs text-emerald-400">
                Secure Local Sandbox
              </span>
            </div>

            <div className="relative z-10 my-8 space-y-4">
              <div className="text-2xl font-bold tracking-tight">
                rxmind sandbox active
              </div>
              <p className="text-sm leading-relaxed text-slate-400">
                Plans, logs, and reminders stay inside your device sandbox.
                Master keys are protected by platform secure hardware where
                available.
              </p>
            </div>

            <div className="relative z-10 flex items-center gap-3 rounded-2xl border border-slate-700/50 bg-slate-800/50 p-4">
              <div
                className="h-3 w-3 animate-pulse rounded-full bg-emerald-500"
                aria-hidden="true"
              />
              <div className="font-mono text-xs text-slate-300">
                Local database encrypted with AES-256 (SQLCipher)
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
