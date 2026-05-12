import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import mokm_effector

Rectangle {
    id: root
    color: Theme.secondary
    height: 28

    property alias timelineModel: controller.timelineModel
    property real pixelPerFrame: 8

    Item {
        id: controller
        property var timelineModel: null
    }

    Repeater {
        model: {
            if (!controller.timelineModel?.composition) return 0
            return controller.timelineModel.composition.duration
        }
        delegate: Rectangle {
            x: index * root.pixelPerFrame
            width: 1
            height: parent.height
            color: index % 10 === 0 ? Theme.muted : Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.3)
            visible: true

            Text {
                x: 3
                y: 2
                text: index % 10 === 0 ? index.toString() : ""
                color: Theme.mutedForeground
                font.pixelSize: 9
            }
        }
    }

    Rectangle {
        id: playhead
        x: (controller.timelineModel?.currentFrame ?? 0) * root.pixelPerFrame - 4
        y: 0
        width: 8
        height: parent.height
        color: Theme.accent

        Rectangle {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 10
            height: 8
            color: Theme.accent
            radius: 2
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: function(mouse) {
            if (controller.timelineModel) {
                var frame = Math.floor(mouse.x / root.pixelPerFrame)
                controller.timelineModel.goToFrame(frame)
            }
        }
        onPositionChanged: function(mouse) {
            if (mouse.buttons & Qt.LeftButton && controller.timelineModel) {
                var frame = Math.max(0, Math.floor(mouse.x / root.pixelPerFrame))
                controller.timelineModel.goToFrame(frame)
            }
        }
    }
}
