**Here’s the full list of transition effects** available in FFmpeg’s **`xfade`** filter (the best and easiest way to add transitions when you're already using FFmpeg in your C++ project).

You can use them directly like this:

```bash
xfade=transition=NAME:duration=1:offset=4
```

Or via `libavfilter` API in C++ by building the filter graph.

### Complete List of `xfade` Transitions

| Category              | Transitions |
|-----------------------|-------------|
| **Basic Fades**       | `fade` (default), `fadeblack`, `fadewhite`, `fadegrays`, `fadefast`, `fadeslow` |
| **Dissolve**          | `dissolve` |
| **Wipes (straight)**  | `wipeleft`, `wiperight`, `wipeup`, `wipedown` |
| **Wipes (diagonal)**  | `wipetl`, `wipetr`, `wipebl`, `wipebr` |
| **Wipes (wind)**      | `hlwind`, `hrwind`, `vuwind`, `vdwind` |
| **Slides**            | `slideleft`, `slideright`, `slideup`, `slidedown` |
| **Smooth Slides**     | `smoothleft`, `smoothright`, `smoothup`, `smoothdown` |
| **Covers**            | `coverleft`, `coverright`, `coverup`, `coverdown` |
| **Reveals**           | `revealleft`, `revealright`, `revealup`, `revealdown` |
| **Iris / Shapes**     | `circlecrop`, `rectcrop`, `circleopen`, `circleclose`, `vertopen`, `vertclose`, `horzopen`, `horzclose` |
| **Diagonals**         | `diagtl`, `diagtr`, `diagbl`, `diagbr` |
| **Slices**            | `hlslice`, `hrslice`, `vuslice`, `vdslice` |
| **Others**            | `distance`, `radial`, `pixelize`, `hblur`, `squeezeh`, `squeezev`, `zoomin` |
| **Custom**            | `custom` (with `expr` option) |

**Total**: Around 50+ built-in transitions.

### Most Popular Ones (Recommended to Implement First)

- `fade` — Classic cross-dissolve
- `dissolve` — Grainy dissolve
- `fadeblack` / `fadewhite` — Fade via black/white
- `wipeleft`, `wiperight`, `wipeup`, `wipedown` — Classic wipes
- `slideleft` etc. — Slide/push effect
- `circleopen` / `circleclose` — Iris in/out
- `pixelize` — Pixelation transition
- `radial` — Radial wipe

### How to Use in Filter Graph (C++ / Command Line)

```bash
ffmpeg -i clip1.mp4 -i clip2.mp4 -filter_complex \
"[0:v][1:v]xfade=transition=dissolve:duration=1:offset=5[outv]" \
-map "[outv]" output.mp4
```

**Key parameters**:
- `transition=` → one of the names above
- `duration=` → length of transition in seconds (e.g. 0.5 to 2.0)
- `offset=` → when the transition starts **relative to the first clip** (very important!)
- `expr=` → only when using `transition=custom`

### Tips for Your Video Editor

1. **Overlap clips** on the timeline by at least the transition duration.
2. Calculate `offset` = start time of second clip - transition duration (or end of first clip - duration).
3. For audio, pair it with `acrossfade` filter.
4. You can also use `xfade_opencl` for hardware acceleration (faster on GPU, but fewer transitions supported).

Would you like me to give you:
- A ready-to-use C++ code snippet using `libavfilter` for a specific transition?
- How to implement the full chain for multiple strips?
- Or examples for the `custom` transition with expressions?

Just tell me which transitions you want to prioritize!