import { ReactNode } from "react";
import { Header } from "./Header";
import { Footer } from "./Footer";

export function PageShell({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col bg-background">
      <Header />
      <main className="flex-1">{children}</main>
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
    <section className="bg-gradient-hero text-primary-foreground">
      <div className="container-page py-16 md:py-20">
        {eyebrow && (
          <div className="mb-4 text-xs font-semibold uppercase tracking-widest text-gold">
            {eyebrow}
          </div>
        )}
        <h1 className="max-w-3xl text-balance text-3xl font-bold leading-tight md:text-5xl">{title}</h1>
        {description && (
          <p className="mt-4 max-w-2xl text-sm text-primary-foreground/80 md:text-base">{description}</p>
        )}
      </div>
    </section>
  );
}
