import { ReactNode } from "react";
import { Header } from "./Header";
import { Footer } from "./Footer";

export function PageShell({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      <Header />
      <main className="public-page flex-1">{children}</main>
      <Footer />
    </div>
  );
}

export function PageHero({
  eyebrow,
  title,
  description,
}: {
  eyebrow?: string;
  title: string;
  description?: string;
}) {
  return (
    <section className="public-hero">
      <div className="container-page py-10 md:py-12">
        {eyebrow && (
          <div className="public-eyebrow mb-4">
            {eyebrow}
          </div>
        )}
        <h1 className="max-w-4xl text-balance text-3xl font-bold leading-tight md:text-5xl">{title}</h1>
        {description && (
          <p className="mt-4 max-w-2xl text-base leading-relaxed text-primary-foreground/80 md:text-lg">{description}</p>
        )}
      </div>
    </section>
  );
}
