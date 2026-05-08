pragma Singleton
import QtQuick 2.15

QtObject {
    // Base (dark monochrome — no pure black)
    readonly property color background: "#09090b"      // zinc-950
    readonly property color foreground: "#fafafa"      // zinc-50

    // Primary (Gold)
    readonly property color primary: "#eab308"      // gold-500
    readonly property color primaryHover: "#ca8a04" // gold-600

    // Accent
    readonly property color accent: "#3b82f6"       // blue-500
    readonly property color accentHover: "#2563eb"  // blue-600

    // Secondary surfaces (slightly lighter than background)
    readonly property color secondary: "#18181b"       // zinc-900
    readonly property color secondaryHover: "#27272a"  // zinc-800

    // Muted / subtle UI
    readonly property color muted: "#27272a"           // zinc-800
    readonly property color mutedForeground: "#a1a1aa" // zinc-400

    // Borders & input
    readonly property color border: "#27272a"          // zinc-800
    readonly property color input: "#09090b"           // zinc-950

    // States
    readonly property color success: "#22c55e"
    readonly property color warning: "#f59e0b"
    readonly property color error: "#ef4444"
}
