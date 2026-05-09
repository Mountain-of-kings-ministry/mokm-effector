import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    height: 36

    property var timelineModel
    property var selectedLayer: null

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 2

        ToolIconButton { source: "qrc:/icons/outline/player-track-prev.svg"; onClicked: root.timelineModel?.goToStart() }

        ToolIconButton {
            id: playBtn
            source: root.timelineModel && root.timelineModel.playing
                ? "qrc:/icons/outline/player-pause.svg"
                : "qrc:/icons/outline/player-play.svg"
            onClicked: {
                if (root.timelineModel && root.timelineModel.playing)
                    root.timelineModel.pause()
                else
                    root.timelineModel.play()
            }
        }

        ToolIconButton { source: "qrc:/icons/outline/player-stop.svg"; onClicked: root.timelineModel?.stop() }

        ToolIconButton { source: "qrc:/icons/outline/player-track-next.svg"; onClicked: root.timelineModel?.goToEnd() }

        Rectangle {
            width: 1
            height: 20
            color: Theme.border
            Layout.leftMargin: 4
            Layout.rightMargin: 4
        }

        Text {
            text: qsTr("Frame:")
            color: Theme.mutedForeground
            font.pixelSize: 11
        }
        Text {
            id: frameDisplay
            text: (root.timelineModel?.currentFrame ?? 0).toString()
            color: Theme.foreground
            font.pixelSize: 11
            font.bold: true
            Layout.preferredWidth: 40
        }

        Item { Layout.fillWidth: true }

        ToolIconButton {
            source: "qrc:/icons/outline/diamond.svg"
            property int _kfStamp: root.timelineModel?.keyframesStamp ?? 0
            badge: {
                var dummy = _kfStamp;
                return root.timelineModel?.hasKeyframe(root.selectedLayer, "opacity", root.timelineModel.currentFrame) ?? false;
            }
            onClicked: {
                if (!root.selectedLayer || !root.timelineModel) return
                var frame = root.timelineModel.currentFrame
                if (root.timelineModel.hasKeyframe(root.selectedLayer, "opacity", frame))
                    root.timelineModel.removeKeyframe(root.selectedLayer, "opacity", frame)
                else
                    root.timelineModel.addKeyframe(root.selectedLayer, "opacity", frame, root.selectedLayer.opacity)
            }
        }

        Text {
            text: "30 fps"
            color: Theme.mutedForeground
            font.pixelSize: 10
        }
    }

    component ToolIconButton : Rectangle {
        implicitWidth: 28
        implicitHeight: 28
        color: ma.containsMouse ? Theme.secondaryHover : "transparent"
        radius: 4

        property string source: ""
        property bool badge: false
        signal clicked()

        Image {
            id: icon
            anchors.centerIn: parent
            width: 16
            height: 16
            source: parent.source
            sourceSize.width: 24
            sourceSize.height: 24
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: parent.badge ? Theme.accent : Theme.foreground
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }
}
