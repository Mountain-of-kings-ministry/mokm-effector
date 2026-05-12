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
    property var selectedObject: null
    readonly property var currentElement: selectedObject && selectedObject.element !== undefined ? selectedObject.element : selectedObject
    property string currentTool: "select"
    property bool snapEnabled: true

    signal toolChanged(string tool)
    signal snapToggled(bool enabled)
    signal splitAtPlayhead()
    signal deleteSelected()
    signal rippleDeleteSelected()
    signal duplicateSelected()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 1

        // ── Transport ──
        ToolIconButton { source: "qrc:/icons/outline/player-track-prev.svg"; tooltip: "Go to Start"; onClicked: root.timelineModel?.goToStart() }

        ToolIconButton {
            id: playBtn
            source: root.timelineModel && root.timelineModel.playing
                ? "qrc:/icons/outline/player-pause.svg"
                : "qrc:/icons/outline/player-play.svg"
            tooltip: root.timelineModel && root.timelineModel.playing ? "Pause" : "Play"
            onClicked: {
                if (root.timelineModel && root.timelineModel.playing)
                    root.timelineModel.pause()
                else
                    root.timelineModel.play()
            }
        }

        ToolIconButton { source: "qrc:/icons/outline/player-stop.svg"; tooltip: "Stop"; onClicked: root.timelineModel?.stop() }

        ToolIconButton { source: "qrc:/icons/outline/player-track-next.svg"; tooltip: "Go to End"; onClicked: root.timelineModel?.goToEnd() }

        // ── Separator ──
        ToolSeparator {}

        // ── Selection Tools ──
        ToolIconButton {
            source: "qrc:/icons/outline/pointer.svg"
            tooltip: "Select (V)"
            accented: root.currentTool === "select"
            onClicked: root.toolChanged("select")
        }
        ToolIconButton {
            source: "qrc:/icons/outline/arrows-move.svg"
            tooltip: "Move (M)"
            accented: root.currentTool === "move"
            onClicked: root.toolChanged("move")
        }

        // ── Separator ──
        ToolSeparator {}

        // ── Trim Tools ──
        ToolIconButton {
            source: "qrc:/icons/outline/arrow-back-up.svg"
            tooltip: "Trim Left (T)"
            accented: root.currentTool === "trimLeft"
            onClicked: root.toolChanged("trimLeft")
        }
        ToolIconButton {
            source: "qrc:/icons/outline/arrow-forward-up.svg"
            tooltip: "Trim Right (T)"
            accented: root.currentTool === "trimRight"
            onClicked: root.toolChanged("trimRight")
        }
        ToolIconButton {
            source: "qrc:/icons/outline/scissors.svg"
            tooltip: "Blade (B)"
            accented: root.currentTool === "blade"
            onClicked: root.toolChanged("blade")
        }

        // ── Separator ──
        ToolSeparator {}

        // ── Editing Actions ──
        ToolIconButton {
            source: "qrc:/icons/outline/arrows-split-2.svg"
            tooltip: "Split at Playhead (Ctrl+S)"
            onClicked: root.splitAtPlayhead()
        }
        ToolIconButton {
            source: "qrc:/icons/outline/trash.svg"
            tooltip: "Delete (Del)"
            onClicked: root.deleteSelected()
        }
        ToolIconButton {
            source: "qrc:/icons/outline/trash-x.svg"
            tooltip: "Ripple Delete (Shift+Del)"
            onClicked: root.rippleDeleteSelected()
        }
        ToolIconButton {
            source: "qrc:/icons/outline/copy.svg"
            tooltip: "Duplicate (Ctrl+D)"
            onClicked: root.duplicateSelected()
        }

        // ── Separator ──
        ToolSeparator {}

        // ── Snap Toggle ──
        ToolIconButton {
            source: "qrc:/icons/outline/magnet.svg"
            accented: root.snapEnabled
            tooltip: "Toggle Snap (S)"
            onClicked: root.snapToggled(!root.snapEnabled)
        }

        Item { Layout.fillWidth: true }

        // ── Frame Display ──
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

        Item { Layout.preferredWidth: 8 }

        ToolIconButton {
            source: "qrc:/icons/outline/diamond.svg"
            accented: root.timelineModel ? root.timelineModel.autoKeyframeEnabled : false
            onClicked: {
                if (!root.timelineModel) return;
                root.timelineModel.autoKeyframeEnabled = !root.timelineModel.autoKeyframeEnabled;
            }
        }

        Text {
            text: {
                var fps = root.timelineModel?.composition?.frameRate;
                return (fps ? fps.toFixed(0) : "30") + " fps";
            }
            color: Theme.mutedForeground
            font.pixelSize: 10
        }
    }

    // ── Components ──
    component ToolSeparator: Rectangle {
        width: 1; height: 20; color: Theme.border; Layout.leftMargin: 2; Layout.rightMargin: 2
    }

    component ToolIconButton : Rectangle {
        implicitWidth: 28
        implicitHeight: 28
        color: accented ? Qt.alpha(Theme.accent, 0.18) : (ma.containsMouse ? Theme.secondaryHover : "transparent")
        radius: 4

        property string source: ""
        property string tooltip: ""
        property bool badge: false
        property bool accented: false
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
                colorizationColor: parent.accented ? Theme.accent : (parent.badge ? Theme.accent : Theme.foreground)
                brightness: 1.0
                contrast: 1.0
                saturation: 0.0
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()

            ToolTip {
                visible: ma.containsMouse && parent.tooltip !== ""
                text: parent.tooltip || ""
                delay: 800
            }
        }
    }
}
