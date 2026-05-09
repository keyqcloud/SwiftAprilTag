# Tag Size Convention

A consistently-misread detail with serious downstream consequences.

## Overview

Two different "sizes" can be reported for an AprilTag, and confusing them produces calibration errors that look like camera miscalibration even when the camera is fine.

## What AprilTag detects

The AprilTag library's ``Detection/corners`` always land on the **outer corners of the black border** — the edge where the solid black square meets whatever surrounds it (white margin, white paper, table, etc.).

```
   white padding
   ┌─────────────────┐
   │  black border   │
   │  ┌───────────┐  │
   │  │ data bits │  │ ← detection corners are at these
   │  │           │  │   four corners (outer black edges)
   │  └───────────┘  │
   │                 │
   └─────────────────┘
```

This is the dimension you must pass to ``Detection/estimatePose(intrinsics:tagSize:)`` as `tagSize`.

## What tag distributors often report

Many AprilTag PDFs available online (notably [`rgov/apriltag-pdfs`](https://github.com/rgov/apriltag-pdfs)) label tags by the **full image size including the white margin**. A "100mm" tag from such a PDF often has only a ~70–80 mm outer black border.

For tag36h11 specifically, the standard rendering is 8 grid units (data + 1-bit black border) wrapped in a 1-bit white margin → 10 grid units total. So a "10 cm" image has an 8 cm black border.

## Why this matters for pose

Pose estimation solves a Perspective-n-Point problem from your declared `tagSize` and the observed pixel positions of the corners. If you tell the solver `tagSize = 0.1` (m) but the actual outer-black-border is 0.08 m, every recovered position scales by `0.08 / 0.1 = 0.8`. A tag at 50 cm depth will be reported at 40 cm depth.

## How to be sure

**Measure the printed tag with a ruler or calipers.** Lay the ruler across just the black square; ignore the white area around it. That number — the outer black border edge length — is what goes into `tagSize`. Don't trust the filename or the distributor's labeling.

If you generate tags programmatically from the upstream `apriltag-imgs` repository, the native rendered images have a 1-pixel white margin built in. After scaling them up for printing, multiply your printed full-image size by `8/10` to get the actual outer-black-border edge length.
