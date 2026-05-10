# Phase 2: Node Graph System

## Architecture Overview

```
Layer (TimelineLayer)
 └── Track
      └── NodeStrip (extends Strip)
            └── NodeGraph (QtNodes)
                  ├── Nodes
                  └── Connections
```

Each `Strip` on the timeline will become a `NodeStrip` that owns a `NodeGraph` — a self-contained dataflow graph driving the strip's visual output.

## Key Design Decisions

### NodeStrip = Strip + NodeGraph
- `Strip` gains a `nodeGraph` property (initially null).
- When a NodeStrip's NodeGraph is empty/default, the strip's `element` (Layer*) renders directly (backward compat).
- When nodes are added to the graph, the strip's output is computed from the graph's terminal node.
- Keyframe animation on strip properties drives node input parameters.

### Layer → Track → NodeStrip → NodeGraph
- **TimelineLayer**: Group of tracks, compositing container (opacity, transform, etc. already added).
- **Track**: Ordered collection of NodeStrips, mix/sum outputs before feeding to Layer.
- **NodeStrip**: Timeline clip that wraps a NodeGraph. Handles timing (startFrame, duration), name, and keyframe bindings.
- **NodeGraph**: DAG of connected Nodes. Owned by one NodeStrip. Cooked whenever inputs change.

### Audio Routing
- `NodeStrip → Track → Layer → Master`
- Audio nodes inside a NodeGraph route through the strip's audio output.
- Tracks sum audio from all strips → Layer sum from tracks → Master output.
- Pan, volume, mute, solo operate at each level.

## Node Types (initial)

### Generators (output: visual + optional audio)
- Rectangle, Ellipse, Circle, Triangle, Polygon, Star, Line, Arc, Grid, Spiral, Arrow, RoundedRect, Bezier, Path
- SVG, Spline, Lottie
- Text
- Noise, Curl Noise, Voronoi
- Image, Video, ImageSequence, GIF, SpriteSheet
<!-- - Webcam, ScreenCapture -->

### Modifiers (input → output transform)
- Transform (translate, rotate, scale, skew, anchor)
- Color Adjust (brightness, contrast, saturation, hue)
- Blur (gaussian, directional, radial)
- Mask / Alpha
- Blend (normal, add, multiply, screen, overlay, etc.)

### Audio (input → output audio)
- Audio File, Microphone
- Gain, Pan, EQ, Compressor
- Audio Visualizer (audio → visual)

## Integration with Timeline

### NodeStrip creation
From ProjectBin context menu:
1. Generators/Media/Procedural → creates asset in project bin (neutral, no node graph)
2. Right-click asset → "Add to Layer" → select track → `Track.createStripFromAsset()` creates a NodeStrip with a default node graph containing one generator node
3. Double-click strip in timeline → opens NodeGraph editor in the graph panel

### Node → Property binding
- Each QML property in the PropertiesPanel binds to a node input port
- Adding a keyframe on a property creates an animation node connected to that port
- Expressions (Phase 5) also connect as node inputs

### Graph cooking
- QtNodes evaluates the DAG on input changes
- Output is a `Layer*` (ThorVG drawable) + optional audio buffer
- Strip caches the cooked output, invalidated on any node/connection change

## File Structure

```
src/
├── nodes/
│   ├── NodeGraph.h/.cpp          # DAG container (QtNodes DataModelRegistry + FlowScene)
│   ├── NodeStrip.h/.cpp          # Strip subclass with nodeGraph ownership
│   ├── nodes/
│   │   ├── GeneratorNode.h/.cpp  # Base for all generator types
│   │   ├── TransformNode.h/.cpp  # Transform modifier
│   │   ├── BlurNode.h/.cpp       # Blur modifier
│   │   ├── BlendNode.h/.cpp      # Blend/merge node
│   │   └── ...
│   └── connections/
│       └── AudioConnection.h/.cpp # Audio data type for node ports
├── ui/
│   └── components/
│       └── NodeEditor.qml        # QML wrapper for QtNodes QGraphicsView
```

## Dependencies
- **QtNodes** (submodule or vcpkg) — `nodes` library for dataflow programming
- ThorVG continues as render backend for generator output

## Migration from Current Strips

1. Add `nodeGraph` property to `Strip` (null by default → backward compatible)
2. Create `NodeStrip` subclass that auto-creates a NodeGraph with one generator node matching the element type
3. `createStripFromAsset` returns a `NodeStrip` instead of `Strip`
4. NodeEditor.qml receives the selected strip's NodeGraph and displays it
5. Gradually move element properties (opacity, x, y, rotation, scale) to node inputs

## Milestones

### M1 — Foundation
- Integrate QtNodes library
- Create `NodeStrip` and `NodeGraph` C++ classes
- Wire `createStripFromAsset` to produce NodeStrips
- Display NodeGraph in NodeEditor panel

### M2 — Generator nodes
- Port all generator types to nodes
- Each generator node outputs a Layer* (ThorVG drawable)
- NodeGraph cooking produces the strip's element

### M3 — Modifier nodes
- Transform, Color, Blur, Mask nodes
- Node chaining: Generator → Modifier → Output
- PropertiesPanel shows node input ports as editable fields

### M4 — Keyframe + Animation
- Animation nodes drive input ports over time
- Keyframe diamond in PropertiesPanel creates animation curve node
- Graph Editor panel for curve manipulation

### M5 — Audio pipeline
- Audio nodes and data type
- Track/Layer audio summing
- Audio routing UI in PropertiesPanel
