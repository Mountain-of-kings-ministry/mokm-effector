changing keyfream interpulation
for any keyframe

here is what am talking about, adding handle to the curve points so users can still do manuall editing their
The animation curve with handles used to reshape interpolation is called a Bezier curve (or Bezier interpolation).

Function: Bezier curves allow animators to manually adjust direction handles (tangents) attached to keyframes to control the speed and trajectory of motion between points.
Variations: Common types include Auto Bezier (automatically smooths transitions), Continuous Bezier (manually set but linked handles), and Free Bezier (independent handles for sharp corners or complex paths).
Alternative Names: In some software like Maya or Blender, these are referred to as F-Curves (Function Curves) with tangents or handles. In After Effects, they are manipulated via the Graph Editor.

for the graph editor.

The things you are referring to are called Tangent Handles (or Control Handles) on a Cubic Bézier Curve. In Blender they are the white dots connected by lines to the keyframes that let you stretch and shape the interpolation curve.
Goal: QML Implementation of Draggable Tangent Handles
Here’s how to implement this in QML:

1. Data Structure (Keyframes)
   qmlproperty list<var> keyframes: [
   { time: 0.0, value: 0.0,
   handleIn: { time: -0.1, value: 0.1 }, // left handle (relative or absolute)
   handleOut: { time: 0.1, value: 0.3 } // right handle
   },
   { time: 1.0, value: 1.0,
   handleIn: { time: 0.8, value: 0.7 },
   handleOut: { time: 1.1, value: 1.0 }
   }
   ]
2. Full Working Example (Basic Version)
   qmlimport QtQuick 2.15
   import QtQuick.Controls 2.15

Item {
id: editor
width: 800
height: 500

    // Canvas for drawing the curve + grid + lines
    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: drawAll()

        function drawAll() {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            // Draw grid here...
            drawCurve(ctx)
            drawTangentLines(ctx)
        }

        function drawCurve(ctx) {
            if (keyframes.length < 2) return
            ctx.strokeStyle = "#00ffcc"
            ctx.lineWidth = 4
            ctx.beginPath()

            let p0 = keyframes[0]
            ctx.moveTo(mapTimeToX(p0.time), mapValueToY(p0.value))

            for (let i = 1; i < keyframes.length; ++i) {
                let prev = keyframes[i-1]
                let curr = keyframes[i]

                ctx.bezierCurveTo(
                    mapTimeToX(prev.handleOut.time),
                    mapValueToY(prev.handleOut.value),
                    mapTimeToX(curr.handleIn.time),
                    mapValueToY(curr.handleIn.value),
                    mapTimeToX(curr.time),
                    mapValueToY(curr.value)
                )
            }
            ctx.stroke()
        }

        function drawTangentLines(ctx) {
            ctx.strokeStyle = "#ffffff"
            ctx.lineWidth = 2
            ctx.beginPath()

            for (let kf of keyframes) {
                // Left handle line
                ctx.moveTo(mapTimeToX(kf.time), mapValueToY(kf.value))
                ctx.lineTo(mapTimeToX(kf.handleIn.time), mapValueToY(kf.handleIn.value))

                // Right handle line
                ctx.moveTo(mapTimeToX(kf.time), mapValueToY(kf.value))
                ctx.lineTo(mapTimeToX(kf.handleOut.time), mapValueToY(kf.handleOut.value))
            }
            ctx.stroke()
        }
    }

    // Draggable Keyframes + Handles
    Repeater {
        model: keyframes

        Item {
            // Keyframe (main point)
            Rectangle {
                width: 12; height: 12
                radius: 2
                color: "#ffff00"
                x: mapTimeToX(modelData.time) - 6
                y: mapValueToY(modelData.value) - 6
                border.color: "black"

                DragHandler {
                    onActiveChanged: if (!active) canvas.requestPaint()
                    onTranslationChanged: {
                        // Update time and value
                    }
                }
            }

            // === LEFT HANDLE ===
            Rectangle {
                width: 10; height: 10
                radius: 5
                color: "#44aaff"
                x: mapTimeToX(modelData.handleIn.time) - 5
                y: mapValueToY(modelData.handleIn.value) - 5
                visible: modelData.time > 0  // hide on first key

                DragHandler {
                    onActiveChanged: if (!active) canvas.requestPaint()
                    onTranslationChanged: {
                        modelData.handleIn.time  += deltaTime(translation.x)
                        modelData.handleIn.value += deltaValue(translation.y)
                        canvas.requestPaint()
                    }
                }
            }

            // === RIGHT HANDLE ===
            Rectangle {
                width: 10; height: 10
                radius: 5
                color: "#44aaff"
                x: mapTimeToX(modelData.handleOut.time) - 5
                y: mapValueToY(modelData.handleOut.value) - 5

                DragHandler {
                    onActiveChanged: if (!active) canvas.requestPaint()
                    onTranslationChanged: {
                        modelData.handleOut.time  += deltaTime(translation.x)
                        modelData.handleOut.value += deltaValue(translation.y)
                        canvas.requestPaint()
                    }
                }
            }
        }
    }

    // Coordinate conversion functions
    function mapTimeToX(t) { return t * width }           // normalize 0..1 → pixels
    function mapValueToY(v) { return height - v * height } // flip Y axis

    function deltaTime(dx) { return dx / width }
    function deltaValue(dy) { return -dy / height }       // because Y is flipped

}

