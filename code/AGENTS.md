# MOKM Effector — Session Log

## Phase 1 (Core Foundation MVP) — DONE

## Phase 2 (Media & Startup) — DONE

### Session 7 — ColorWheelItem, AppSettings, StartupConfig, ProjectProperties, CLAP/OpenFX

#### Color Grading
- **ColorWheelItem**: Hand-rolled QQuickPaintedItem (360 hue arcs, SV barycentric triangle) replacing Qt-Color-Widgets placeholder
- **ColorGradingEditor.qml**: Wired ColorWheelItem to liftColor/gammaColor/gainColor (QColor Q_PROPERTYs on Layer)

#### Preferences & Startup Overhaul
- **AppSettings singleton** (`src/core/AppSettings.h/.cpp`): QSettings INI backed, 20+ settings across 6 categories (General/Project/Editing/Audio/Rendering/System)
- **StartupConfig** (`src/core/StartupConfig.h/.cpp`): Context property for new/open project config; manages recent projects in QSettings (max 8)
- **ProjectProperties.qml (rewrite)**: App entry point. Left: Recent Projects list + Open Other. Right: Create New form (name, location, resolution/fps/duration/color space presets, GPU/auto-save/proxy toggles). Loads Main.qml via Qt.createComponent
- **PreferencesDialog.qml (rewrite)**: 680×440, 6-panel left-nav layout bound to AppSettings. Footer: Reset All / Cancel / OK
- **Main.qml**: Project → context property (no inline). Removed demo Rectangle 1 auto-creation. Component.onCompleted reads _startupConfig. FPS display dynamic from composition.frameRate

#### Critical Bugfixes
- **VideoLayer::clone()**: Now calls setSource(m_source) so cloned layer has valid format context
- **Viewport clip-relative frame**: renderVideoLayer passes m_currentFrame - layer->startFrame() to frameAt()
- **createStripFromAsset auto-duration**: -1 → auto-detect from VideoLayer.frameCount() / AudioLayer.frameCount(); fallback 90
- **AudioLayer frameCount**: Q_PROPERTY + WAV header parser (channels/sampleRate/bitsPerSample)

#### CLAP + OpenFX Infrastructure
- **CLAP**: git submodule at third_parties/clap-main (free-audio/clap). CMake INTERFACE target (headers), define MOKM_ENABLE_CLAP, linked to app
- **OpenFX**: git submodule at third_parties/openfx-main (ASWF/OpenFX). Auto-detected → forces MOKM_ENABLE_INTEROP ON. OfxHost + OfxSupport static libs built and linked. OpenTimelineIO also auto-built
- **ProjectBin binding loop fix**: Renamed local property `project` → `projectModel` to avoid shadowing the context property `project`. Was causing "Cannot read property 'activeComposition' of null" + binding loop on startup
- **Build**: Zero errors, zero warnings — app runs with no QML console errors

### Completed (this session)
- **createShapeLayer naming bug**: Fixed array length (added "Ellipse") to match enum
- **Delete layer**: Made `Composition::removeLayer` Q_INVOKABLE, wired Edit > Delete in TopBar + Main.qml
- **PropertiesPanel editable**: Replaced read-only text display with TextInput fields for Name, Opacity, Position, Rotation, Scale
- **Timeline keyframes**: Shows colored diamond indicators for all 6 animatable properties (opacity/x/y/rotation/scaleX/scaleY) per layer
- **ProjectBin**: Shows actual composition layers from project (name + colored indicator), click to select, right-click context menu for adding shapes
- **Window resize**: Frameless window now has 8 ResizeHandle zones (4 edges + 4 corners) with cursor changes and drag-to-resize
- **Toolbar icons**: Replaced emoji symbols with Tabler SVG icons (player-track-prev, player-play/pause, player-stop, player-track-next, diamond) tinted via MultiEffect
- **Splash → Main**: Cleaner transition using Loader + fade-out animation
- **Build**: Zero errors, app launches cleanly

