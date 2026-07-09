"use client";

import Link from "next/link";
import { useState } from "react";
import { Menu, X } from "lucide-react";
import { LogoMark } from "./logo-mark";
import { smoothScrollToId } from "@/lib/smooth-scroll";

const NAV_LINKS = [
  { href: "/#features", label: "Features" },
  { href: "/#how-it-works", label: "How It Works" },
  { href: "/#privacy", label: "Privacy First" },
  { href: "/#faq", label: "FAQ" },
];

export function SiteNav() {
  const [open, setOpen] = useState(false);

  const onAnchor = (e: React.MouseEvent, href: string) => {
    if (href.startsWith("/#")) {
      const id = href.slice(2);
      if (window.location.pathname === "/" || window.location.pathname === "") {
        e.preventDefault();
        smoothScrollToId(id);
        setOpen(false);
      }
    }
  };

  return (
    <header className="sticky top-0 z-50 border-b border-slate-100/80 bg-white/90 backdrop-blur-md">
      <nav className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4 md:px-12 md:py-5">
        <Link
          href="/"
          className="flex items-center gap-2 text-[#3B82F6]"
          aria-label="RxMind home"
        >
          <LogoMark />
          <span className="text-2xl font-extrabold tracking-tight text-[#111827]">
            rxmind
          </span>
        </Link>

        <div className="hidden items-center gap-8 text-sm font-semibold text-slate-600 md:flex">
          {NAV_LINKS.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              onClick={(e) => onAnchor(e, link.href)}
              className="bg-transparent transition-colors hover:text-slate-900"
            >
              {link.label}
            </Link>
          ))}
        </div>

        <div className="flex items-center gap-3">
          <Link
            href="/#download"
            onClick={(e) => onAnchor(e, "/#download")}
            className="rounded-full border border-slate-200 px-5 py-2 text-sm font-semibold text-slate-800 transition-colors hover:bg-slate-50"
          >
            Get Started
          </Link>
          <button
            type="button"
            className="inline-flex rounded-full p-2 text-slate-700 md:hidden"
            aria-expanded={open}
            aria-controls="mobile-nav"
            aria-label={open ? "Close menu" : "Open menu"}
            onClick={() => setOpen((v) => !v)}
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </nav>

      {open && (
        <div
          id="mobile-nav"
          className="border-t border-slate-100 bg-white px-6 py-4 md:hidden"
        >
          <ul className="flex flex-col gap-3">
            {NAV_LINKS.map((link) => (
              <li key={link.href}>
                <Link
                  href={link.href}
                  onClick={(e) => onAnchor(e, link.href)}
                  className="block py-2 text-sm font-semibold text-slate-700"
                >
                  {link.label}
                </Link>
              </li>
            ))}
          </ul>
        </div>
      )}
    </header>
  );
}
