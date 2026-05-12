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

    // Triggers plugin scanning
    Component.onCompleted: {
        _startupConfig.status = "Loading Audio Plugins...";
        // Call C++ plugin scanning
        if (typeof _audioPluginManager !== "undefined") {
            _audioPluginManager.scanPlugins();
        }
        _startupConfig.status = "Ready";
        loadTimer.start();
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
            text: _startupConfig ? _startupConfig.status : ""
            color: Theme.mutedForeground
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Timer {
        id: loadTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            var component = Qt.createComponent("ProjectProperties.qml");
            if (component.status === Component.Ready) {
                var win = component.createObject(null);
                win.show();
                splash.close();
            } else {
                console.error("Failed to load ProjectProperties.qml");
            }
        }
    }
}