Here's a clean and practical way to add predefined interpolation presets (Ease In, Ease Out, etc.) to your QML curve editor.

1. Define Presets in QML
   qmlimport QtQuick 2.15

Item {
id: curveEditor

    // ==================== PREDEFINED EASING PRESETS ====================
    property var easingPresets: [
        { name: "Linear",          type: "linear",     bezier: [0.00, 0.00, 1.00, 1.00] },

        { name: "Ease",            type: "bezier",    bezier: [0.25, 0.10, 0.25, 1.00] },
        { name: "Ease In",         type: "bezier",    bezier: [0.42, 0.00, 1.00, 1.00] },
        { name: "Ease Out",        type: "bezier",    bezier: [0.00, 0.00, 0.58, 1.00] },
        { name: "Ease In Out",     type: "bezier",    bezier: [0.42, 0.00, 0.58, 1.00] },

        { name: "Ease In Quad",    type: "bezier",    bezier: [0.11, 0.00, 0.50, 0.00] },
        { name: "Ease Out Quad",   type: "bezier",    bezier: [0.50, 1.00, 0.89, 1.00] },
        { name: "Ease In Out Quad",type: "bezier",    bezier: [0.45, 0.00, 0.55, 1.00] },

        { name: "Ease In Cubic",   type: "bezier",    bezier: [0.32, 0.00, 0.67, 0.00] },
        { name: "Ease Out Cubic",  type: "bezier",    bezier: [0.33, 1.00, 0.68, 1.00] },
        { name: "Ease In Out Cubic",type: "bezier",   bezier: [0.65, 0.00, 0.35, 1.00] },

        { name: "Ease In Quart",   type: "bezier",    bezier: [0.50, 0.00, 0.75, 0.00] },
        { name: "Ease Out Quart",  type: "bezier",    bezier: [0.25, 1.00, 0.50, 1.00] },

        { name: "Ease In Expo",    type: "bezier",    bezier: [0.95, 0.05, 0.80, 0.04] },
        { name: "Ease Out Expo",   type: "bezier",    bezier: [0.19, 1.00, 0.22, 1.00] },

        { name: "Ease In Back",    type: "bezier",    bezier: [0.60, -0.28, 0.74, 0.05] },
        { name: "Ease Out Back",   type: "bezier",    bezier: [0.18, 0.89, 0.32, 1.28] }
    ]

    // Current selected preset
    property string currentEasing: "Ease In Out"

} 2. Apply Preset to Keyframes (Important!)
When the user selects a preset, you apply it to the handles of the selected segment:
qmlfunction applyEasingPreset(presetName) {
// Find the preset
let preset = easingPresets.find(p => p.name === presetName)
if (!preset || preset.type !== "bezier") return;

    let p0 = keyframes[selectedKeyframeIndex]
    let p1 = keyframes[selectedKeyframeIndex + 1]

    if (!p0 || !p1) return;

    // Apply to the segment between p0 and p1
    let dx = p1.time - p0.time
    let dy = p1.value - p0.value

    // Convert normalized bezier points to actual handle positions
    p0.handleOut.time  = p0.time  + dx * preset.bezier[0]
    p0.handleOut.value = p0.value + dy * preset.bezier[1]

    p1.handleIn.time   = p0.time  + dx * preset.bezier[2]
    p1.handleIn.value  = p0.value + dy * preset.bezier[3]

    canvas.requestPaint()

} 3. UI - Preset Selector (ComboBox)
qmlComboBox {
id: presetCombo
model: easingPresets.map(p => p.name)
onActivated: {
applyEasingPreset(currentText)
}
}


################
last adition


## Timeline Navigation

```text id="nav_tools"
[ Playhead ]
Move current frame

[ Scrub ]
Timeline scrubbing

[ Pan ]
Move timeline view

[ Zoom ]
Zoom timeline

[ Frame Step ]
Move frame-by-frame

[ Jump Start ]
Go to frame 0

[ Jump End ]
Go to composition end
```

---