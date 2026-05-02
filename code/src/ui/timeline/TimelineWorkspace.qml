import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Ruler
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            color: Theme.base
            border.color: Theme.border
            
            RowLayout {
                anchors.fill: parent
                spacing: 0
                Repeater {
                    model: 10
                    delegate: Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Text {
                            anchors.centerIn: parent
                            text: (index * 60) + "f"
                            font: Theme.monoFont
                            color: Theme.textSecondary
                            opacity: 0.5
                        }
                        Rectangle {
                            anchors.right: parent.right
                            width: 1; height: 4; color: Theme.textSecondary; opacity: 0.2
                        }
                    }
                }
            }
        }

        // Tracks Area
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Track Headers
            Rectangle {
                Layout.preferredWidth: 150
                Layout.fillHeight: true
                color: Theme.surface
                border.color: Theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 1
                    
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 32
                        color: Theme.base; radius: 2
                        Text { anchors.centerIn: parent; text: "V1: Composition"; font: Theme.smallFont; color: Theme.textPrimary }
                    }
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 32
                        color: Theme.base; radius: 2
                        Text { anchors.centerIn: parent; text: "A1: Audio_Track"; font: Theme.smallFont; color: Theme.textSecondary }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // Clips Canvas
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Theme.surface
                clip: true

                // Dummy Clips
                Row {
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    spacing: 2
                    x: 20
                    
                    Rectangle { width: 120; height: 24; radius: 2; color: Theme.primary; opacity: 0.3; border.color: Theme.primary; border.width: 1 }
                    Rectangle { width: 240; height: 24; radius: 2; color: Theme.accent; opacity: 0.3; border.color: Theme.accent; border.width: 1 }
                }
                
                // Playhead
                Rectangle {
                    x: 100
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Theme.primary
                    Rectangle {
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 9; height: 9; radius: 1; rotation: 45; color: Theme.primary
                    }
                }
            }
        }
    }
}
