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
                text: "PROJECT BIN"
                font: Theme.smallFontBold
                color: Theme.textSecondary
            }
        }
        
        // Asset List
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: [
                { name: "Node_Logic.dag", type: "Logic", icon: "network.svg" },
                { name: "Hybrid_Timeline.comp", type: "Timeline", icon: "layers.svg" },
                { name: "Scene_3D.usd", type: "3D", icon: "box.svg" },
                { name: "ThorVG_Core.bin", type: "Binary", icon: "zap.svg" }
            ]
            delegate: ItemDelegate {
                width: parent.width
                height: 32
                
                contentItem: RowLayout {
                    spacing: 8
                    Item {
                        width: 16; height: 16
                        Rectangle {
                            anchors.fill: parent
                            color: Theme.primary
                            opacity: 0.1
                            radius: 2
                        }
                        // Icon placeholder
                    }
                    Text {
                        text: modelData.name
                        font: Theme.smallFont
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                    }
                    Text {
                        text: modelData.type
                        font: Theme.smallFont
                        color: Theme.textSecondary
                        opacity: 0.5
                    }
                }
            }
        }
    }
}
