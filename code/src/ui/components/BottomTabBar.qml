// import QtQuick
// import QtQuick.Controls
// import QtQuick.Layouts
// import mokm_effector

// Rectangle {
//     id: root
//     implicitHeight: 30
//     Layout.fillWidth: true
//     color: Theme.background
//     border.color: Theme.border
//     border.width: 1

//     property int currentIndex: 0

//     RowLayout {
//         anchors.fill: parent
//         anchors.margins: 0
//         spacing: 0

//         Repeater {
//             model: ["Timeline", "Node Editor", "Keyframes"]
//             delegate: Rectangle {
//                 Layout.fillHeight: true
//                 Layout.preferredWidth: 120
//                 color: root.currentIndex === index ? Theme.secondary : "transparent"

//                 Rectangle {
//                     width: 1
//                     height: parent.height
//                     anchors.right: parent.right
//                     color: Theme.border
//                 }

//                 Text {
//                     anchors.centerIn: parent
//                     text: modelData
//                     color: root.currentIndex === index ? Theme.foreground : Theme.mutedForeground
//                     font.pixelSize: 12
//                     font.bold: root.currentIndex === index
//                 }

//                 MouseArea {
//                     anchors.fill: parent
//                     cursorShape: Qt.PointingHandCursor
//                     hoverEnabled: true
//                     onEntered: if (root.currentIndex !== index)
//                         parent.color = Theme.secondaryHover
//                     onExited: if (root.currentIndex !== index)
//                         parent.color = "transparent"
//                     onClicked: root.currentIndex = index
//                 }
//             }
//         }

//         Item {
//             Layout.fillWidth: true
//         } // spacer
//     }
// }

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root

    implicitHeight: 30
    Layout.fillWidth: true

    color: Theme.background
    border.color: Theme.border
    border.width: 1

    property int currentIndex: 0

    signal tabClicked(int index)

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: ["Timeline", "Node Editor", "Keyframes"]

            delegate: Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 120

                color: root.currentIndex === index ? Theme.secondary : "transparent"

                Rectangle {
                    width: 1
                    height: parent.height
                    anchors.right: parent.right
                    color: Theme.border
                }

                Text {
                    anchors.centerIn: parent
                    text: modelData

                    color: root.currentIndex === index ? Theme.foreground : Theme.mutedForeground

                    font.pixelSize: 12
                    font.bold: root.currentIndex === index
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        root.currentIndex = index;
                        root.tabClicked(index);
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
