import type {Metadata} from 'next';
import './globals.css';
import { Plus_Jakarta_Sans } from "next/font/google";
import { cn } from "@/lib/utils";

const plusJakartaSans = Plus_Jakarta_Sans({
  subsets: ['latin'],
  weight: ['300', '400', '500', '700'],
  variable: '--font-sans',
});

export const metadata: Metadata = {
  title: 'RxMind — Privacy-First On-Device Mobile Healthcare Assistant',
  description: 'RxMind is a hyper-secure, local-first on-device health assistant. No cloud sync. No telemetry.',
};

export default function RootLayout({children}: {children: React.ReactNode}) {
  return (
    <html lang="en" className={cn("font-sans", plusJakartaSans.variable)}>
      <body suppressHydrationWarning className="bg-background text-foreground min-h-screen antialiased selection:bg-primary/20 selection:text-primary">
        {children}
      </body>
    </html>
  );
}
