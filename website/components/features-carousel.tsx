"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import {
  motion,
  animate,
  useMotionValue,
  useReducedMotion,
  type PanInfo,
} from "motion/react";
import {
  Bell,
  ClipboardList,
  HeartPulse,
  Shield,
  CalendarCheck,
  ChevronLeft,
  ChevronRight,
} from "lucide-react";

const FEATURES = [
  {
    title: "Medication schedule reminders",
    body: "Log your medications and get timely, generic reminders that fit your day — without putting drug names on your lock screen.",
    icon: Bell,
    accent: "bg-pink-100 text-pink-600",
    disc: "bg-pink-200/50",
    chip: "Reminders",
  },
  {
    title: "Wellness & recovery logs",
    body: "Track how you feel, tasks, and milestones with simple, friendly logging that stays private on your phone.",
    icon: HeartPulse,
    accent: "bg-emerald-100 text-emerald-600",
    disc: "bg-emerald-200/45",
    chip: "Logging",
  },
  {
    title: "Discharge checklists",
    body: "Import discharge documents for on-device text extraction and turn them into checklists you organize yourself.",
    icon: ClipboardList,
    accent: "bg-blue-100 text-blue-600",
    disc: "bg-blue-200/45",
    chip: "Checklists",
  },
  {
    title: "On-device privacy sandbox",
    body: "Recovery plans and logs live in an encrypted local database. No cloud sync of your health data to RxMind servers.",
    icon: Shield,
    accent: "bg-violet-100 text-violet-600",
    disc: "bg-violet-200/45",
    chip: "Privacy",
  },
  {
    title: "Follow-up day planner",
    body: "Keep appointments, tasks, and recovery milestones in one calm timeline you can review offline anytime.",
    icon: CalendarCheck,
    accent: "bg-amber-100 text-amber-700",
    disc: "bg-amber-200/45",
    chip: "Planning",
  },
] as const;

