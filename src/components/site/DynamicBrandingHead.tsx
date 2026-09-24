// Mengganti judul, ikon, dan theme-color secara dinamis
// sesuai pengaturan branding superadmin.
import { useEffect } from "react";
import { useSiteBranding } from "@/lib/site-settings";

export function DynamicBrandingHead() {
  const b = useSiteBranding();

  useEffect(() => {
    if (typeof document === "undefined") return;

    const appName = b.meta_site_title || b.brand_name || "Portal Pemerintah";
    const shortName = b.brand_name || "Portal";
    const icon = b.logo_url || "/icon-192.png";

    // Update <title>
    document.title = appName;

    // Update theme-color
    const setMeta = (name: string, content: string) => {
      let el = document.querySelector(`meta[name="${name}"]`) as HTMLMetaElement | null;
      if (!el) {
        el = document.createElement("meta");
        el.setAttribute("name", name);
        document.head.appendChild(el);
      }
      el.setAttribute("content", content);
    };
    setMeta("application-name", appName);
    setMeta("apple-mobile-web-app-title", shortName);
    setMeta("description", b.meta_site_description || "");

    // Update apple-touch-icon & favicon
    const setLink = (rel: string, href: string) => {
      let el = document.querySelector(`link[rel="${rel}"]`) as HTMLLinkElement | null;
      if (!el) {
        el = document.createElement("link");
        el.setAttribute("rel", rel);
        document.head.appendChild(el);
      }
      el.setAttribute("href", href);
    };
    setLink("apple-touch-icon", icon);
    setLink("icon", icon);
  }, [b]);

  return null;
}
