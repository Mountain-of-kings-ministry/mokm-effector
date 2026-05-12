To restyle a Qt Range (such as Slider or ProgressBar) in QML to resemble an audio mixer, you must customize the handle and background properties of the specific control, as there is no global "audio mixer" style preset. 

1. Customizing the Slider (Fader)
An audio mixer primarily uses vertical sliders. You can create a custom vertical slider by embedding a Rectangle for the track and a styled Rectangle for the handle.

import QtQuick 2.15
import QtQuick.Controls 2.15

Slider {
    id: volumeFader
    orientation: Qt.Vertical
    from: 0.0
    to: 1.0
    value: 0.5
    stepSize: 0.01

    // Custom Track (Background)
    background: Rectangle {
        x: volumeFader.leftPadding
        y: volumeFader.topPadding
        implicitWidth: 6
        implicitHeight: 200
        width: implicitWidth
        height: implicitHeight
        radius: 3
        color: "#333333" // Dark grey background

        // Indicator for current level
        Rectangle {
            width: volumeFader.availableWidth
            height: volumeFader.visualPosition * parent.height
            color: "#00ff00" // Green level indicator
            radius: 3
        }
    }

    // Custom Handle (Knob)
    handle: Rectangle {
        x: volumeFader.leftPadding + volumeFader.availableWidth / 2 - width / 2
        y: volumeFader.topPadding + volumeFader.visualPosition * (volumeFader.availableHeight - height)
        implicitWidth: 40
        implicitHeight: 15
        radius: 7
        color: "#cccccc" // Silver knob
        border.color: "#666666"
        border.width: 1

        // Visual detail to look like a mixer knob
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 4
            height: 2
            color: "#333333"
        }
    }
}

add a thing line beside it indicating the current level of playing audio passing through the fader


here are the svg to use as control nubs
<qresource prefix="/">
                <file>circular-numb.svg</file> -> regular circular knob icon
        <file>slide-nub.svg</file> -> slide-style knob icon like a real mixer
    </qresource>
