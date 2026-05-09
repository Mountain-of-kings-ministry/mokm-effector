# Phase 1 — Core Foundation (MVP)

## Layout
```
ColumnLayout {
    RowLayout {
        ProjectBin (panel) | Viewport (ThorVG canvas) | Properties (panel)
    }
    ColumnLayout {
        Toolbar
        Timeline (layer list + time ruler + keyframes)
    }
}
```

---

## Implementation Checklist

### Step 1 — Core Model Classes
- [x] Create `src/core/Project.h` / `Project.cpp` — document model with compositions
- [x] Create `src/core/Composition.h` / `Composition.cpp` — layers container with duration/resolution
- [x] Create `src/core/Layer.h` / `Layer.cpp` — base class (name, transform, opacity)
- [x] Create `src/core/ShapeLayer.h` / `ShapeLayer.cpp` — rect, ellipse, circle with fill/stroke
- [x] Create `src/core/TextLayer.h` / `TextLayer.cpp` — text with font, size, alignment
- [x] Create `src/core/Keyframe.h` / `Keyframe.cpp` — time, value, easing (linear/in/out/inout)

### Step 2 — Viewport / ThorVG Integration
- [x] Create `src/viewport/ThorVGViewport.h` / `ThorVGViewport.cpp` (QQuickPaintedItem)
- [x] Viewport renders comp layers: shapes with fill/stroke, text with font
- [x] Proper scaling / framing of comp within viewport
- [x] Checkerboard background for transparent areas

### Step 3 — Timeline Data Model
- [x] Create `src/timeline/TimelineModel.h` / `TimelineModel.cpp`
- [x] Play/pause/stop playback with frame-stepping
- [x] Add/remove keyframes per layer per property
- [x] Keyframe interpolation (linear) between frames
- [x] Registered as QML type

### Step 4 — Main UI Layout
- [x] Rewrite `src/ui/Main.qml` — ColumnLayout + RowLayout structure
- [x] Panels: ProjectBin | Viewport (ThorVGViewport) | PropertiesPanel
- [x] Bottom section: Toolbar + Timeline
- [x] Default scene creates a demo Rectangle layer on startup

### Step 5 — Panel Components
- [x] Create `src/ui/components/ProjectBin.qml` — asset tree placeholder
- [x] Create `src/ui/components/PropertiesPanel.qml` — selected layer property readout
- [x] Create `src/ui/components/Toolbar.qml` — transport controls (play/pause/stop/step)

### Step 6 — Timeline UI
- [x] Create `src/ui/components/TimeRuler.qml` — frame ruler with click-to-scrub
- [x] Create `src/ui/components/Timeline.qml` — layer list + keyframe diamonds + playhead line

### Step 7 — Shape Rendering
- [x] Rectangle / Ellipse / Circle rendering with fill + stroke via QPainter
- [x] Text rendering with font family, size, weight, color
- [x] Layer transform (position, rotation, scale) applied per layer
- [x] Layers update on property change via Qt signals

### Step 8 — Keyframe Animation
- [x] Playhead scrubbing via timeline click/drag
- [x] Add/remove keyframe diamonds visible on timeline
- [x] Keyframe interpolation updates viewport on frame change
- [x] Playback controls functional (play/pause loops)

### Step 9 — FFmpeg Export
- [x] Create `src/core/ExportController.h` / `ExportController.cpp`
- [x] Basic image sequence export (frame-by-frame PNG)
- [x] Encode frames to video via FFmpeg subprocess

### Step 10 — Build Integration
- [x] Update `src/core/CMakeLists.txt` — new sources globbed automatically
- [x] Update `src/viewport/CMakeLists.txt` — ThorVGViewport sources
- [x] Update `src/timeline/CMakeLists.txt` — TimelineModel sources
- [x] Update root `CMakeLists.txt` QML_FILES — all new components registered
- [x] All C++ types registered via qmlRegisterType in main.cpp

### Step 11 — Cleanup
- [x] Remove old `someclass` boilerplate (someclass.h, someclass.cpp)
- [x] Update `main.cpp` — register new types, clean engine setup
- [x] Remove stale imports from QML files (kingClass)
- [x] Update SplashScreen.qml — fresh branding, cleanup

### Step 12 — QML Wiring & Shape Menu
- [x] Add `Triangle` to `ShapeLayer::ShapeType` enum
- [x] Triangle rendering in `ThorVGViewport::renderShapeLayer` and `ExportController::renderShapeLayer`
- [x] File > New submenu (Rect/Circle/Triangle/Text) + Export Video... in TopBar.qml
- [x] Main.qml signal handlers for all create signals + ExportController + FileDialog
- [x] App builds cleanly with zero errors

---
**Status:** Phase 1 complete. All steps done.  
**Last updated:** 2026-05-09

### Items completed since last update
- Fixed `createShapeLayer` naming array (added missing "Ellipse" for enum alignment)
- Made `Composition::removeLayer` Q_INVOKABLE; wired Edit → Delete in TopBar/Main.qml
- PropertiesPanel now editable (TextInput fields for Name, Opacity, Position, Rotation, Scale)
- Timeline keyframe diamonds now show for all 6 animatable properties (opacity, x, y, rotation, scaleX, scaleY) with distinct colors
- ProjectBin replaced static placeholder list with dynamic composition layer tree (name + indicator, click-to-select)
- Frameless window now resizable via 8 edge/corner MouseArea handles
- Toolbar emoji icons replaced with Tabler SVGs (player-play/pause/stop/track-prev/track-next, diamond)
- Splash → Main transition: fade-out animation via Loader
- App builds with zero errors
