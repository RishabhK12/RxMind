import { DISCLAIMER } from "@/lib/config";

export function DisclaimerStrip() {
  return (
    <aside
      className="border-l-4 border-[#3B82F6] bg-[#F9FAFB] px-4 py-3 text-sm font-medium leading-relaxed text-[#4B5563] md:px-6"
      role="note"
    >
      {DISCLAIMER}
    </aside>
  );
}
