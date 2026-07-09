"use client";

import { motion, useReducedMotion } from "motion/react";
import { smoothScrollToId } from "@/lib/smooth-scroll";

const STEPS = [
  {
    n: "01",
    title: "Bring your discharge papers",
    body: "Photograph or import documents. Text is extracted on your phone — nothing is uploaded to RxMind servers.",
  },
  {
    n: "02",
    title: "Organize into your plan",
    body: "Turn instructions into checklists, medication schedules, and tasks you control and edit yourself.",
  },
  {
    n: "03",
    title: "Track progress privately",
    body: "Log how you feel, mark milestones, and get generic reminders — all stored in an encrypted local database.",
  },
] as const;

export function HowItWorks() {
  const prefersReducedMotion = useReducedMotion();
  const float = !prefersReducedMotion;

  return (
    <section id="how-it-works" className="bg-white px-4 py-24 md:py-32">
      <div className="mx-auto max-w-6xl">
        <div className="mb-14 max-w-xl">
          <span className="mb-4 inline-block rounded-full bg-orange-100 px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-orange-800">
            Recovery companion
          </span>
          <h2 className="text-4xl font-extrabold leading-tight tracking-tight text-slate-900 md:text-5xl">
            Healing doesn&apos;t have to feel like a hospital chore.
          </h2>
          <p className="mt-5 text-lg font-medium leading-relaxed text-slate-600">
            RxMind turns discharge instructions into trackable tasks on your
            phone — private, offline-friendly, and designed for everyday
            recovery.
          </p>
        </div>

        <div className="grid items-center gap-16 lg:grid-cols-2">
          <ol className="relative space-y-0">
            {STEPS.map((step, i) => (
              <li key={step.n} className="relative flex gap-5 pb-10 last:pb-0">
                {i < STEPS.length - 1 && (
                  <div
                    className="absolute left-[1.35rem] top-12 h-[calc(100%-1.5rem)] w-px border-l-2 border-dashed border-slate-200"
                    aria-hidden="true"
                  />
                )}
                <div className="relative z-10 flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-[#1E1E24] text-sm font-bold text-white shadow-md">
                  {step.n}
                </div>
                <div className="pt-1">
                  <h3 className="mb-2 text-lg font-bold text-slate-900">
                    {step.title}
                  </h3>
                  <p className="text-sm font-medium leading-relaxed text-slate-600 md:text-base">
                    {step.body}
                  </p>
                </div>
              </li>
            ))}
          </ol>

          <div className="relative h-[420px] w-full">
            <div className="absolute inset-0 flex flex-col justify-center overflow-hidden rounded-[3rem] bg-gradient-to-tr from-indigo-50 via-blue-50 to-emerald-50 p-8 shadow-inner">
              <motion.div
                animate={float ? { y: [0, -10, 0] } : undefined}
                transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
                className="mb-6 ml-4 w-5/6 rounded-[2rem] border border-white bg-white/90 p-5 shadow-[0_8px_30px_rgb(0,0,0,0.04)] backdrop-blur-sm"
              >
                <div className="mb-3 flex items-center gap-3.5">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-orange-100 text-lg">
                    🏃
                  </div>
                  <div>
                    <div className="mb-1.5 h-2.5 w-24 rounded-full bg-slate-200" />
                    <div className="h-2 w-32 rounded-full bg-slate-100" />
                  </div>
                  <span className="ml-auto text-xs font-bold text-slate-400">
                    9:30 AM
                  </span>
                </div>
                <div className="mt-4 h-2 w-full overflow-hidden rounded-full bg-slate-100">
                  <div className="h-full w-3/4 rounded-full bg-emerald-400" />
                </div>
                <div className="mt-3 flex items-center justify-between text-xs font-semibold text-slate-500">
                  <span>Morning stretch</span>
                  <span className="text-emerald-600">75% done</span>
                </div>
              </motion.div>

              <motion.div
                animate={float ? { y: [0, 10, 0] } : undefined}
                transition={{
                  duration: 5,
                  repeat: Infinity,
                  ease: "easeInOut",
                  delay: 1,
                }}
                className="relative ml-auto mr-4 w-5/6 rounded-[2rem] border border-white bg-white/90 p-5 shadow-[0_8px_30px_rgb(0,0,0,0.04)] backdrop-blur-sm"
              >
                <div className="absolute -right-3 -top-3 flex h-8 w-8 items-center justify-center rounded-full bg-indigo-500 text-xs font-bold text-white shadow-md">
                  +1
                </div>
                <div className="flex items-center gap-3.5">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-pink-100 text-lg">
                    💊
                  </div>
                  <div className="flex-1">
                    <div className="mb-1.5 h-2.5 w-16 rounded-full bg-slate-200" />
                    <div className="h-2 w-28 rounded-full bg-slate-100" />
                  </div>
                  <span className="rounded-full bg-pink-50 px-2 py-0.5 text-xs font-bold text-pink-600">
                    Next reminder
                  </span>
                </div>
              </motion.div>
            </div>
            <p className="sr-only">
              Illustrative app preview with sample recovery tasks. No real
              patient data.
            </p>
          </div>
        </div>

        <div className="mt-12">
          <motion.button
            type="button"
            onClick={() => smoothScrollToId("download")}
            whileHover={prefersReducedMotion ? undefined : { scale: 1.04, y: -2 }}
            whileTap={prefersReducedMotion ? undefined : { scale: 0.97 }}
            className="inline-flex cursor-pointer rounded-full bg-slate-900 px-7 py-3 text-sm font-bold text-white transition-colors hover:bg-slate-800"
          >
            Get the app
          </motion.button>
        </div>
      </div>
    </section>
  );
}
