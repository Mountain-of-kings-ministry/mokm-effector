# Open-Source Motion Graphics Platform

**Project Name:** ForgeMotion (or LuminaForge)  
**Description:** A high-efficiency, open-source 2D/3D motion graphics and animation software designed for professional results on low-end hardware.  
**Core Philosophy:** Hybrid timeline + node-based workflow | "Pay-for-what-you-use" modular architecture | Freedom through open standards and open source.  
**Target Platforms:** Windows, macOS, Linux, (future: mobile/embedded)  
**Primary Tech Stack:** C++20 + Qt 6.x

## Core Goals

- Deliver professional-grade motion design without expensive hardware or subscriptions
- Combine the best of **Adobe After Effects** (timeline/layers), **Cavalry** (procedural/data-driven), and **Left Angle Autograph** (responsive design + modern 3D)
- Run efficiently on low-end devices through extreme optimization
- Full interoperability via open industry standards

## 1. Foundational Architecture

- **Language & Framework:** C++20 + Qt 6.x (native performance, cross-platform)
- **UI Layer:** Qt Quick + QML (hardware-accelerated, non-blocking UI)
- **Modularity Principle:** "Pay-for-what-you-use" – optional high-end components can be disabled for lightweight builds

### Selected Core Libraries

| Component             | Library / Technology                   | Purpose / Advantage                                    |
| --------------------- | -------------------------------------- | ------------------------------------------------------ |
| System Framework      | Qt 6.x + C++20                         | Cross-platform native performance                      |
| 2D Vector Engine      | **ThorVG** (primary) + Skia (optional) | Tiny footprint, CPU-optimized, smart partial rendering |
| 3D Rendering          | **Filament** + gltfio                  | Mobile-first PBR, real-time, low power                 |
| 3D Scene Format       | **USD** (Universal Scene Description)  | Non-destructive, efficient, interoperable              |
| Node/Logic Engine     | **QtNodes** (v3)                       | Dataflow programming, DAG-based                        |
| Scripting Engine      | **QuickJS** (ES2023)                   | Lightweight, modern JS with low memory                 |
| Animation Engine      | ozz-animation + Choreograph            | Skeletal & procedural animation                        |
| Editorial Interchange | **OpenTimelineIO** (OTIO)              | Timeline data exchange with NLEs                       |
| Plugin System         | **OpenFX** (OFX)                       | Industry-standard effect plugins                       |
| Video I/O             | **FFmpeg**                             | Full codec support + hardware acceleration             |

## 2. Key Features (Detailed Breakdown)

### 2.1 Hybrid Workflow

- Full **Timeline + Layer Stack** (After Effects style)
- Full **Node Graph Editor** (dataflow / procedural style)
- Seamless synchronization between Timeline and Node Graph
- Toggle any composition between Layer view and Node view
- Nested compositions / Pre-comps with improved organization
- Dope Sheet and Graph Editor for keyframe manipulation

### 2.2 Procedural & Data-Driven Animation (Cavalry-inspired)

- **Duplicators**: Grid, Circle, Spiral, custom distribution with procedural offsets
- **Behaviors** / Rule-based animation systems
- **Magic Easing** and physics solvers
- **Data Binding**: Link parameters to external JSON, CSV, or live data feeds
- Templated / Auto-updating graphics (sports scores, financial data, etc.)

### 2.3 Responsive Design Engine (Autograph-inspired)

- Relative anchoring to frame boundaries
- Automatic adaptation to different aspect ratios (16:9, 1:1, 9:16, etc.)
- Smart layout system for social media / multi-format delivery

### 2.4 2D Rendering Engine

- Primary: **ThorVG** – ultra-light (210 KiB), smart partial rendering, excellent for low-end & real-time preview
- Optional high-end: **Skia** (GPU-accelerated) or **Blend2D** (performance-critical CPU paths)
- Modular backend switching at runtime or build time

### 2.5 3D Integration

- Native 3D workspace inside 2D compositions
- **Filament** PBR renderer (real-time, mobile-optimized)
- **USD** as native 3D scene format
- glTF 2.0 import with skeletal animation & morph targets
- Camera animation with focal length, aperture, shutter speed
- Procedural camera effects (shake, etc.) via nodes

### 2.6 Scripting & Expressions

- Modern **QuickJS** engine (ES2023 + modules)
- Expressions on any node or layer property
- Audio-reactive expressions
- Full automation API via C++/QuickJS bridge
- Support for custom tools and batch processing

