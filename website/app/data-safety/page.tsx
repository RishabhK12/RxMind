import type { Metadata } from "next";
import { SiteChrome } from "@/components/site-chrome";

export const metadata: Metadata = {
  title: "Data Safety — RxMind",
  description:
    "RxMind data safety summary for Google Play and App Store privacy labels.",
};

export default function DataSafetyPage() {
  return (
    <SiteChrome mainClassName="mx-auto max-w-3xl px-6 py-12 md:py-16">
      <article className="legal-prose">
        <h1>Data Safety Summary</h1>
        <p>
          Summary for Google Play Data Safety and App Store Privacy labels.
          Version 2026-07-08.
        </p>

        <div className="overflow-x-auto">
          <table>
            <thead>
              <tr>
                <th>Data type</th>
                <th>Collected</th>
                <th>Shared</th>
                <th>Encrypted</th>
                <th>Purpose</th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>Health &amp; fitness (medications, tasks, discharge text)</td>
                <td>Yes, on-device</td>
                <td>No</td>
                <td>Yes (SQLCipher)</td>
                <td>App functionality</td>
              </tr>
              <tr>
                <td>Photos / documents</td>
                <td>Yes, on-device OCR</td>
                <td>No</td>
                <td>Yes</td>
                <td>Document organization</td>
              </tr>
              <tr>
                <td>Contacts (picker selection)</td>
                <td>Yes, user-selected only</td>
                <td>No</td>
                <td>Yes</td>
                <td>Emergency / clinical contacts</td>
              </tr>
              <tr>
                <td>App interactions (AI chat)</td>
                <td>Yes, on-device</td>
                <td>No</td>
                <td>Yes</td>
                <td>Wellness clarification</td>
              </tr>
            </tbody>
          </table>
        </div>

        <p>
          <strong>Deletion:</strong> Settings → Delete All Data (type DELETE to
          confirm).
        </p>
        <p>
          <strong>Third-party sharing:</strong> None for Consumer Health Data.
        </p>
      </article>
    </SiteChrome>
  );
}