### Session 2 fixes
- **Viewport live update**: `ThorVGViewport` now connects to each layer's `transformChanged`, `opacityChanged`, `visibleChanged`, `enabledChanged`, `startFrameChanged`, `durationChanged` signals → triggers `update()` repaint. Properties edits now reflect instantly in viewport
- **Timeline ruler alignment**: `TimeRuler` moved inside a `RowLayout` next to the "Layers" header, aligned at x=140px (right of layer names column)
- **Layer strips**: Each timeline layer shows a colored strip bar (5s/150f default). Strip is horizontally draggable to change `startFrame`. Right-edge handle to resize `duration`. Viewport skips rendering layers outside `[startFrame, startFrame+duration)`
- **Layer reorder**: Layer names column uses manual `y: index * 24` positioning. Drag vertically on name row → calls `Composition::moveLayer(from, to)` on release
- **Viewport drag-to-move**: `ThorVGViewport` mouse handlers: hit-test via inverse transform, drag updates `layer.x`/`layer.y` in real time
- **Layer data model**: `startFrame` (int, default 0) + `duration` (int, default 150) properties with signals
- **Composition**: `moveLayer(int fromIndex, int toIndex)` Q_INVOKABLE for reordering layers

### Session 3 fixes (bug squashing)
- **Deprecation warnings**: Fixed 4 signal handlers in `Timeline.qml` that used implicit `mouse` parameter — changed to `function(mouse)`
- **RangeError crash**: Eliminated by fixing keyframes binding reactivity + duration resize feedback loop
- **Keyframes reactive**: Added `keyframesStamp` Q_PROPERTY to `TimelineModel` (incremented on add/remove/clear). Timeline.qml `frames` binding now reads `keyframesStamp` as a dependency → diamonds appear/update instantly on keyframe toggle
- **Strip resize**: Duration handle now uses `mapToItem` for proper coordinate mapping + start-value-only calculation (no feedback loop). Strips resize correctly in both directions
- **Export null-safety**: `selectedFolder` access guarded with fallback to `currentFolder` + `if (!folderUrl) return` — prevents `toString of undefined` crash
- **Build**: Zero errors, zero warnings, clean 10s run

### Session 4 fixes (Timeline interaction & TopBar)
- **Timeline drag rewrite**: Replaced overlapping model-bound `MouseArea`s with a unified "drag-now, commit-later" visual model. Added distinct drag zones with hit testing for smooth repositioning and duration resizing identical to the `TimeRuler` responsiveness.
- **TimeRuler alignment**: Adjusted `RowLayout` spacing and left margins in `Timeline.qml` Header to precisely match the `layerNameWidth` coordinate space of the scrolling timeline strips. Playhead perfectly aligns.

### Session 5 — Selection Tool
- **Selection Tool**: Added `selectedLayers` JS array (multi-select support) + `currentTool` property on Timeline
- **Click vs Drag**: Body `MouseArea` uses 4px drag threshold — click selects without moving, drag past threshold starts strip reposition
- **Multi-select**: Shift+click on strip name or bar toggles layer in selection. `selectedLayers[0]` is the primary/active layer passed to Properties/Toolbar
- **Theme.selected visual**: Strip name row, colored bar border, and ProjectBin use `Theme.selected` (`#0066ff`). Selected text turns white for readability
- **Box select**: Rubber-band rectangle on empty-area drag. Selects all strips intersecting the rectangle. uses `#0066ff` fill + border
- **Deselect**: Click empty area below strips or press Escape clears selection
- **Left/right handles**: Trim operations always select single layer (no shift-toggle)
- **ProjectBin**: Selection highlight changed from `Theme.primary` (gold) to `Theme.selected` (blue)
- **Sync**: `onSelectedLayerChanged` handler syncs external selection (from viewport/ProjectBin) into Timeline's `selectedLayers` array

