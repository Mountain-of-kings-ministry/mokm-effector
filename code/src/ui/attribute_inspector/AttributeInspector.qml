import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: Theme.base
            border.color: Theme.border
            
            Text {
                anchors.centerIn: parent
                text: "INSPECTOR"
                font: Theme.smallFontBold
                color: Theme.textSecondary
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 1

                // Group 1
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    color: Theme.panel
                    opacity: 0.5
                    Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; text: "PROJECT PROPERTIES"; font: Theme.monoFont; color: Theme.textPrimary }
                }

                Repeater {
                    model: [
                        { name: "Language", value: "C++20" },
                        { name: "Framework", value: "Qt 6.5" },
                        { name: "Vector Engine", value: "ThorVG" },
                        { name: "3D Engine", value: "Filament" }
                    ]
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        Layout.leftMargin: 8
                        Layout.rightMargin: 8
                        
                        Text { text: modelData.name; font: Theme.smallFont; color: Theme.textSecondary; Layout.preferredWidth: 100 }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                            color: Theme.base
                            border.color: Theme.border
                            radius: 2
                            Text { anchors.centerIn: parent; text: modelData.value; font: Theme.monoFont; color: Theme.primary }
                        }
                    }
                }
            }
        }
    }
}
