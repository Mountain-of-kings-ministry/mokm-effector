import type { Route } from "./+types/home";
import Navbar from "../sections/Navbar";
import Sidebar from "../sections/Sidebar";
import Hero from "../sections/Hero";
import Features from "../sections/Features";
import TechStack from "../sections/TechStack";
import Roadmap from "../sections/Roadmap";

export function meta({}: Route.MetaArgs) {
  return [
    { title: "MOKM Effector — Next-Generation Motion Graphics Suite" },
    { name: "description", content: "An open-source, node-based motion graphics suite built in C++ and Qt 6. High-efficiency 2D/3D animation, procedural workflows, and native performance on all hardware." },
    { name: "keywords", content: "motion graphics, animation, open source, node-based, C++, Qt, ThorVG, Filament, procedural animation, video design" },
    { property: "og:title", content: "MOKM Effector — Next-Generation Motion Graphics Suite" },
    { property: "og:description", content: "An open-source, node-based motion graphics suite built in C++ and Qt 6. High-efficiency 2D/3D animation and procedural workflows." },
    { property: "og:type", content: "website" },
    { name: "twitter:card", content: "summary_large_image" },
    { name: "twitter:title", content: "MOKM Effector — Next-Generation Motion Graphics Suite" },
    { name: "twitter:description", content: "An open-source, node-based motion graphics suite built in C++ and Qt 6. High-efficiency 2D/3D animation and procedural workflows." },
  ];
}

export default function Home() {
  return (
    <div className="flex flex-col h-screen bg-[var(--color-surface)] dark:bg-[var(--color-surface-dark)] text-[var(--color-text)] dark:text-[var(--color-text-dark)] overflow-hidden font-sans">
      <Navbar />
      
      <div className="flex flex-1 min-h-0 overflow-hidden">
        <Sidebar />
        
        {/* Project Bin / Features */}
        <aside className="w-64 border-r border-[var(--color-border)] dark:border-[var(--color-border-dark)] bg-[var(--color-base)] dark:bg-[var(--color-base-dark)] overflow-y-auto hidden md:block">
          <Features />
        </aside>

        <div className="flex flex-1 flex-col min-w-0">
          {/* Main Canvas / Hero */}
          <main className="flex-1 relative overflow-hidden bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)]">
            <Hero />
          </main>

          {/* Timeline / Roadmap */}
          <section className="h-48 border-t border-[var(--color-border)] dark:border-[var(--color-border-dark)] bg-[var(--color-base)] dark:bg-[var(--color-base-dark)] overflow-x-auto">
            <Roadmap />
          </section>
        </div>

        {/* Inspector / Tech Stack */}
        <aside className="w-72 border-l border-[var(--color-border)] dark:border-[var(--color-border-dark)] bg-[var(--color-base)] dark:bg-[var(--color-base-dark)] overflow-y-auto hidden lg:block">
          <TechStack />
        </aside>
      </div>

      {/* Footer / Status Bar */}
      <footer className="h-6 border-t border-[var(--color-border)] dark:border-[var(--color-border-dark)] bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)] flex items-center justify-between px-3 text-[10px] text-[var(--color-text-muted)] dark:text-[var(--color-text-muted-dark)] select-none">
        <div className="flex items-center gap-4">
          <span>Ready</span>
          <span>Composition: Main_Render</span>
          <span>Frame: 0 / 240</span>
        </div>
        <div className="flex items-center gap-4">
          <span>Engine: ThorVG</span>
          <span>GPU: Vulkan</span>
          <span>Memory: 42MB</span>
        </div>
      </footer>
    </div>
  );
}

