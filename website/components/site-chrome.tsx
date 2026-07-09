import { DisclaimerStrip } from "./disclaimer-strip";
import { SiteFooter } from "./site-footer";
import { SiteNav } from "./site-nav";

export function SiteChrome({
  children,
  mainClassName = "",
}: {
  children: React.ReactNode;
  mainClassName?: string;
}) {
  return (
    <div className="min-h-screen overflow-x-hidden bg-white text-[#111827]">
      <SiteNav />
      <div className="mx-auto max-w-7xl px-4 pt-3 md:px-8">
        <DisclaimerStrip />
      </div>
      <main className={mainClassName}>{children}</main>
      <SiteFooter />
    </div>
  );
}
