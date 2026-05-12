the flow
slecte a track/layer/strip -> automation for pan and volume is available by default.

add plugin will allow users to select plugin with plugin manager popup
plugin manager will include search funtions to search for plugins the add selected plugins either multiselect or select one. then add to the track/layer/strip effect chain

the parameters of the plugin will be animatable like audio automation,
the audioediting tab deasign will go this way

---

## wave of audio output from track/layer/strip

the faders for the | plugin rack, and can be rearranged
track/layer/strip | in any other to get different effects result their parameters can be changed tooo.

---

the faders are the master out of the project and the selected track/layer/strip.
when auto keyfram is active from toolbar as the time change and the plugin parameters are changed it keyframes them automatically.

the faders and plugin rack will have a splitview between them so it can be readjusted easily.

from start the plugin manager will search default plugin spaces to fetch plugins that are available by vst/lv2/clap

make sure the ui flows with the theme in theme.qml.

in the faders view their shouls be toggle to view automation, so that users can see the automation in realtime and the ui of the faders too should be animated if users set it. it should be a button at the top bar animate faders so the ui looks more interesting.

so we can complete the audio system fully working.

next keyframe editor ->
the part that needs eorking is the grapg editor, just to be able to replote the aniation graph like with a pen tool/similar to blender graph editing

next colorgradingeditor -> it just shows viewport current render, i need you to make it take a screen shot of the vive port then apply the color effect to the selected strip/layer/track output so it stays clean. and can show original and edited durin the split view, i added lot cube image it not affecting anything at all.

-> everywhere color wheel is used, i need you to draw them this way so they are efficient and intaractive.

To implement a color wheel with opacity and saturation controls in Qt 6 QML, you should use QtQuick.Effects.MultiEffect or ShaderEffect instead of the deprecated QtGraphicalEffects module (like ColorOverlay), which was removed in Qt 6.

1. Recommended Approach: ShaderEffect for the Wheel
   The most performant and modern way to draw a color wheel in Qt 6 is using a ShaderEffect with a fragment shader. This allows you to calculate colors based on mouse angle (hue) and distance (saturation/value).

import QtQuick
import QtQuick.Controls

Item {
width: 300
height: 400

    property vector4d colorHSVA: Qt.vector4d(0, 1, 1, 1) // Hue, Saturation, Value, Alpha

    // Color Wheel Component
    ShaderEffect {
        id: colorWheel
        width: 200
        height: 200
        anchors.horizontalCenter: parent.horizontalCenter
        property real hue: colorHSVA.x
        property real saturation: colorHSVA.y
        property real value: colorHSVA.z

        fragmentShader: "
            uniform highp float qt_Opacity;
            uniform highp float hue;
            uniform highp float saturation;
            uniform highp float value;
            varying highp vec2 qt_TexCoord0;

            vec3 hsv2rgb(vec3 c) {
                vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
                vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            void main() {
                highp vec2 coord = qt_TexCoord0 - vec2(0.5);
                highp float angle = atan(coord.y, coord.x) / 6.28318 + 0.5;
                highp float dist = length(coord);

                // Simple wheel: Hue is angle, Saturation is distance from center
                vec3 col = hsv2rgb(vec3(angle, dist, 1.0));
                gl_FragColor = vec4(col, qt_Opacity);
            }
        "

        MouseArea {
            anchors.fill: parent
            onPressed: {
                var coord = Qt.point(mouse.x / width, mouse.y / height);
                var angle = Math.atan2(coord.y - 0.5, coord.x - 0.5) / 6.28318 + 0.5;
                var dist = Math.sqrt(Math.pow(coord.x - 0.5, 2) + Math.pow(coord.y - 0.5, 2));
                colorHSVA = Qt.vector4d(angle, dist, colorHSVA.z, colorHSVA.w);
            }
        }
    }

    // Saturation Slider (Vertical)
    Column {
        anchors.top: colorWheel.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Text { text: "Saturation" }
        Slider {
            width: 200
            from: 0.0; to: 1.0
            value: colorHSVA.y
            onValueChanged: {
                colorHSVA = Qt.vector4d(colorHSVA.x, value, colorHSVA.z, colorHSVA.w);
            }
        }
    }

    // Opacity Slider (Vertical)
    Column {
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Text { text: "Opacity" }
        Slider {
            width: 200
            from: 0.0; to: 1.0
            value: colorHSVA.w
            onValueChanged: {
                colorHSVA = Qt.vector4d(colorHSVA.x, colorHSVA.y, colorHSVA.z, value);
            }
        }
    }

    // Display Result
    Rectangle {
        anchors.bottom: parent.bottom
        width: 200
        height: 50
        color: Qt.rgba(colorHSVA.x, colorHSVA.y, colorHSVA.z, colorHSVA.w)
        anchors.horizontalCenter: parent.horizontalCenter
        border.color: "black"
    }

}

for the drawing of cureves etc for the keyfram editor and audio automation too
To draw a proper graph in Qt6 QML, you should use the Qt Graphs module (introduced in Qt 6.11) for modern, high-performance 2D graphs, or the legacy Qt Charts module for broader compatibility with older Qt6 versions.

1. Using Qt Graphs (Recommended for Qt 6.11+)
   The QtGraphs module provides the GraphsView type, which is optimized for performance and offers built-in theming, zooming, and panning.

import QtQuick
import QtGraphs // Import the new module

GraphsView {
anchors.fill: parent
theme: GraphsTheme {
colorScheme: GraphsTheme.ColorScheme.Dark
seriesColors: ["#E0D080", "#B0A060"]
}

    // Define axes
    axisX: BarCategoryAxis {
        categories: ["2023", "2024", "2025"]
        lineVisible: false
    }
    axisY: ValueAxis {
        min: 0
        max: 10
        subTickCount: 4
    }

    // Add series data
    BarSeries {
        BarSet { values: [7, 6, 9] }
        BarSet { values: [9, 8, 6] }
    }

}

To implement a color wheel in Qt6 QML, the most efficient approach is to use a ShaderEffect combined with Qt.hsva for color calculation, avoiding the performance overhead of Canvas or Image pixel manipulation.

1. Shader-Based Color Wheel (Recommended)
   This method renders a perfect color wheel using GLSL shaders and calculates the selected color based on the mouse angle relative to the center.

import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
width: 300
height: 300

    property real selectedHue: 0.0
    property color selectedColor: Qt.hsva(selectedHue, 1.0, 1.0, 1.0)

    ShaderEffect {
        id: colorWheel
        anchors.fill: parent
        property real ringWidth: 0.2 // Relative width of the wheel ring (0.0 to 0.5)

        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform highp float qt_Opacity;
            uniform highp float ringWidth;

            vec3 hsv2rgb(vec3 c) {
                vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
                vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
            }

            void main() {
                highp vec2 coord = qt_TexCoord0 - vec2(0.5);
                highp float dist = length(coord);
                highp float ring = smoothstep(0, 0.01, -abs(dist - 0.5 + ringWidth) + ringWidth);

                // Calculate angle for hue (0.0 to 1.0)
                highp float angle = -atan(coord.x, coord.y) / 6.2831 + 0.5;
                if (angle < 0.0) angle += 1.0;

                gl_FragColor = vec4(hsv2rgb(vec3(angle, 1.0, 1.0)), 1.0) * ring;
            }
        "
    }

    MouseArea {
        anchors.fill: parent
        onClicked: handleColorSelection(mouseX, mouseY)
        onPositionChanged: handleColorSelection(mouseX, mouseY)

        function handleColorSelection(x, y) {
            // Convert mouse coordinates to 0.0-1.0 range
            var normX = x / parent.width;
            var normY = y / parent.height;

            // Calculate angle from center
            var centerX = 0.5;
            var centerY = 0.5;
            var dx = normX - centerX;
            var dy = centerY - normY; // Invert Y for standard polar coords

            var angle = -Math.atan2(dx, dy) / (2 * Math.PI) + 0.5;
            if (angle < 0) angle += 1.0;

            selectedHue = angle;
        }
    }

    // Visual indicator for selected color
    Rectangle {
        width: 50
        height: 50
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
        color: selectedColor
        border.color: "black"
    }

}