export function FeaturesCarousel() {
  const prefersReducedMotion = useReducedMotion();
  const [index, setIndex] = useState(0);
  const [width, setWidth] = useState(0);
  const viewportRef = useRef<HTMLDivElement>(null);
  const x = useMotionValue(0);
  const animRef = useRef<ReturnType<typeof animate> | null>(null);

  const snapTo = useCallback(
    (i: number) => {
      if (!width) return;
      animRef.current?.stop();
      const target = -i * width;
      if (prefersReducedMotion) {
        x.set(target);
        return;
      }
      animRef.current = animate(x, target, {
        type: "spring",
        stiffness: 240,
        damping: 28,
        mass: 0.85,
      });
    },
    [prefersReducedMotion, width, x]
  );

  useEffect(() => {
    const el = viewportRef.current;
    if (!el) return;
    const measure = () => setWidth(el.offsetWidth);
    measure();
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  useEffect(() => {
    snapTo(index);
  }, [index, snapTo]);

  const goTo = useCallback((next: number) => {
    setIndex(((next % FEATURES.length) + FEATURES.length) % FEATURES.length);
  }, []);

  const prev = useCallback(() => goTo(index - 1), [goTo, index]);
  const next = useCallback(() => goTo(index + 1), [goTo, index]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const section = document.getElementById("features");
      if (
        !section?.contains(document.activeElement) &&
        document.activeElement !== document.body
      ) {
        return;
      }
      if (e.key === "ArrowLeft") {
        e.preventDefault();
        prev();
      }
      if (e.key === "ArrowRight") {
        e.preventDefault();
        next();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [prev, next]);

  const onDragStart = () => {
    animRef.current?.stop();
  };

  const onDragEnd = (_: unknown, info: PanInfo) => {
    if (!width) return;
    const offset = info.offset.x;
    const velocity = info.velocity.x;
    let nextIndex = index;
    if (offset < -width * 0.18 || velocity < -450) nextIndex = index + 1;
    else if (offset > width * 0.18 || velocity > 450) nextIndex = index - 1;
    nextIndex = Math.max(0, Math.min(FEATURES.length - 1, nextIndex));
    setIndex(nextIndex);
    snapTo(nextIndex);
  };

  return (
    <section
      id="features"
      className="relative overflow-hidden bg-[#F9FAFB] px-4 py-24 md:py-32"
      aria-roledescription="carousel"
      aria-label="Recovery features"
    >
      <div className="mx-auto max-w-5xl">
        <div className="mb-12 flex flex-col gap-6 md:mb-14 md:flex-row md:items-end md:justify-between">
          <div className="max-w-2xl">
            <span className="mb-4 inline-block rounded-full bg-violet-100 px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-violet-700">
              Smarter home recovery
            </span>
            <h2 className="text-4xl font-extrabold leading-tight tracking-tight text-slate-900 md:text-5xl">
              Your recovery schedule, under your control.
            </h2>
          </div>

          <div className="flex items-center gap-2 self-start md:self-auto">
            <button
              type="button"
              onClick={prev}
              disabled={index === 0}
              aria-label="Previous feature"
              className="flex h-11 w-11 items-center justify-center rounded-full border border-slate-200 bg-white text-slate-700 shadow-sm transition-all hover:border-slate-300 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-35"
            >
              <ChevronLeft className="h-5 w-5" aria-hidden="true" />
            </button>
            <button
              type="button"
              onClick={next}
              disabled={index === FEATURES.length - 1}
              aria-label="Next feature"
              className="flex h-11 w-11 items-center justify-center rounded-full border border-slate-200 bg-white text-slate-700 shadow-sm transition-all hover:border-slate-300 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-35"
            >
              <ChevronRight className="h-5 w-5" aria-hidden="true" />
            </button>
          </div>
        </div>

        <div ref={viewportRef} className="overflow-hidden rounded-[2.5rem]">
          <motion.div
            className="flex cursor-grab touch-pan-y active:cursor-grabbing"
            style={{ x }}
            drag={prefersReducedMotion || width === 0 ? false : "x"}
            dragConstraints={
              width
                ? {
                    left: -(FEATURES.length - 1) * width,
                    right: 0,
                  }
                : undefined
            }
            dragElastic={0.14}
            onDragStart={onDragStart}
            onDragEnd={onDragEnd}
          >
            {FEATURES.map((feature, i) => {
              const Icon = feature.icon;
              return (
                <article
                  key={feature.title}
                  className="relative min-h-[280px] shrink-0 overflow-hidden border border-slate-100/80 bg-white p-8 shadow-sm md:p-12"
                  style={{ width: width ? width : "100%", minWidth: width ? width : "100%" }}
                  aria-roledescription="slide"
                  aria-label={`${i + 1} of ${FEATURES.length}: ${feature.title}`}
                  aria-hidden={i !== index}
                >
                  <div
                    className={`pointer-events-none absolute -right-10 -top-10 h-48 w-48 rounded-full ${feature.disc} blur-3xl`}
                    aria-hidden="true"
                  />
                  <div
                    className={`pointer-events-none absolute -bottom-16 -left-8 h-40 w-40 rounded-full ${feature.disc} blur-3xl opacity-70`}
                    aria-hidden="true"
                  />

                  <div className="relative z-10 flex flex-col gap-8 md:flex-row md:items-center md:gap-12">
                    <div
                      className={`flex h-16 w-16 shrink-0 items-center justify-center rounded-full ${feature.accent} md:h-20 md:w-20`}
                    >
                      <Icon className="h-8 w-8 md:h-9 md:w-9" aria-hidden="true" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <span className="mb-3 inline-block rounded-full bg-slate-100 px-3 py-1 text-xs font-bold uppercase tracking-wider text-slate-500">
                        {feature.chip}
                      </span>
                      <h3 className="mb-3 text-2xl font-extrabold tracking-tight text-slate-900 md:text-3xl">
                        {feature.title}
                      </h3>
                      <p className="max-w-xl text-base font-medium leading-relaxed text-slate-600 md:text-lg">
                        {feature.body}
                      </p>
                      <div
                        className="mt-8 h-1.5 w-20 rounded-full bg-gradient-to-r from-[#3B82F6] via-[#A855F7] to-[#F43F5E] opacity-80"
                        aria-hidden="true"
                      />
                    </div>
                  </div>
                </article>
              );
            })}
          </motion.div>
        </div>

        <div
          className="mt-8 flex items-center justify-center gap-2"
          role="tablist"
          aria-label="Feature slides"
        >
          {FEATURES.map((f, i) => (
            <button
              key={f.title}
              type="button"
              role="tab"
              aria-selected={i === index}
              aria-label={`Show ${f.title}`}
              onClick={() => goTo(i)}
              className="group relative flex h-8 w-8 items-center justify-center"
            >
              <span
                className={`block h-2 rounded-full transition-all duration-500 ease-out ${
                  i === index
                    ? "w-8 bg-[#3B82F6]"
                    : "w-2 bg-slate-300 group-hover:bg-slate-400"
                }`}
              />
            </button>
          ))}
        </div>

        <p className="mt-4 text-center text-sm font-medium text-slate-400">
          {String(index + 1).padStart(2, "0")} /{" "}
          {String(FEATURES.length).padStart(2, "0")}
          <span className="mx-2 text-slate-300">·</span>
          Drag or use arrows
        </p>
      </div>
    </section>
  );
}
