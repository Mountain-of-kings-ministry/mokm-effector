import { CheckCircle2, Circle, Timer, ChevronRight } from "lucide-react";

const phases = [
  {
    phase: "Phase 1",
    title: "Foundation",
    status: "done",
    frames: "0 - 120",
    color: "bg-blue-500/20 border-blue-500/50"
  },
  {
    phase: "Phase 2",
    title: "Core_Editing",
    status: "in-progress",
    frames: "120 - 240",
    color: "bg-[var(--color-primary)]/20 border-[var(--color-primary)]/50"
  },
  {
    phase: "Phase 3",
    title: "Node_Engine",
    status: "planned",
    frames: "240 - 360",
    color: "bg-purple-500/20 border-purple-500/50"
  },
  {
    phase: "Phase 4",
    title: "Animation",
    status: "planned",
    frames: "360 - 480",
    color: "bg-orange-500/20 border-orange-500/50"
  },
  {
    phase: "Phase 5",
    title: "Professional",
    status: "planned",
    frames: "480 - 600",
    color: "bg-emerald-500/20 border-emerald-500/50"
  },
  {
    phase: "Phase 6",
    title: "Optimization",
    status: "planned",
    frames: "600 - 720",
    color: "bg-pink-500/20 border-pink-500/50"
  },
];

export default function Roadmap() {
  return (
    <div className="flex flex-col h-full select-none">
      {/* Timeline Header / Ruler */}
      <div className="h-8 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)] flex items-center bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)]">
        <div className="w-48 border-r border-[var(--color-border)] dark:border-[var(--color-border-dark)] h-full flex items-center px-3">
          <span className="text-[10px] font-bold uppercase tracking-wider opacity-60">Timeline</span>
        </div>
        <div className="flex-1 h-full relative overflow-hidden">
          {/* Ruler Marks */}
          <div className="absolute inset-0 flex items-end">
            {Array.from({ length: 20 }).map((_, i) => (
              <div key={i} className="flex-1 flex flex-col items-center">
                <span className="text-[8px] opacity-30 mb-1">{i * 60}f</span>
                <div className="w-px h-2 bg-current opacity-20" />
              </div>
            ))}
          </div>
        </div>
      </div>
      
      {/* Timeline Tracks */}
      <div className="flex-1 overflow-y-auto">
        <div className="flex min-w-[1200px]">
          {/* Track Headers */}
          <div className="w-48 border-r border-[var(--color-border)] dark:border-[var(--color-border-dark)] shrink-0 bg-[var(--color-base)] dark:bg-[var(--color-base-dark)]">
            <div className="h-12 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)] flex items-center px-3 gap-2 hover:bg-[var(--color-panel)] transition-colors cursor-pointer group">
              <ChevronRight className="w-3 h-3 opacity-40 group-hover:rotate-90 transition-transform" />
              <span className="text-[10px] font-bold opacity-80 uppercase">Dev_Roadmap</span>
            </div>
            <div className="h-12 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)] flex items-center px-3 gap-2 opacity-40">
              <ChevronRight className="w-3 h-3" />
              <span className="text-[10px] font-bold uppercase">Audio_Engine</span>
            </div>
            <div className="h-12 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)] flex items-center px-3 gap-2 opacity-40">
              <ChevronRight className="w-3 h-3" />
              <span className="text-[10px] font-bold uppercase">UI_Refinement</span>
            </div>
          </div>

          {/* Track Content */}
          <div className="flex-1 relative bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)]/10">
            {/* Playhead Guide */}
            <div className="absolute top-0 bottom-0 left-[200px] w-px bg-[var(--color-primary)] z-10 shadow-[0_0_10px_var(--color-glow)]">
              <div className="absolute top-0 left-1/2 -translate-x-1/2 w-3 h-3 bg-[var(--color-primary)] rounded-b-sm" />
            </div>

            <div className="h-12 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)] flex items-center px-4 gap-1">
              {phases.map((phase, i) => (
                <div 
                  key={i}
                  className={`h-8 w-44 border rounded flex flex-col justify-center px-2 cursor-help transition-all hover:scale-[1.02] ${phase.color}`}
                  title={`${phase.title}: ${phase.status}`}
                >
                  <div className="flex items-center justify-between">
                    <span className="text-[9px] font-bold truncate">{phase.title}</span>
                    {phase.status === "done" ? (
                      <CheckCircle2 className="w-2.5 h-2.5 text-blue-500" />
                    ) : phase.status === "in-progress" ? (
                      <Timer className="w-2.5 h-2.5 text-[var(--color-primary)] animate-pulse" />
                    ) : (
                      <Circle className="w-2.5 h-2.5 opacity-30" />
                    )}
                  </div>
                  <span className="text-[7px] opacity-50 font-mono">{phase.frames}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

