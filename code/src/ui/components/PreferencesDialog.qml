import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Dialog {
    id: root
    title: qsTr("Preferences")
    modal: true
    anchors.centerIn: parent
    width: 400
    height: 250

    property var project: null

    background: Rectangle {
        color: Theme.background
        border.color: Theme.border
        border.width: 1
        radius: 8
    }

    header: Rectangle {
        color: Theme.secondary
        height: 40
        radius: 8
        Rectangle {
            // square off bottom corners
            height: 8
            width: parent.width
            anchors.bottom: parent.bottom
            color: Theme.secondary
        }
        Text {
            anchors.centerIn: parent
            text: root.title
            color: Theme.foreground
            font.pixelSize: 14
            font.bold: true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        Text {
            text: qsTr("Project Settings")
            color: Theme.accent
            font.bold: true
            font.pixelSize: 13
        }

        GridLayout {
            columns: 2
            rowSpacing: 12
            columnSpacing: 16

            Text {
                text: qsTr("Frame Rate (FPS):")
                color: Theme.mutedForeground
            }

            SpinBox {
                id: fpsSpin
                from: 1
                to: 240
                value: root.project ? Math.round(root.project.frameRate) : 30
                editable: true

                onValueChanged: {
                    if (root.project) {
                        root.project.frameRate = value;
                        if (root.project.activeComposition) {
                            root.project.activeComposition.frameRate = value;
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true } // spacer
    }

    footer: Rectangle {
        color: "transparent"
        height: 50
        RowLayout {
            anchors.fill: parent
            anchors.rightMargin: 20
            Item { Layout.fillWidth: true }
            Button {
                text: qsTr("Close")
                onClicked: root.close()
            }
        }
    }
}
