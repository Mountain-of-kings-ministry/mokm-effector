import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Window {
    id: splash
    width: 640
    height: 480
    visible: true
    title: qsTr("Starting...")

    color: Theme.background
    flags: Qt.FramelessWindowHint

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 12

        Rectangle {
            width: 120
            height: 120
            color: Theme.primary
            radius: 12
            border.color: Theme.border
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("learConnection")
            color: Theme.foreground
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Loader {
        id: mainLoader
        anchors.fill: parent
        visible: false
    }

    Timer {
        interval: 1400
        running: true
        repeat: false
        onTriggered: {
            // load Main.qml (same dir)
            mainLoader.source = "Main.qml";
            mainLoader.asynchronous = false;
        }
    }

    // hide splash when main Window is ready
    Connections {
        target: mainLoader
        onStatusChanged: {
            if (mainLoader.status === Loader.Ready && mainLoader.item && mainLoader.item.visible) {
                splash.visible = false;
            }
        }
    }
}
