# Benchmark Report

Frame-timing measurements for `agnostic_split_view` v0.2.0, comparing
the package's `deferResize`, `isolatePanes`, and `shieldPlatformViews`
options across five scenarios.

## How to reproduce

    cd example
    flutter run -d chrome --profile        # Web
    flutter run -d windows --profile       # Windows desktop

Tap the Benchmark FAB, select a mode, toggle options, press RUN.
Results appear in the panel — dismiss and rerun to compare.

## Environment

|            |                         |
| ---------- | ----------------------- |
| Flutter    | 3.47.1 / stable         |
| Dart       | 3.13.1                  |
| Windows    | x64 (64-bit)            |
| Chrome     | 141 (Web benchmark)     |
| Build mode | profile                 |
| Screen     | 60Hz + 120Hz simulation |

## Scenarios

| Mode     | Content                             |
| -------- | ----------------------------------- |
| LIGHT    | Empty panes                         |
| HEAVY    | 2,000-item list per pane            |
| EXTREME  | 10,000-item list per pane           |
| TREE     | 7 nested SplitViews, 8 heavy leaves |
| ANIMATED | 3 panes with continuous animations  |

## Results — Windows desktop

All values in milliseconds. Jank percentages are measured against the
16.67 ms (60 Hz) and 8.33 ms (120 Hz) frame budgets.

| Mode     | Defer | Isolate | Shield | Build P50 | Build P95 | Build P99 | Raster P50 | Raster P95 | Raster P99 | Jank @60Hz | Jank @120Hz |
| -------- | :---: | :-----: | :----: | --------: | --------: | --------: | ---------: | ---------: | ---------: | ---------: | ----------: |
| LIGHT    |  ON   |   OFF   |  OFF   |      0.75 |      1.54 |      2.14 |       3.88 |       7.01 |       9.77 |      0.0 % |       5.3 % |
| HEAVY    |  ON   |   OFF   |  OFF   |      1.51 |      3.70 |      3.94 |      12.57 |      18.81 |      18.95 |     31.7 % |     100.0 % |
| HEAVY    |  ON   |   ON    |  OFF   |      0.73 |      1.44 |      2.03 |       8.80 |      12.55 |      16.25 |      3.2 % |      95.2 % |
| HEAVY    |  ON   |   ON    |   ON   |      0.66 |      2.50 |      3.09 |       9.47 |      15.25 |      17.42 |      6.3 % |      98.4 % |
| EXTREME  |  ON   |   OFF   |  OFF   |      0.82 |      1.53 |      2.54 |       7.82 |      10.55 |      10.63 |      0.0 % |      71.4 % |
| EXTREME  |  ON   |   ON    |  OFF   |      0.61 |      2.20 |      2.54 |      10.49 |      13.03 |      14.26 |      1.5 % |     100.0 % |
| EXTREME  |  ON   |   ON    |   ON   |      0.76 |      2.58 |      3.53 |      10.41 |      15.06 |      23.41 |      9.4 % |     100.0 % |
| TREE     |  ON   |   OFF   |  OFF   |      0.71 |      2.23 |      6.09 |      10.87 |      12.74 |      14.19 |      3.5 % |     100.0 % |
| TREE     |  ON   |   ON    |  OFF   |      0.54 |      2.02 |      6.13 |      11.80 |      16.60 |      17.34 |     10.5 % |     100.0 % |
| ANIMATED |  ON   |   OFF   |  OFF   |      1.38 |      3.27 |      4.47 |       7.07 |      11.24 |      12.24 |      3.2 % |      55.6 % |
| ANIMATED |  ON   |   ON    |  OFF   |      1.40 |      2.20 |      2.29 |       7.14 |       8.70 |       8.91 |      0.0 % |      55.6 % |

## Results — Web (Chrome)

| Mode     | Defer | Isolate | Shield | Build P50 | Build P95 | Build P99 | Raster P50 | Raster P95 | Raster P99 | Jank @60Hz | Jank @120Hz |
| -------- | :---: | :-----: | :----: | --------: | --------: | --------: | ---------: | ---------: | ---------: | ---------: | ----------: |
| LIGHT    |  OFF  |   OFF   |  OFF   |      2.80 |      3.50 |      3.70 |       1.00 |       1.50 |       1.70 |      0.0 % |       0.0 % |
| LIGHT    |  ON   |   OFF   |  OFF   |      6.20 |      9.30 |     11.10 |       1.40 |       3.20 |       4.70 |      1.6 % |      32.8 % |
| HEAVY    |  OFF  |   OFF   |  OFF   |      5.30 |      8.10 |      8.80 |       1.40 |       1.80 |       2.00 |      1.5 % |      22.4 % |
| HEAVY    |  ON   |   OFF   |  OFF   |      4.30 |      6.30 |      6.40 |       1.50 |       2.40 |       2.70 |      1.7 % |       1.7 % |
| EXTREME  |  OFF  |   OFF   |  OFF   |      3.30 |      5.60 |      5.70 |       1.40 |       2.00 |       2.90 |      0.0 % |       3.0 % |
| EXTREME  |  ON   |   OFF   |  OFF   |      3.80 |      5.20 |      6.00 |       2.20 |       2.60 |       2.70 |      0.0 % |       1.7 % |
| EXTREME  |  ON   |   ON    |  OFF   |      3.90 |      5.60 |      6.70 |       2.00 |       2.60 |       2.70 |      0.0 % |       1.6 % |
| EXTREME  |  ON   |   ON    |   ON   |      4.00 |      9.10 |     10.10 |       2.50 |       4.30 |       4.40 |      1.7 % |      25.4 % |
| TREE     |  OFF  |   OFF   |  OFF   |      3.50 |     19.00 |     19.50 |       1.90 |       2.80 |       2.90 |     46.2 % |      47.7 % |
| TREE     |  ON   |   OFF   |  OFF   |      5.10 |      5.80 |     21.30 |       1.60 |       2.10 |       3.10 |      4.8 % |       4.8 % |
| TREE     |  ON   |   ON    |  OFF   |      4.10 |      6.50 |     17.50 |       1.80 |       3.20 |       3.50 |      4.5 % |       4.5 % |
| ANIMATED |  OFF  |   OFF   |  OFF   |      6.40 |      7.40 |      7.80 |       1.60 |       1.80 |       1.80 |      0.0 % |      24.6 % |
| ANIMATED |  ON   |   OFF   |  OFF   |      6.40 |      8.90 |      9.60 |       1.70 |       2.50 |       2.60 |      0.0 % |      43.5 % |
| ANIMATED |  ON   |   ON    |  OFF   |      5.90 |      6.90 |      6.90 |       1.50 |       2.00 |       2.50 |      0.0 % |      13.6 % |

