import { ArrowRight, Play, Maximize2, MousePointer2 } from "lucide-react";

export default function Hero() {
  return (
    <div className="absolute inset-0 flex flex-col items-center justify-center p-8 select-none">
      {/* Viewport Grid Background */}
      <div 
        className="absolute inset-0 opacity-[0.05] dark:opacity-[0.1]"
        style={{
          backgroundImage: `linear-gradient(var(--color-border) 1px, transparent 1px), linear-gradient(90deg, var(--color-border) 1px, transparent 1px)`,
          backgroundSize: "40px 40px",
          backgroundPosition: "center center"
        }}
      />

      {/* Viewport Center Crosshair */}
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-4 h-4 opacity-20 pointer-events-none">
        <div className="absolute top-1/2 left-0 w-full h-px bg-current" />
        <div className="absolute left-1/2 top-0 w-px h-full bg-current" />
      </div>

      <div className="relative z-10 max-w-2xl text-center">
        {/* Animated Headline */}
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-md border border-[var(--color-primary)]/30 bg-[var(--color-primary)]/5 mb-6">
          <span className="w-2 h-2 rounded-full bg-[var(--color-primary)] animate-pulse" />
          <span className="text-[10px] font-bold uppercase tracking-widest text-[var(--color-primary)]">
            Active Composition: World_Freedom_v1
          </span>
        </div>

        <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black tracking-tighter text-[var(--color-text)] dark:text-[var(--color-text-dark)] leading-[0.9] mb-4 uppercase italic">
          Next-Gen <br />
          <span className="text-[var(--color-primary)] dark:text-[var(--color-primary-dark)]">
            Motion Graphics
          </span>
        </h1>

        <p className="text-sm sm:text-base text-[var(--color-text-muted)] dark:text-[var(--color-text-muted-dark)] max-w-md mx-auto mb-8 leading-tight font-medium">
          MOKM Effector: A high-efficiency, procedural animation suite built for 
          uncompromising performance on any hardware.
        </p>

        {/* CTA as App Buttons */}
        <div className="flex items-center justify-center gap-3">
          <button className="flex items-center gap-2 px-6 py-2 rounded bg-[var(--color-primary)] text-[var(--color-text-inverse)] text-xs font-bold uppercase tracking-wider hover:brightness-110 transition-all shadow-lg shadow-[var(--color-glow)]">
            <Play className="w-3 h-3 fill-current" />
            Start Creating
          </button>
          <a 
            href="/docs"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 px-6 py-2 rounded border border-[var(--color-border)] bg-[var(--color-base)]/50 text-xs font-bold uppercase tracking-wider hover:bg-[var(--color-border)] transition-all"
          >
            Documentation
          </a>
        </div>
      </div>

      {/* Viewport Toolbar Overlay */}
      <div className="absolute bottom-4 left-1/2 -translate-x-1/2 flex items-center gap-1 p-1 rounded-lg bg-[var(--color-base)]/80 dark:bg-[var(--color-base-dark)]/80 border border-[var(--color-border)] dark:border-[var(--color-border-dark)] backdrop-blur-sm shadow-xl">
        {[MousePointer2, Maximize2].map((Icon, i) => (
          <button key={i} className="p-1.5 rounded hover:bg-[var(--color-border)] dark:hover:bg-[var(--color-border-dark)] text-[var(--color-text-muted)]">
            <Icon className="w-3.5 h-3.5" />
          </button>
        ))}
        <div className="w-px h-3 bg-[var(--color-border)] mx-1" />
        <span className="text-[10px] font-mono px-2 text-[var(--color-text-muted)]">100%</span>
      </div>
    </div>
  );
}