To draw smooth Bézier curves in Qt6 Canvas without freezing, use the Canvas QML element with its built-in bezierCurveTo() method, which handles GPU-accelerated rasterization efficiently for simple paths. For complex, high-performance vector graphics with high-quality anti-aliasing, use Qt Quick Shapes (available in Qt 6.6+) with the Curve Renderer, which renders true curves on the GPU rather than flattening them into lines like the older Geometry Renderer.

Key Implementation Strategies:
Use Canvas for Simple Paths: The Canvas API provides ctx.bezierCurveTo(controlX1, controlY1, controlX2, controlY2, endX, endY) to draw smooth cubic Bézier segments. Ensure you call requestPaint() only when data changes to avoid unnecessary redraws, and use beginPath() and closePath() correctly to manage memory.
Use Qt Quick Shapes for Performance: For complex scenes or real-time updates, derive from Shape and use Path elements with CubicBezier commands. In Qt 6.6+, set Shape.preferredRendererType: Shape.CurveRenderer to enable the new backend that preserves curvature information and provides high-quality anti-aliasing without the "jagged" artifacts of the default Geometry Renderer.
Optimize Rendering: Avoid calculating control points manually if possible; use QPainterPath in C++ backed by QQuickPaintedItem if you need imperative control, or stick to declarative QML bindings for automatic animation. Ensure you are not blocking the GUI thread with heavy calculations; offload point generation to background threads and update QML properties via signals.
Example using Canvas QML:
Canvas {
id: canvas
anchors.fill: parent

    property var points: [{x: 50, y: 100}, {x: 200, y: 50}, {x: 350, y: 100}]

    onPaint: {
        var ctx = getContext("2d")
        ctx.lineWidth = 4
        ctx.strokeStyle = "blue"
        ctx.beginPath()

        if (points.length > 0) {
            ctx.moveTo(points[0].x, points[0].y)
            // Draw smooth curves between points using quadratic or cubic methods
            // Note: Canvas 2D context in QML supports bezierCurveTo for cubic Beziers
        }
        ctx.stroke()
    }

    // Trigger redraw when points change
    Connections {
        target: model
        onPointsChanged: canvas.requestPaint()
    }

}
