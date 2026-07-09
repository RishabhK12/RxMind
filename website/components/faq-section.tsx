"use client";

import { useId, useState } from "react";
import { motion, AnimatePresence, useReducedMotion } from "motion/react";
import { ChevronDown } from "lucide-react";

const FAQ_DATA = [
  {
    q: "How does rxmind protect my privacy?",
    a: "rxmind is built for on-device use. Recovery data is processed and stored in your phone’s local sandbox and is not uploaded to rxmind servers.",
  },
  {
    q: "Can I import discharge instructions?",
    a: "Yes. Photograph or import documents for on-device text extraction. You review and organize the results into checklists and schedules yourself.",
  },
  {
    q: "Does it work offline?",
    a: "Yes. Core logging, reminders, and recovery plans work without an internet connection.",
  },
  {
    q: "Is rxmind medical advice?",
    a: "No. rxmind is not a medical device and does not diagnose, treat, or prescribe. Always consult licensed healthcare professionals for medical questions.",
  },
] as const;

export function FaqSection() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);
  const prefersReducedMotion = useReducedMotion();
  const baseId = useId();

  return (
    <section id="faq" className="bg-white px-4 py-24 md:py-32">
      <div className="mx-auto max-w-3xl">
        <div className="mb-14 text-center">
          <span className="mb-4 inline-block rounded-full bg-slate-100 px-4 py-1.5 text-xs font-bold uppercase tracking-wider text-slate-700">
            Frequently asked questions
          </span>
          <h2 className="text-4xl font-extrabold tracking-tight text-slate-900">
            Straight answers.
          </h2>
        </div>

        <div className="space-y-3">
          {FAQ_DATA.map((faq, idx) => {
            const isOpen = openIndex === idx;
            const panelId = `${baseId}-panel-${idx}`;
            const buttonId = `${baseId}-btn-${idx}`;
            return (
              <div
                key={faq.q}
                className="overflow-hidden rounded-[1.75rem] bg-[#F9FAFB] transition-colors"
              >
                <button
                  type="button"
                  id={buttonId}
                  aria-expanded={isOpen}
                  aria-controls={panelId}
                  onClick={() => setOpenIndex(isOpen ? null : idx)}
                  className="flex w-full cursor-pointer items-center gap-4 px-6 py-5 text-left transition-colors hover:bg-slate-100/60 md:px-8 md:py-6"
                >
                  <span
                    className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-white text-sm font-extrabold text-[#3B82F6] shadow-sm"
                    aria-hidden="true"
                  >
                    {String(idx + 1).padStart(2, "0")}
                  </span>
                  <span className="flex-1 text-base font-bold text-slate-900 md:text-lg">
                    {faq.q}
                  </span>
                  <ChevronDown
                    className={`h-5 w-5 shrink-0 text-slate-400 transition-transform duration-300 ${
                      isOpen ? "rotate-180" : ""
                    }`}
                    aria-hidden="true"
                  />
                </button>

                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      id={panelId}
                      role="region"
                      aria-labelledby={buttonId}
                      initial={
                        prefersReducedMotion
                          ? { height: "auto", opacity: 1 }
                          : { height: 0, opacity: 0 }
                      }
                      animate={{ height: "auto", opacity: 1 }}
                      exit={
                        prefersReducedMotion
                          ? { height: "auto", opacity: 0 }
                          : { height: 0, opacity: 0 }
                      }
                      transition={
                        prefersReducedMotion
                          ? { duration: 0 }
                          : { type: "spring", stiffness: 300, damping: 30 }
                      }
                      className="overflow-hidden"
                    >
                      <div className="border-t border-slate-200/50 px-6 pb-6 pl-[4.25rem] text-sm font-medium leading-relaxed text-slate-600 md:px-8 md:pb-7 md:pl-[5.25rem] md:text-base">
                        {faq.a}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}
