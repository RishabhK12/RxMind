"use client";

import Link from "next/link";
import { LogoMark } from "./logo-mark";
import { smoothScrollToId } from "@/lib/smooth-scroll";

export function SiteFooter() {
  const onAnchor = (e: React.MouseEvent, id: string) => {
    if (window.location.pathname === "/" || window.location.pathname === "") {
      e.preventDefault();
      smoothScrollToId(id);
    }
  };

  return (
    <footer className="border-t border-slate-100 bg-white px-6 py-12">
      <div className="mx-auto flex max-w-5xl flex-col items-center justify-between gap-8 md:flex-row">
        <div className="flex flex-col items-center gap-2 md:items-start">
          <Link href="/" className="flex items-center gap-2 text-[#3B82F6]">
            <LogoMark className="h-5 w-5" />
            <span className="text-lg font-extrabold tracking-tight text-slate-800">
              rxmind
            </span>
          </Link>
          <p className="max-w-xs text-center text-sm font-medium text-slate-400 md:text-left">
            On-device recovery organizer. Not a medical device.
          </p>
        </div>

        <div className="flex flex-wrap justify-center gap-6 text-sm font-medium text-slate-400">
          <Link
            href="/#features"
            onClick={(e) => onAnchor(e, "features")}
            className="hover:text-slate-600"
          >
            Features
          </Link>
          <Link
            href="/#how-it-works"
            onClick={(e) => onAnchor(e, "how-it-works")}
            className="hover:text-slate-600"
          >
            How It Works
          </Link>
          <Link
            href="/#faq"
            onClick={(e) => onAnchor(e, "faq")}
            className="hover:text-slate-600"
          >
            FAQ
          </Link>
          <Link href="/privacy/" className="hover:text-slate-600">
            Privacy
          </Link>
          <Link href="/terms/" className="hover:text-slate-600">
            Terms
          </Link>
          <Link href="/data-safety/" className="hover:text-slate-600">
            Data Safety
          </Link>
        </div>

        <p className="text-sm font-medium text-slate-400">
          &copy; 2026 rxmind
        </p>
      </div>
    </footer>
  );
}
