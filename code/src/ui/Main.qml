import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import kingClass
import mokm_effector

Window {
    width: 640
    height: 480
    visible: true
    title: qsTr("Learning Connections")

    // Use loaded theme as the app color source
    color: Theme.background

    SomeClass {
        id: someClass
    }

    Connections {
        target: someClass
        onManagerChanged: inputxt.text = someClass.getManagerState()
    }

    ColumnLayout {
        x: 180
        y: 155
        width: 281
        height: 171

        Text {
            id: inputxt
            // text: someClass.getManagerState()
        }

        Button {
            id: button
            text: "clcik me to see state change"
            icon.source: "qrc:/icons/outline/aerial-lift.svg"
            display: AbstractButton.TextBesideIcon
            hoverEnabled: true

            background: Rectangle {
                id: buttonBg
                anchors.fill: parent
                color: Theme.primary
                radius: 6
            }

            onHoveredChanged: {
                buttonBg.color = hovered ? Theme.primaryHover : Theme.primary;
            }
            onClicked: {
                someClass.setManager("kings manager state");
            }

            Connections {
                target: button
                function onClicked() {
                    console.log("clicked");
                }
            }
        }
    }
}