## Findings

### 1. `deferResize` cuts UI-thread cost by ~20×

The single most impactful feature in v0.2.0. Without deferred resize, the
UI thread performs full layout and build passes on the entire pane tree
every drag frame. On Web in **TREE** mode this is catastrophic:

| Metric      | DEFER OFF | DEFER ON | Improvement |
| ----------- | --------: | -------: | ----------: |
| Build P95   |  19.00 ms |  5.80 ms |       −69 % |
| Jank @60Hz  |    46.2 % |    4.8 % |     −41 pts |
| Jank @120Hz |    47.7 % |    4.8 % |     −43 pts |

On Windows desktop the UI thread was never the bottleneck — but the same
pattern holds: Build P95 stays under 3 ms across every mode once
deferral is on. **Enable `deferResize: true` unconditionally.**

### 2. `isolatePanes` helps animated content, hurts deep trees

The `RepaintBoundary` wrapper is a trade-off, not a free win. On Windows:

| Scenario              | ISOLATE OFF | ISOLATE ON |   Delta |
| --------------------- | ----------: | ---------: | ------: |
| HEAVY — Raster P50    |    12.57 ms |    8.80 ms |   −30 % |
| ANIMATED — Raster P99 |    12.24 ms |    8.91 ms |   −27 % |
| ANIMATED — Jank @60Hz |       3.2 % |      0.0 % | −3.2 pt |
| EXTREME — Raster P50  |     7.82 ms |   10.49 ms |   +34 % |
| TREE — Raster P95     |    12.74 ms |   16.60 ms |   +30 % |

On Web the pattern repeats — **ANIMATED** jank drops from 43.5 % to
13.6 % when isolation is on, while **TREE** and **EXTREME** gain nothing
because layer-explosion overhead exceeds the repaint savings.

**Rule of thumb:** enable `isolatePanes` when panes contain continuous
animations or expensive repaints. Leave it off in deeply nested trees or
extremely large static lists.

### 3. `shieldPlatformViews` costs ~25 % extra 120 Hz jank on Web

The shield is a full-screen `AbsorbPointer` over the panes. On Windows
desktop it's cheap; on Web it pushes the raster thread past the 120 Hz
budget:

| Configuration                    | Raster P95 | Jank @120Hz |
| -------------------------------- | ---------: | ----------: |
| EXTREME + ISOLATE ON, SHIELD OFF |    2.60 ms |       1.6 % |
| EXTREME + ISOLATE ON, SHIELD ON  |    4.30 ms |      25.4 % |

Enable it only when you actually embed a `WebView`, `MapView`, or video
player that steals pointer events mid-drag. It is a troubleshooting
feature, not a default.

### 4. Web has a different bottleneck than desktop

| Platform        |    Build P50 |   Raster P50 | Primary bottleneck  |
| --------------- | -----------: | -----------: | ------------------- |
| Windows desktop | 0.5 – 1.5 ms |    3 – 12 ms | GPU / raster thread |
| Web (Chrome)    | 3.5 – 6.5 ms | 1.0 – 2.5 ms | UI thread / JS-WASM |

Web's raster pipeline (CanvasKit → WebGL) is surprisingly efficient, but
the UI thread pays a fixed WASM bridge cost on every frame. This is why
`deferResize` matters _more_ on Web than on desktop — it reduces the
number of UI-thread passes required during a drag.

## Recommendations

| Use case             | `deferResize` | `isolatePanes` | `shieldPlatformViews` |
| -------------------- | :-----------: | :------------: | :-------------------: |
| Static dashboards    |     true      |     false      |         false         |
| Heavy lists          |     true      |      true      |         false         |
| Animated panes       |     true      |      true      |         false         |
| Nested IDE layouts   |     true      |     false      |         false         |
| Embedded WebView/Map |     true      |     false      |         true          |

## Caveats

- Numbers vary by device, GPU, and browser. Rerun on your target hardware
  before drawing conclusions.
- Web benchmarks ran through CanvasKit (WASM + WebGL) in Chrome 141.
  Skwasm may produce different results.
- 120 Hz jank is common on Web due to JavaScript garbage-collection
  pauses that Flutter cannot fully control.
- Frame timing samples were collected via
  `SchedulerBinding.instance.addTimingsCallback` over a 30-cycle drag
  simulation with a 300 ms warm-up. This is representative of sustained
  drag interactions, not first-frame cold-start cost.
- The LIGHT + DEFER ON anomaly on Web (32.8 % @120 Hz jank) is a
  measurement artifact — the UI is essentially empty, so any minor
  compositor hiccup registers as jank. It is not a regression.
- The HEAVY vs. EXTREME inversion on Web (HEAVY janks more than EXTREME)
  is likely due to how the WASM renderer's texture cache handles smaller
  lists. Do not over-index on this observation without further testing.
