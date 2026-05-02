import { ChevronDown, Info } from "lucide-react";

const technologies = [
  { name: "C++20", category: "Language", value: "Native" },
  { name: "Qt 6.5+", category: "Framework", value: "6.5.3" },
  { name: "ThorVG", category: "Vector Engine", value: "v1.0" },
  { name: "Filament", category: "3D Rendering", value: "PBR" },
  { name: "USD", category: "Scene Desc", value: "Pixar" },
  { name: "QuickJS", category: "Scripting", value: "ES2023" },
  { name: "OpenTimelineIO", category: "Interchange", value: "OTIO" },
  { name: "OpenFX", category: "Plugin API", value: "v1.4" },
];

export default function TechStack() {
  return (
    <div className="flex flex-col h-full select-none text-[11px]">
      <div className="h-8 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)] flex items-center px-3 bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)]">
        <span className="text-[10px] font-bold uppercase tracking-wider opacity-60">Inspector</span>
      </div>
      
      <div className="flex-1 overflow-y-auto">
        <div className="p-3 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)]">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-10 h-10 rounded bg-[var(--color-primary)]/10 flex items-center justify-center">
              <Info className="w-5 h-5 text-[var(--color-primary)]" />
            </div>
            <div>
              <div className="font-bold">Project_Settings</div>
              <div className="text-[9px] opacity-50 uppercase">Configuration</div>
            </div>
          </div>
        </div>

        <div className="p-0">
          <div className="bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)]/30 px-3 py-1 flex items-center gap-1 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)]">
            <ChevronDown className="w-3 h-3 opacity-40" />
            <span className="font-bold opacity-60 uppercase text-[9px]">Technical_Stack</span>
          </div>

          <div className="p-3 space-y-3">
            {technologies.map((tech) => (
              <div key={tech.name} className="flex items-center">
                <span className="w-24 text-[var(--color-text-muted)] shrink-0 font-mono text-[10px]">{tech.name}</span>
                <div className="flex-1 h-6 bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)] border border-[var(--color-border)] dark:border-[var(--color-border-dark)] rounded px-2 flex items-center justify-between group hover:border-[var(--color-primary)] transition-colors">
                  <span className="truncate">{tech.value}</span>
                  <span className="text-[8px] opacity-0 group-hover:opacity-40 uppercase">{tech.category}</span>
                </div>
              </div>
            ))}
          </div>

          <div className="bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)]/30 px-3 py-1 flex items-center gap-1 border-y border-[var(--color-border)] dark:border-[var(--color-border-dark)] mt-4">
            <ChevronDown className="w-3 h-3 opacity-40" />
            <span className="font-bold opacity-60 uppercase text-[9px]">Target_Platforms</span>
          </div>
          <div className="p-3 space-y-2 opacity-60">
            <div className="flex items-center gap-2">
              <input type="checkbox" checked readOnly className="accent-[var(--color-primary)]" />
              <span>Windows (x64)</span>
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" checked readOnly className="accent-[var(--color-primary)]" />
              <span>macOS (Silicon/Intel)</span>
            </div>
            <div className="flex items-center gap-2">
              <input type="checkbox" checked readOnly className="accent-[var(--color-primary)]" />
              <span>Linux (X11/Wayland)</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

