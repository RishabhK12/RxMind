import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import "./globals.css";

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-plus-jakarta",
  display: "swap",
});

export const metadata: Metadata = {
  title: "RxMind — Private On-Device Recovery Organizer",
  description:
    "Organize post-hospital recovery on your phone — private recovery plans, medication schedules, and progress tracking that stay on-device.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={plusJakarta.variable}>
      <body className="min-h-screen bg-white font-sans text-[#111827] antialiased">
        {children}
      </body>
    </html>
  );
}
