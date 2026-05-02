pragma Singleton
import QtQuick

QtObject {
    // Brand & High Priority
    readonly property color primary: "#FFD700"
    readonly property color secondary: "#FFCC10"
    readonly property color accent: "#E5B70A"
    
    // Backgrounds & Layers
    readonly property color surface: "#1A1B1F"    // Deep space
    readonly property color base: "#343840"       // Panels base
    readonly property color panel: "#4E5360"      // Component cards
    readonly property color border: "#4E5360"     // Same as panel for subtle division
    
    // Status & Glows
    readonly property color glow: "#26FFD700"     // 15% opacity primary
    readonly property color success: "#10B981"
    readonly property color warning: "#F59E0B"
    readonly property color danger: "#EF4444"

    // Text colors
    readonly property color textPrimary: "#F3F4F6"
    readonly property color textSecondary: "#9CA3AF"
    readonly property color textDisabled: "#666666"
    readonly property color textInverse: "#1A1B1F"

    // Generic geometry
    readonly property int radius: 4
    readonly property int paddingLarge: 16
    readonly property int paddingMedium: 8
    readonly property int paddingSmall: 4

    // Standard font
    readonly property font defaultFont: Qt.font({ family: "Inter", pixelSize: 13 })
    readonly property font defaultFontBold: Qt.font({ family: "Inter", pixelSize: 13, weight: Font.Bold })
    readonly property font headerFont: Qt.font({ family: "Inter", pixelSize: 18, weight: Font.Bold })
    readonly property font smallFont: Qt.font({ family: "Inter", pixelSize: 11 })
    readonly property font smallFontBold: Qt.font({ family: "Inter", pixelSize: 11, weight: Font.Bold })
    readonly property font monoFont: Qt.font({ family: "JetBrains Mono", pixelSize: 10 })
}
