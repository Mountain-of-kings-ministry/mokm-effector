# MOKM Effector

A visual node-based compositing and motion graphics application built with Qt 6.

## Build Prerequisites

- **Qt 6.10+** (Quick, Widgets, OpenGL, Multimedia)
- **ThorVG** (vector graphics rendering)
- **FFmpeg** (media decoding)
- **CMake 3.16+** with Ninja
- **C++20** compiler

## Build Instructions

```bash
# Configure
cmake -G Ninja \
  -DCMAKE_PREFIX_PATH=/path/to/Qt/6.11.0/gcc_64 \
  -DCMAKE_BUILD_TYPE=Debug \
  -S code -B build/debug

# Build
ninja -C build/debug -j$(nproc)

# Run
./build/debug/appmokm_effector
```

### Optional Features

- `MOKM_ENABLE_NODES=ON` — Qt-Node-editor graph editor (default: ON)
- `MOKM_ENABLE_CLAP=ON` — CLAP audio plugin support
- `MOKM_ENABLE_INTEROP=ON` — OpenTimelineIO + OpenFX interop
- `MOKM_ENABLE_SCRIPTING=ON` — QuickJS scripting engine
- `MOKM_ENABLE_ALL=ON` — Enable all optional components

## Architecture

```
src/
├── core/          — Data model (Layer, Composition, Project, Track, Strip, Keyframe)
├── timeline/      — Timeline model and ruler
├── viewport/      — ThorVG rendering viewport
├── nodes/         — Node graph C++ backend + custom node types
├── integration/   — CLAP, OpenFX, OFX plugin bridges
├── rendering/     — Export/render pipeline
├── scripting/     — QuickJS scripting host
└── ui/            — QML components
    ├── Main.qml
    ├── Theme.qml
    └── components/
        ├── Timeline.qml
        ├── NodeEditor.qml
        ├── Toolbar.qml
        ├── PropertiesPanel.qml
        ├── ProjectBin.qml
        ├── KeyframeEditor.qml
        ├── ColorGradingEditor.qml
        ├── AudioEditor.qml
        └── ...
```

## Third-Party Dependencies

| Library | Path | Purpose |
|---------|------|---------|
| Qt-Node-editor | `third_parties/Qt-Node-editor/` | Visual node graph editor |
| ThorVG | system/vcpkg | Vector graphics rendering |
| FFmpeg | system/vcpkg | Media decoding (audio/video) |
| CLAP | `third_parties/clap-main/` | Audio plugin format |
| OpenFX | `third_parties/openfx-main/` | Visual effect plugin format |
| OpenTimelineIO | `third_parties/OpenTimelineIO-main/` | Timeline interchange |
| QuickJS | `third_parties/quickjs-master/` | JavaScript scripting |
| Qt-Color-Widgets | `third_parties/Qt-Color-Widgets-master/` | Color picker widgets |
| qrhiimgui2 | `third_parties/qrhiimgui2-master/` | Dear ImGui integration |

## Feature Status

- ✅ Timeline with multi-track, drag, trim, blade, snap
- ✅ Audio playback via QMediaPlayer + FFmpeg
- ✅ Waveform visualization
- ✅ Keyframe animation (opacity, position, rotation, scale)
- ✅ Color grading (lift/gamma/gain wheels)
- ✅ Export/render pipeline
- ✅ Undo/redo (JSON snapshot)
- ✅ Project save/load (.mokm format)
- ✅ Frameless window with resize handles
- ✅ CLAP + OpenFX plugin infrastructure
- ✅ Node graph editor (Qt-Node-editor)
- 🚧 Node graph compute (DataFlowEngine integration)
- 🚧 Full custom node type porting
- 🚧 Scripting engine (QuickJS)
- 🚧 OTIO timeline interchange

## Project

- **Version**: 0.1
- **Format**: `.mokm` JSON-based project files
- **License**: Proprietary
