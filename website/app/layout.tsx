import type { Metadata } from "next";
import { Plus_Jakarta_Sans } from "next/font/google";
import { BASE_PATH } from "@/lib/config";
import "./globals.css";

const plusJakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  variable: "--font-plus-jakarta",
  display: "swap",
});

export const metadata: Metadata = {
  title: "rxmind — private on-device recovery organizer",
  description:
    "Organize post-hospital recovery on your phone — private recovery plans, medication schedules, and progress tracking that stay on-device.",
  icons: {
    icon: [
      { url: `${BASE_PATH}/favicon.ico`, sizes: "any" },
      {
        url: `${BASE_PATH}/favicon-32.png`,
        sizes: "32x32",
        type: "image/png",
      },
      {
        url: `${BASE_PATH}/favicon-16.png`,
        sizes: "16x16",
        type: "image/png",
      },
      { url: `${BASE_PATH}/icon.png`, type: "image/png" },
    ],
    apple: [{ url: `${BASE_PATH}/apple-touch-icon.png`, sizes: "180x180" }],
    shortcut: `${BASE_PATH}/favicon.ico`,
  },
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
