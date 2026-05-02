import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".."

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Composition Info
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: "transparent"
            
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.paddingLarge
                
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: Theme.primary
                }
                Text {
                    text: "Active Composition: Main_Render.comp"
                    font: Theme.smallFontBold
                    color: Theme.primary
                    opacity: 0.8
                }
            }
        }

        // Viewport Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.8
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "MOKM EFFECTOR"
                    font: Theme.headerFont
                    color: Theme.primary
                    style: Text.Outline
                    styleColor: Theme.glow
                }
                
                Text {
                    anchors.top: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: 8
                    text: "1920 x 1080 | 24.00 fps"
                    font: Theme.monoFont
                    color: Theme.textSecondary
                }
            }
        }
    }
}
