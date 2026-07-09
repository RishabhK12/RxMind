import type { Metadata } from "next";
import { SiteChrome } from "@/components/site-chrome";

export const metadata: Metadata = {
  title: "Privacy Policy — RxMind",
  description:
    "RxMind privacy policy: on-device storage, no cloud sync of Consumer Health Data.",
};

export default function PrivacyPage() {
  return (
    <SiteChrome mainClassName="mx-auto max-w-3xl px-6 py-12 md:py-16">
      <article className="legal-prose">
        <h1>Privacy Policy</h1>
        <p>
          <strong>Effective date:</strong> July 8, 2026 ·{" "}
          <strong>Version:</strong> 2026-07-08
        </p>

        <h2>Plain-Language Summary</h2>
        <p>
          RxMind is a personal recovery organizer that runs on your phone. The
          health information you enter or scan is stored <strong>on your device
          only</strong>. We do not operate cloud servers that receive, store, or
          process your health data. You can export a copy and permanently erase
          everything in Settings at any time.
        </p>

        <h2>Zero-Cloud, Local-Only Architecture</h2>
        <ul>
          <li>
            No developer cloud database for medications, discharge text, tasks,
            or chat history
          </li>
          <li>No sale of Consumer Health Data</li>
          <li>No advertising SDKs on health data screens</li>
          <li>
            OCR, parsing, reminders, and optional on-device AI run on your phone
          </li>
        </ul>

        <h2>Data Categories</h2>
        <p>
          Depending on how you use RxMind, locally processed information may
          include recovery documents, medications, tasks, follow-up contacts,
          profile preferences, and on-device AI interactions.
        </p>

        <h2>Encryption &amp; Security</h2>
        <p>
          Consumer Health Data is stored in an encrypted SQLCipher database.
          Master keys are protected by Android Keystore / iOS Secure Enclave
          where available.
        </p>

        <h2>Your Choices</h2>
        <p>
          You may withdraw consent and erase all data via{" "}
          <strong>Settings → Delete All Data</strong>. This performs a
          cryptographic wipe of local databases and secure storage.
        </p>

        <h2>Contact</h2>
        <p>
          Privacy contact:{" "}
          <a
            href="mailto:privacy@rxmind.app"
            className="font-semibold text-[#3B82F6] underline underline-offset-2"
          >
            privacy@rxmind.app
          </a>
        </p>
      </article>
    </SiteChrome>
  );
}
