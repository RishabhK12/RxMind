import { SiteChrome } from "@/components/site-chrome";
import { Hero } from "@/components/hero";
import { FeaturesCarousel } from "@/components/features-carousel";
import { HowItWorks } from "@/components/how-it-works";
import { PrivacySection } from "@/components/privacy-section";
import { FaqSection } from "@/components/faq-section";
import { DownloadSection } from "@/components/download-section";

export default function HomePage() {
  return (
    <SiteChrome>
      <Hero />
      <FeaturesCarousel />
      <HowItWorks />
      <PrivacySection />
      <FaqSection />
      <DownloadSection />
    </SiteChrome>
  );
}
