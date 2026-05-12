import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Window {
    id: splash
    width: 640
    height: 400
    visible: true
    title: qsTr("Starting...")

    color: Theme.background
    flags: Qt.FramelessWindowHint

    opacity: 1

    NumberAnimation on opacity {
        id: fadeOut
        from: 1
        to: 0
        duration: 300
        running: false
        onFinished: splash.visible = false
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 16

        Rectangle {
            width: 80
            height: 80
            color: Theme.primary
            radius: 8
            Layout.alignment: Qt.AlignHCenter

            Text {
                anchors.centerIn: parent
                text: "M"
                color: Theme.foreground
                font.pixelSize: 36
                font.bold: true
            }
        }

        Text {
            text: qsTr("MOKM Effector")
            color: Theme.foreground
            font.pixelSize: 22
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: qsTr("Loading…")
            color: Theme.mutedForeground
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: false
        onTriggered: mainLoader.source = "ProjectProperties.qml"
    }

    Loader {
        id: mainLoader
        asynchronous: false
        onLoaded: fadeOut.start()
    }
}
