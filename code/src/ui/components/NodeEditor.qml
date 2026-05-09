import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import mokm_effector

Rectangle {
    id: root
    color: Theme.background

    Text {
        anchors.centerIn: parent
        text: qsTr("Node Editor (Coming Soon)")
        color: Theme.mutedForeground
        font.pixelSize: 18
    }
}
