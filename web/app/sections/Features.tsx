import { 
  Network, 
  Zap, 
  Plug, 
  Layers, 
  Box, 
  Maximize, 
  Monitor, 
  Repeat, 
  ChevronDown, 
  FileJson,
  Video
} from "lucide-react";

const features = [
  { icon: Network, title: "Node_Logic.dag", type: "Logic" },
  { icon: Layers, title: "Hybrid_Timeline.composition", type: "Timeline" },
  { icon: Repeat, title: "Procedural_Engine.solver", type: "Engine" },
  { icon: Maximize, title: "Responsive_Layout.layout", type: "System" },
  { icon: Box, title: "Scene_3D.usd", type: "3D Asset" },
  { icon: Zap, title: "ThorVG_Rasterizer.renderer", type: "Renderer" },
  { icon: Plug, title: "Plugin_Host.api", type: "API" },
  { icon: Monitor, title: "Native_Core.bin", type: "Binary" },
];

export default function Features() {
  return (
    <div className="flex flex-col h-full select-none">
      <div className="h-8 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)] flex items-center px-3 bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)]">
        <span className="text-[10px] font-bold uppercase tracking-wider opacity-60">Project Bin</span>
      </div>
      
      <div className="flex-1 p-2 space-y-4">
        {/* Assets Folder */}
        <div>
          <div className="flex items-center gap-1 mb-2">
            <ChevronDown className="w-3 h-3 opacity-40" />
            <span className="text-[11px] font-semibold opacity-80">Core_Features</span>
          </div>
          
          <div className="pl-4 space-y-1">
            {features.map((feature, i) => (
              <div 
                key={i}
                className="group flex items-center justify-between p-1.5 rounded hover:bg-[var(--color-primary)]/10 transition-colors cursor-pointer"
              >
                <div className="flex items-center gap-2">
                  <feature.icon className="w-3.5 h-3.5 text-[var(--color-primary)] dark:text-[var(--color-primary-dark)]" />
                  <span className="text-[11px] font-mono truncate max-w-[120px]">
                    {feature.title}
                  </span>
                </div>
                <span className="text-[9px] opacity-40 group-hover:opacity-100 transition-opacity">
                  {feature.type}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Assets Folder 2 */}
        <div>
          <div className="flex items-center gap-1 mb-2">
            <ChevronDown className="w-3 h-3 opacity-40" />
            <span className="text-[11px] font-semibold opacity-80">Documentation</span>
          </div>
          <div className="pl-4 space-y-1">
            <div className="flex items-center gap-2 p-1.5 rounded hover:bg-[var(--color-primary)]/10 cursor-pointer">
              <FileJson className="w-3.5 h-3.5 text-blue-400" />
              <span className="text-[11px] font-mono">README.md</span>
            </div>
            <div className="flex items-center gap-2 p-1.5 rounded hover:bg-[var(--color-primary)]/10 cursor-pointer">
              <Video className="w-3.5 h-3.5 text-red-400" />
              <span className="text-[11px] font-mono">Quick_Start.mp4</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

