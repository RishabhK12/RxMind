import type { Metadata } from "next";
import { SiteChrome } from "@/components/site-chrome";

export const metadata: Metadata = {
  title: "Terms of Use — rxmind",
  description: "rxmind terms of use for personal wellness organization.",
};

export default function TermsPage() {
  return (
    <SiteChrome mainClassName="mx-auto max-w-3xl px-6 py-12 md:py-16">
      <article className="legal-prose">
        <h1>Terms of Use</h1>
        <p>
          <strong>Effective date:</strong> July 8, 2026
        </p>
        <p>
          By using rxmind you agree to use the app for personal wellness
          organization only. rxmind does not provide medical advice, diagnosis,
          or treatment recommendations.
        </p>
        <p>
          You are responsible for verifying all extracted information against
          your original discharge documents and consulting licensed healthcare
          professionals for medical decisions.
        </p>
        <p>
          rxmind is provided as-is. To the extent permitted by law, we disclaim
          warranties and limit liability for personal use of the application.
        </p>
      </article>
    </SiteChrome>
  );
}
