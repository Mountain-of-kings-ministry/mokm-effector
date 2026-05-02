import { 
  Box, 
  Layers, 
  Zap, 
  Settings, 
  MousePointer2, 
  Hand, 
  Search, 
  Plus,
  Network
} from "lucide-react";

export default function Sidebar() {
  const tools = [
    { icon: MousePointer2, label: "Select", active: true },
    { icon: Hand, label: "Pan" },
    { icon: Box, label: "3D View" },
    { icon: Network, label: "Node Editor" },
    { icon: Layers, label: "Timeline" },
    { icon: Zap, label: "Render" },
  ];

  const bottomTools = [
    { icon: Plus, label: "Add" },
    { icon: Search, label: "Find" },
    { icon: Settings, label: "Settings" },
  ];

  return (
    <aside className="w-12 flex-shrink-0 border-r border-[var(--color-border)] dark:border-[var(--color-border-dark)] bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)] flex flex-col items-center py-4 justify-between">
      <div className="flex flex-col items-center gap-4">
        {tools.map((tool, i) => (
          <button
            key={i}
            className={`p-2 rounded-lg transition-colors ${
              tool.active 
                ? "bg-[var(--color-primary)]/20 text-[var(--color-primary)] dark:text-[var(--color-primary-dark)]" 
                : "text-[var(--color-text-muted)] dark:text-[var(--color-text-muted-dark)] hover:bg-[var(--color-border)] dark:hover:bg-[var(--color-border-dark)]"
            }`}
            title={tool.label}
          >
            <tool.icon className="w-5 h-5" />
          </button>
        ))}
      </div>

      <div className="flex flex-col items-center gap-4">
        {bottomTools.map((tool, i) => (
          <button
            key={i}
            className="p-2 rounded-lg text-[var(--color-text-muted)] dark:text-[var(--color-text-muted-dark)] hover:bg-[var(--color-border)] dark:hover:bg-[var(--color-border-dark)] transition-colors"
            title={tool.label}
          >
            <tool.icon className="w-5 h-5" />
          </button>
        ))}
      </div>
    </aside>
  );
}