### Session 6 — Production Workflow (Phase 1.5)

#### Data Model Changes
- **Track C++ class** (`src/core/Track.h/.cpp`): holds QVector<Layer*> clips, with Q_PROPERTY(name, locked, clips, clipCount), Q_INVOKABLE addClip/removeClip/removeClipAt/moveClip/indexOf/clipAt
- **Composition refactored**: now holds `QVector<Track*> m_tracks` instead of direct layers. Backward-compat `layers()` is a flat computed view from all track clips. Methods: addTrack/removeTrack/moveTrack, rebuildLayers slot
- **Project.assets**: new `QQmlListProperty<Layer> assets` property on Project. Assets are source shapes/text independent of timeline clips
- **Clone methods**: `Layer::clone()`, `ShapeLayer::clone()`, `TextLayer::clone()` (all Q_INVOKABLE) for deep-copy semantics from asset to clip
- **Serialization**: toJson/fromJson/serialize/deserialize on Layer/ShapeLayer/TextLayer for JSON round-tripping
- **Undo/Redo**: 5-step JSON snapshot-based undo/redo on Project. captureSnapshot/undo/redo with canUndo/canRedo properties
- **Save/Load**: Project.serializeToJson/deserializeFromJson + saveToFile/loadFromFile (.mokm format)

#### UI Changes
- **ProjectBin.qml**: Shows `project.assets` instead of `composition.layers`. Right-click asset → "Add to Track" submenu (lists existing tracks + "New Track"). Clones asset onto selected track
- **Timeline.qml**: Complete rewrite for track-based layout:
  - Track names column (left) + strip area (right) synchronized via computeTrackY/getClipY helpers
  - Each track has header + clip strips, laid out via Column + nested Repeaters
  - Global playhead overlay spanning full timeline height
  - Right-click strip context menu: Cut, Copy, Paste, Duplicate, Split At Playhead, Clear Selection, Delete
  - copySelectedLayers/cutSelectedLayers/pasteClips/duplicateSelectedLayers/deleteSelectedLayers/splitAtPlayhead functions
  - Box select fixed with proper Y-coordinate calculation via getClipY()
  - `selectionChanged` signal emitted on every selection change
- **TopBar.qml**: canUndo/canRedo properties, enabled/disabled Undo/Redo menu items
- **Main.qml**: wired project save/open/undo/redo. New createShapeLayer adds to project.assets (not timeline). Demo Rectangle 1 created via asset→clone→clip flow
- **ThorVGViewport**: selection outlines (2px #0066ff border + corner handles), box select rubber-band, setSelectedLayers Q_INVOKABLE, multi-select via Shift+click

#### New Files
- `src/core/Track.h`, `src/core/Track.cpp` — Track container class

#### Modified Files
- `src/core/Layer.h/.cpp` — clone(), toJson/fromJson, serialize/deserialize
- `src/core/ShapeLayer.h/.cpp` — clone(), toJson/fromJson overrides
- `src/core/TextLayer.h/.cpp` — clone(), toJson/fromJson overrides
- `src/core/Composition.h/.cpp` — tracks property, track management, rebuildLayers
- `src/core/Project.h/.cpp` — assets, undo/redo, save/load
- `src/viewport/ThorVGViewport.h/.cpp` — selection outlines, box select, setSelectedLayers
- `src/ui/Main.qml` — asset workflow, save/open dialogs, undo/redo wiring, delete multi-selection
- `src/ui/components/ProjectBin.qml` — assets display, Add to Track menu
- `src/ui/components/Timeline.qml` — track-based layout, context menu, operations
- `src/ui/components/TopBar.qml` — canUndo/canRedo properties
- `main.cpp` — Track type registration

### Known Issues
- None — builds clean, runs without QML errors

### Build
- Dir: `/home/david/Documents/projects/software/MOKM effector/build/debug/`
- Executable: `appmokm_effector`
- Zero build errors