### 2.7 Interoperability & Extensibility

- **OpenFX** host – compatible with thousands of existing VFX plugins
- **OpenTimelineIO** – seamless round-trip with Premiere, DaVinci, Kdenlive, etc.
- USD, glTF, OTIO, and standard image/video formats
- Plugin API for custom nodes, effects, and generators
- Import/export project as clean, non-proprietary formats

### 2.8 Performance Optimizations

- Smart partial rendering (ThorVG)
- Deterministic memory management (C++20)
- SIMD optimizations for geometry and pixel operations
- Non-blocking UI (Qt Quick)
- Configurable lightweight builds for mobile/low-spec devices
- Hardware acceleration where available (FFmpeg, GPU backends)

### 2.9 Additional Professional Features

- Multi-track timeline with advanced compositing
- Layer effects stack with full OpenFX support
- Real-time preview with minimal latency
- High-quality export (ProRes with Alpha, AV1, etc.)
- Color management and ACES support (planned)
- Asset management and library system

## 3. Phase-by-Phase Development Roadmap

### Phase 1: Core Foundation (MVP Base)

- Qt 6 application skeleton with QML UI
- Basic project management and document model
- ThorVG 2D rendering backend integrated
- Simple timeline + layer stack
- Basic shape generators (rect, circle, text)
- Keyframe animation on timeline
- FFmpeg basic export (image sequence + video)
- Build system (CMake + Conan/vcpkg)

### Phase 2: Node Graph System

- Integrate QtNodes
- Basic dataflow model (Generators + Modifiers)
- Node → Timeline property synchronization
- Simple node types: Transform, Shape, Group, Effect
- Real-time cooking and preview

### Phase 3: Procedural Tools

- Duplicator nodes (grid, circle, spiral)
- Behavior / rule-based animation nodes
- Data binding system (JSON/CSV)
- Basic physics and easing solvers

### Phase 4: Responsive & Layout Engine

- Relative anchoring system
- Multi-aspect ratio preview and rendering
- Smart layout constraints

### Phase 5: Scripting Engine

- Integrate QuickJS
- Expression system on node/layer properties
- QML property bindings
- Basic automation API

### Phase 6: 3D Integration

- Integrate Filament renderer
- USD scene support
- 3D object import (glTF)
- 3D camera with keyframing
- Basic lighting and materials

### Phase 7: Interoperability

- OpenFX host implementation
- OpenTimelineIO import/export
- Full FFmpeg pipeline with hardware acceleration

### Phase 8: Polish & Optimization

- Dope Sheet + Graph Editor
- Advanced effects stack
- Performance tuning & partial rendering
- Lightweight build configurations
- UI/UX refinement

### Phase 9: Extensibility & Release

- Plugin system finalization
- Documentation and examples
- Community tools (templates, asset packs)
- Official 1.0 release (open source license)

## 4. Technical Notes & Future Considerations

- All high-end libraries (Skia, full Filament features) must remain optional
- Strict focus on memory footprint and CPU efficiency
- License: MIT or GPL-3.0 (to be decided)
- Target: Run professional projects on 8GB RAM / integrated graphics machines

## 5. References & Inspiration Sources

- Adobe After Effects (timeline & effects ecosystem)
- Cavalry Motion Design (procedural & data-driven)
- Left Angle Autograph (responsive design & 3D integration)
- ThorVG, Filament, Qt, QtNodes, QuickJS, OpenFX, OpenTimelineIO, USD

---

## folder restructuring

code/
├── src/
│ ├── core/ # Scene, Composition, Document
│ ├── viewport/ # 2D (ThorVG) + 3D (Filament) viewport system
│ ├── nodes/ # Node system and dataflow
│ ├── timeline/ # Timeline, Dope Sheet, Keyframes
│ ├── ui/ # QML components, MainWindow, docking
│ ├── rendering/ # Render backends and managers
│ ├── scripting/ # QuickJS integration
│ └── integration/ # USD, OTIO, OpenFX, FFmpeg
├── resources/
│ ├── icons/ # Tabler Icons (outline + filled)
│
├── CMakeLists.txt
├── vcpkg.json

**Status:** Architectural Blueprint Complete  
**Next Step:** Begin Phase 1 implementation

This document serves as the single source of truth for building the project incrementally.
