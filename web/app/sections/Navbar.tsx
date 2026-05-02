import { Clapperboard, Play } from "lucide-react";
import { BsGithub } from "react-icons/bs";

export default function Navbar() {
  const menuItems = ["File", "Edit", "View", "Composition", "Window", "Help"];

  return (
    <nav className="h-10 border-b border-[var(--color-border)] dark:border-[var(--color-border-dark)] bg-[var(--color-panel)] dark:bg-[var(--color-panel-dark)] flex items-center justify-between px-3 select-none">
      <div className="flex items-center gap-6">
        {/* Logo & Title */}
        <div className="flex items-center gap-2">
          <Clapperboard className="w-4 h-4 text-[var(--color-primary)] dark:text-[var(--color-primary-dark)]" />
          <span className="text-[11px] font-bold tracking-tight text-[var(--color-text)] dark:text-[var(--color-text-dark)] uppercase">
            MOKM <span className="text-[var(--color-primary)] dark:text-[var(--color-primary-dark)]">Effector</span>
          </span>
        </div>

        {/* Mock Menu Bar */}
        <div className="hidden lg:flex items-center gap-4">
          {menuItems.map((item) => (
            <button
              key={item}
              className="text-[11px] font-medium text-[var(--color-text-muted)] dark:text-[var(--color-text-muted-dark)] hover:text-[var(--color-text)] dark:hover:text-[var(--color-text-dark)] transition-colors cursor-default"
            >
              {item}
            </button>
          ))}
        </div>
      </div>

      {/* Right Controls */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-1 mr-2 px-2 py-0.5 rounded bg-[var(--color-base)] dark:bg-[var(--color-base-dark)] border border-[var(--color-border)] dark:border-[var(--color-border-dark)]">
          <Play className="w-3 h-3 text-green-500 fill-green-500" />
          <span className="text-[10px] font-mono text-[var(--color-text-muted)] dark:text-[var(--color-text-muted-dark)]">
            00:00:00:00
          </span>
        </div>
        
        <div className="h-4 w-px bg-[var(--color-border)] dark:bg-[var(--color-border-dark)] mx-1" />
        
        <a
          href="https://github.com/Mountain-of-kings-ministry/mokm-effector"
          target="_blank"
          rel="noopener noreferrer"
          className="p-1.5 rounded hover:bg-[var(--color-border)] dark:hover:bg-[var(--color-border-dark)] text-[var(--color-text-muted)] dark:text-[var(--color-text-muted-dark)] transition-colors"
          title="GitHub Repository"
        >
          <BsGithub className="w-4 h-4" />
        </a>
      </div>
    </nav>
  );
}
