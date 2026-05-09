# MOKM Effector — Session Log

## Phase 1 (Core Foundation MVP) — DONE

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

### Known Issues
- None

### Build
- Dir: `/home/david/Documents/projects/software/MOKM effector/build/debug/`
- Executable: `appmokm_effector`
- Zero build errors
