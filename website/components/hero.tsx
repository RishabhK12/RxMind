"use client";

import { useEffect, useState } from "react";
import {
  motion,
  useMotionValue,
  useSpring,
  useReducedMotion,
} from "motion/react";
import { smoothScrollToId } from "@/lib/smooth-scroll";

export function Hero() {
  const prefersReducedMotion = useReducedMotion();
  const [isHeroToggleActive, setIsHeroToggleActive] = useState(true);
  const [isSliderActive, setIsSliderActive] = useState(false);
  const [mounted, setMounted] = useState(false);

  const dragX = useMotionValue(0);
  const dragY = useMotionValue(0);
  const springX = useSpring(dragX, { stiffness: 280, damping: 18, mass: 0.7 });
  const springY = useSpring(dragY, { stiffness: 280, damping: 18, mass: 0.7 });

  useEffect(() => setMounted(true), []);

  const float = !prefersReducedMotion && mounted;
  const spring = prefersReducedMotion
    ? { duration: 0 }
    : { type: "spring" as const, stiffness: 260, damping: 22 };

  const softSpring = prefersReducedMotion
    ? { duration: 0 }
    : { type: "spring" as const, stiffness: 220, damping: 20 };

  return (
    <section className="relative mx-auto flex max-w-5xl flex-col items-center justify-center px-4 pb-24 pt-12 md:pb-32 md:pt-16">
      {float && (
        <div className="pointer-events-none absolute inset-0 z-0 hidden overflow-visible md:block">
          <motion.div
            animate={{ y: [0, -12, 0], rotate: [0, 8, 0] }}
            transition={{ duration: 5.5, repeat: Infinity, ease: "easeInOut" }}
            className="absolute left-[5%] top-[40%] h-8 w-8 opacity-40"
          >
            <svg viewBox="0 0 24 24" fill="none" className="text-[#10B981] drop-shadow-sm">
              <path
                d="M12 4V20M4 12H20"
                stroke="currentColor"
                strokeWidth="6"
                strokeLinecap="round"
              />
            </svg>
          </motion.div>

          <motion.div
            animate={{ y: [0, 10, 0], rotate: [0, -6, 0] }}
            transition={{
              duration: 6,
              repeat: Infinity,
              ease: "easeInOut",
              delay: 0.8,
            }}
            className="absolute right-[5%] top-[45%] h-8 w-8 opacity-40"
          >
            <div className="flex h-8 w-8 rotate-45 items-center justify-center rounded-full bg-[#FBBF24] shadow-sm">
              <div className="h-1 w-3 rounded-full bg-amber-600/30" />
              <div className="ml-1 h-1 w-3 rounded-full bg-amber-600/30" />
            </div>
          </motion.div>

          <motion.div
            animate={{ y: [0, -8, 0], scale: [1, 1.08, 1] }}
            transition={{
              duration: 4.5,
              repeat: Infinity,
              ease: "easeInOut",
              delay: 1.4,
            }}
            className="absolute left-[12%] top-[12%] opacity-30"
          >
            <svg
              viewBox="0 0 24 24"
              fill="currentColor"
              className="h-5 w-5 text-[#3B82F6]"
              aria-hidden="true"
            >
              <path d="M12 0L14.6 9.4L24 12L14.6 14.6L12 24L9.4 14.6L0 12L9.4 9.4L12 0Z" />
            </svg>
          </motion.div>
        </div>
      )}

      <div className="relative z-10 flex w-full select-none flex-col items-center gap-6 tracking-tight md:gap-8">
        {/* Row 1 */}
        <div className="flex flex-wrap items-center justify-center gap-4 text-6xl font-extrabold leading-none md:gap-6 md:text-8xl lg:text-[110px]">
          <motion.span
            className="text-slate-900"
            whileHover={prefersReducedMotion ? undefined : { y: -2 }}
            transition={softSpring}
          >
            master
          </motion.span>

          <motion.div
            whileHover={
              prefersReducedMotion
                ? undefined
                : { scale: 1.08, rotate: 6 }
            }
            whileTap={prefersReducedMotion ? undefined : { scale: 0.92 }}
            animate={
              float
                ? { boxShadow: ["0 10px 20px rgba(16,185,129,0.2)", "0 14px 28px rgba(16,185,129,0.32)", "0 10px 20px rgba(16,185,129,0.2)"] }
                : undefined
            }
            transition={
              float
                ? { duration: 3.5, repeat: Infinity, ease: "easeInOut" }
                : softSpring
            }
            className="flex h-16 w-16 cursor-pointer items-center justify-center rounded-full bg-[#10B981] text-slate-900 shadow-lg shadow-emerald-500/20 md:h-24 md:w-24 lg:h-28 lg:w-28"
            role="presentation"
          >
            <motion.svg
              width="40%"
              height="40%"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="3"
              strokeLinecap="round"
              strokeLinejoin="round"
              aria-hidden="true"
              animate={float ? { x: [0, 3, 0] } : undefined}
              transition={{ duration: 2.2, repeat: Infinity, ease: "easeInOut" }}
            >
              <path d="M5 12h14M12 5l7 7-7 7" />
            </motion.svg>
          </motion.div>

          <button
            type="button"
            onClick={() => setIsHeroToggleActive(!isHeroToggleActive)}
            className="relative flex shrink-0 cursor-pointer items-center border-none bg-transparent p-0"
            aria-pressed={isHeroToggleActive}
            aria-label="Toggle recovery mode ornament"
          >
            <motion.div
              whileHover={prefersReducedMotion ? undefined : { scale: 1.03 }}
              transition={softSpring}
              className={`flex h-16 w-32 rounded-full bg-gradient-to-r from-[#3B82F6] via-[#A855F7] to-[#F43F5E] p-1 shadow-xl shadow-purple-500/10 md:h-24 md:w-48 md:p-2 lg:h-28 lg:w-56 ${
                isHeroToggleActive ? "justify-end" : "justify-start"
              }`}
            >
              <motion.div
                layout={!prefersReducedMotion}
                whileHover={prefersReducedMotion ? undefined : { scale: 1.06 }}
                className="relative flex h-14 w-14 items-center justify-center rounded-full border border-white/50 bg-white/95 shadow-[0_8px_16px_rgba(0,0,0,0.1)] backdrop-blur-sm md:h-20 md:w-20 lg:h-24 lg:w-24"
                transition={spring}
              >
                <div className="flex h-8 w-8 items-center justify-center rounded-full border-[1.5px] border-slate-200 md:h-12 md:w-12">
                  <motion.div
                    className="h-1.5 w-1.5 rounded-full bg-[#3B82F6] md:h-2.5 md:w-2.5"
                    animate={float ? { scale: [1, 1.35, 1] } : undefined}
                    transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
                  />
                </div>
              </motion.div>
            </motion.div>
          </button>
        </div>

        {/* Row 2 */}
        <div className="z-20 -mt-2 flex flex-wrap items-center justify-center gap-4 text-6xl font-extrabold leading-none md:gap-6 md:text-8xl lg:text-[110px]">
          <div className="relative flex h-16 w-40 shrink-0 items-center md:h-24 md:w-56 lg:h-28 lg:w-64">
            {/* Draggable amber disc — springs back on release */}
            <motion.div
              style={
                prefersReducedMotion
                  ? undefined
                  : { x: springX, y: springY }
              }
              drag={!prefersReducedMotion}
              dragConstraints={{ left: -36, right: 72, top: -28, bottom: 28 }}
              dragElastic={0.35}
              onDragEnd={() => {
                dragX.set(0);
                dragY.set(0);
              }}
              whileHover={prefersReducedMotion ? undefined : { scale: 1.06 }}
              whileTap={prefersReducedMotion ? undefined : { scale: 0.96, cursor: "grabbing" }}
              className="absolute left-0 z-20 flex h-16 w-16 cursor-grab touch-none items-center justify-center rounded-full bg-[#FBBF24] shadow-lg shadow-amber-500/20 active:cursor-grabbing md:h-24 md:w-24 lg:h-28 lg:w-28"
              role="slider"
              aria-label="Draggable amber control — drag and release to spring back"
              aria-valuemin={0}
              aria-valuemax={100}
              aria-valuenow={50}
              tabIndex={0}
            >
              <motion.div
                className="h-3 w-3 rounded-full bg-[#3B82F6] shadow-sm md:h-4 md:w-4"
                animate={float ? { scale: [1, 1.2, 1] } : undefined}
                transition={{ duration: 2.4, repeat: Infinity, ease: "easeInOut" }}
              />
            </motion.div>

            <button
              type="button"
              onClick={() => setIsSliderActive(!isSliderActive)}
              className="absolute left-10 z-10 flex h-12 w-32 cursor-pointer items-center rounded-full border border-slate-100 bg-white/80 px-4 shadow-[0_8px_16px_rgba(0,0,0,0.06)] backdrop-blur-md transition-shadow hover:shadow-[0_12px_24px_rgba(0,0,0,0.08)] md:left-14 md:h-16 md:w-48 md:px-6 lg:left-16 lg:h-20 lg:w-56"
              aria-pressed={isSliderActive}
              aria-label="Progress slider ornament"
            >
              <div className="relative h-1 w-full rounded-full bg-slate-900">
                <motion.div
                  animate={{
                    left: isSliderActive ? "calc(100% - 1rem)" : "0%",
                  }}
                  className="absolute top-1/2 h-5 w-5 -translate-y-1/2 rounded-full bg-[#10B981] md:h-6 md:w-6"
                  transition={spring}
                  whileHover={prefersReducedMotion ? undefined : { scale: 1.15 }}
                />
              </div>
            </button>
          </div>

          <motion.span
            className="ml-4 text-slate-900"
            whileHover={prefersReducedMotion ? undefined : { y: -2 }}
            transition={softSpring}
          >
            your
          </motion.span>

          <motion.div
            whileHover={
              prefersReducedMotion
                ? undefined
                : { y: -8, scale: 1.03, rotate: -1 }
            }
            transition={softSpring}
            animate={
              float
                ? {
                    y: [0, -4, 0],
                    transition: {
                      duration: 4.5,
                      repeat: Infinity,
                      ease: "easeInOut",
                    },
                  }
                : undefined
            }
            className="z-20 flex h-16 w-32 shrink-0 items-center justify-center gap-2 rounded-full border border-slate-100 bg-white/80 px-4 shadow-[0_12px_24px_rgba(0,0,0,0.08)] backdrop-blur-md md:h-24 md:w-48 md:gap-4 lg:h-28 lg:w-56"
            role="img"
            aria-label="Medication and heart icons"
          >
            <motion.span
              className="text-2xl md:text-4xl"
              aria-hidden="true"
              animate={float ? { rotate: [0, -8, 8, 0] } : undefined}
              transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
            >
              💊
            </motion.span>
            <motion.span
              className="relative text-3xl drop-shadow-md md:text-5xl"
              aria-hidden="true"
              animate={float ? { scale: [1, 1.06, 1] } : undefined}
              transition={{ duration: 2.8, repeat: Infinity, ease: "easeInOut" }}
            >
              ❤️
              <span className="absolute bottom-0 right-0 text-xs md:text-sm">🩺</span>
            </motion.span>
          </motion.div>
        </div>

        {/* Row 3 */}
        <div className="z-30 -mt-2 flex flex-wrap items-center justify-center gap-4 text-6xl font-extrabold leading-none md:gap-6 md:text-8xl lg:text-[110px]">
          <div className="relative flex h-16 w-32 shrink-0 items-center justify-center md:h-24 md:w-48 lg:h-28 lg:w-56">
            <motion.div
              className="absolute left-0 h-16 w-16 rounded-full bg-gradient-to-tr from-rose-400 to-purple-500 opacity-90 shadow-sm md:left-4 md:h-24 md:w-24 lg:h-28 lg:w-28"
              animate={float ? { scale: [1, 1.05, 1] } : undefined}
              transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
            />
            <motion.div
              className="absolute right-0 h-16 w-16 rounded-full bg-gradient-to-tr from-blue-400 to-cyan-300 opacity-90 shadow-sm md:right-4 md:h-24 md:w-24 lg:h-28 lg:w-28"
              animate={float ? { scale: [1, 1.06, 1] } : undefined}
              transition={{
                duration: 4.5,
                repeat: Infinity,
                ease: "easeInOut",
                delay: 0.5,
              }}
            />

            {/* Hoverable, not clickable */}
            <motion.div
              whileHover={
                prefersReducedMotion
                  ? undefined
                  : {
                      scale: 1.08,
                      y: -4,
                      boxShadow: "0 14px 28px rgba(0,0,0,0.14)",
                    }
              }
              transition={softSpring}
              className="relative z-10 flex h-10 w-28 cursor-default items-center justify-center gap-1.5 rounded-full border border-white bg-white/95 shadow-[0_8px_16px_rgba(0,0,0,0.1)] backdrop-blur-xl md:h-12 md:w-40 md:gap-2 lg:h-14 lg:w-48"
              role="presentation"
              aria-hidden="false"
              title="Plan details"
            >
              <svg
                className="h-4 w-4 shrink-0 text-indigo-600 md:h-5 md:w-5"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <line x1="12" y1="3" x2="12" y2="21" />
                <path d="M12 18.5c-3-1-4-3-4-4.5s2-2.5 4-4 4-2.5 4-4-2-2.5-4-3.5" />
                <circle cx="12" cy="2.5" r="1.2" fill="currentColor" />
              </svg>
              <span className="text-[10px] font-bold tracking-tight text-slate-800 md:text-sm lg:text-base">
                plan details
              </span>
            </motion.div>
          </div>

          <motion.span
            className="text-slate-900"
            whileHover={prefersReducedMotion ? undefined : { y: -2 }}
            transition={softSpring}
          >
            recovery
          </motion.span>

          <motion.div
            className="ml-2 hidden w-12 lg:block lg:w-16"
            aria-hidden="true"
            animate={
              float
                ? { opacity: [0.55, 1, 0.55], pathLength: [0.8, 1, 0.8] }
                : undefined
            }
            transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
          >
            <svg
              viewBox="0 0 50 20"
              fill="none"
              stroke="#111827"
              strokeWidth="3.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <motion.path
                d="M0 10h10l5-8 10 16 5-8h20"
                animate={
                  float
                    ? {
                        strokeDashoffset: [0, 12, 0],
                      }
                    : undefined
                }
                transition={{ duration: 3.5, repeat: Infinity, ease: "easeInOut" }}
                style={{ strokeDasharray: "6 4" }}
              />
            </svg>
          </motion.div>
        </div>
      </div>

      {/* Dashed connectors */}
      <div className="pointer-events-none absolute inset-0 z-0 mx-auto mt-24 hidden max-w-5xl overflow-visible lg:block">
        <svg
          className="absolute inset-0 h-[600px] w-full"
          viewBox="0 0 1000 600"
          fill="none"
          style={{ overflow: "visible" }}
          aria-hidden="true"
        >
          <motion.path
            d="M 280 320 Q 280 430 400 420"
            stroke="#111827"
            strokeWidth="3.5"
            strokeDasharray="8,8"
            strokeLinecap="round"
            animate={float ? { strokeDashoffset: [0, -16] } : undefined}
            transition={{ duration: 8, repeat: Infinity, ease: "linear" }}
          />
          <polygon points="400,420 390,412 390,428" fill="#3B82F6" />
          <motion.path
            d="M 680 180 Q 780 180 750 280"
            stroke="#111827"
            strokeWidth="3.5"
            strokeDasharray="8,8"
            strokeLinecap="round"
            animate={float ? { strokeDashoffset: [0, -16] } : undefined}
            transition={{ duration: 9, repeat: Infinity, ease: "linear" }}
          />
          <polygon points="750,280 740,270 760,270" fill="#3B82F6" />
        </svg>
      </div>

      {/* Subcopy + CTAs */}
      <div className="relative z-10 mx-auto mt-20 w-full max-w-4xl px-6 md:mt-28">
        {float && (
          <>
            <motion.div
              animate={{ y: [0, -8, 0], rotate: [12, 18, 12] }}
              transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
              className="pointer-events-none absolute -left-2 top-0 hidden h-10 w-10 select-none items-center justify-center md:flex xl:-left-12"
            >
              <svg
                viewBox="0 0 24 24"
                fill="currentColor"
                className="h-8 w-8 text-[#10B981] opacity-80 drop-shadow-sm"
                aria-hidden="true"
              >
                <path d="M19 10h-5V5a2 2 0 0 0-4 0v5H5a2 2 0 0 0 0 4h5v5a2 2 0 0 0 4 0v-5h5a2 2 0 0 0 0-4z" />
              </svg>
            </motion.div>
            <motion.div
              animate={{ y: [0, 6, 0], rotate: [-12, -18, -12] }}
              transition={{
                duration: 4.5,
                repeat: Infinity,
                ease: "easeInOut",
                delay: 0.6,
              }}
              className="pointer-events-none absolute -right-2 top-4 hidden select-none text-3xl opacity-90 drop-shadow-sm md:block xl:-right-12"
              aria-hidden="true"
            >
              🩹
            </motion.div>
            <motion.div
              animate={{ rotate: [0, 20, 0], scale: [1, 1.1, 1] }}
              transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
              className="pointer-events-none absolute -bottom-4 left-8 hidden h-6 w-6 select-none md:block xl:left-0"
            >
              <svg
                viewBox="0 0 24 24"
                fill="currentColor"
                className="h-6 w-6 text-[#3B82F6] opacity-80"
                aria-hidden="true"
              >
                <path d="M12 0L14.6 9.4L24 12L14.6 14.6L12 24L9.4 14.6L0 12L9.4 9.4L12 0Z" />
              </svg>
            </motion.div>
            <motion.div
              animate={{ rotate: [0, -15, 0], scale: [1, 1.12, 1] }}
              transition={{
                duration: 5.5,
                repeat: Infinity,
                ease: "easeInOut",
                delay: 1,
              }}
              className="pointer-events-none absolute -bottom-6 right-8 hidden h-6 w-6 select-none md:block xl:right-0"
            >
              <svg
                viewBox="0 0 24 24"
                fill="currentColor"
                className="h-6 w-6 text-[#93C5FD] opacity-80"
                aria-hidden="true"
              >
                <path d="M12 0L14.6 9.4L24 12L14.6 14.6L12 24L9.4 14.6L0 12L9.4 9.4L12 0Z" />
              </svg>
            </motion.div>
          </>
        )}

        <div className="flex flex-col items-center text-center">
          <h1 className="sr-only">master your recovery</h1>
          <p className="mb-10 max-w-3xl px-4 text-lg font-medium leading-relaxed text-slate-600 md:text-xl">
            RxMind helps you organize post-hospital recovery on your phone —
            private recovery plans, medication schedules, and progress tracking
            that stay on-device.
          </p>
          <div className="z-20 flex flex-col items-center gap-4 sm:flex-row">
            <motion.button
              type="button"
              onClick={() => smoothScrollToId("download")}
              whileHover={prefersReducedMotion ? undefined : { scale: 1.04, y: -2 }}
              whileTap={prefersReducedMotion ? undefined : { scale: 0.97 }}
              transition={softSpring}
              className="cursor-pointer rounded-full bg-[#1E1E24] px-8 py-4 text-sm font-bold text-white shadow-lg transition-colors hover:bg-black hover:shadow-xl md:text-base"
            >
              Get the app
            </motion.button>
            <motion.button
              type="button"
              onClick={() => smoothScrollToId("how-it-works")}
              whileHover={prefersReducedMotion ? undefined : { x: 4 }}
              transition={softSpring}
              className="cursor-pointer border-none bg-transparent px-4 py-2 text-sm font-bold text-slate-800 underline underline-offset-4 transition-colors hover:text-black"
            >
              See how it works
            </motion.button>
          </div>
        </div>
      </div>
    </section>
  );
}
