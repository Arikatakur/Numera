# Handoff: App Icon + First-Launch Animation (Numera)

## Overview
Two things to implement in the Numera iOS app (SwiftUI):
1. A new **App Icon** (replacing the currently-empty `AppIcon.appiconset`).
2. A **first-launch animation**: the monogram mark fades in centered, glides left, and the "NUMERA" wordmark reveals letter-by-letter (A → N) beside it, finishing with a tagline.

## About the Design Files
The bundled `reference_design.dc.html` is a **design reference built in HTML** — it shows the exact visual target, timing, easing, and layout, but it is not production code. Recreate this in SwiftUI using Numera's existing design system (`AppColors`, `AppSpacing`, etc.) — do not port HTML/CSS/JS directly, and do not introduce new color literals where an existing token already matches (see Color Mapping below).

## Fidelity
**High-fidelity.** Exact colors, sizes, durations, and easing curves are specified below — implement pixel/point-accurate, adjusting only for SwiftUI idiom and real device safe areas.

---

## 1. App Icon

### Assets provided
- `app-icons/icon-1024.png` — master icon, flat 1024×1024 square (no rounded corners, no glow/shadow baked in — iOS applies the corner mask and shine itself).
- `app-icons/AppIcon.appiconset/` — drop-in replacement matching the repo's current single-icon `Contents.json` setup (just the 1024 PNG + manifest).
- `app-icons/AppIcon-FullSet.appiconset/` — full legacy multi-size set (20–1024px, iPhone + iPad + App Store) with its own `Contents.json`, in case the target/build needs explicit per-size assets rather than the single 1024 universal entry.
- `numera-mark.png` — the monogram glyph alone, cropped tight with transparent background (no icon-square framing). This is the same art used inside the launch animation.

### Task
Replace `Numera/Resources/Assets.xcassets/AppIcon.appiconset/` contents with the provided set (use whichever `Contents.json` variant matches what the project's Xcode version/target expects — check the existing `Contents.json` in the repo first since one is already present and may only need its image swapped in). Build and confirm the icon shows correctly on the home screen, in Settings, and in Spotlight (these render at small sizes — confirm the monogram stays legible at 40–60pt, that's what the `app-icons/icon-40.png` … `icon-60.png` files are for, pre-rendered for spot-checking).

---

## 2. First-Launch Animation

### What it is
A splash/intro sequence shown once when the app launches (before or as part of the existing launch/loading flow — wire it in wherever the app currently shows its launch screen). It is NOT a tab or settings screen; it plays once and then proceeds into the app.

### Visual elements (3 layers, all centered as a group)
1. **Glyph** — `numera-mark.png`, the monogram mark. Natural aspect ratio ≈ 64:57 (w:h).
2. **Wordmark** — the word **NUMERA**, set in 6 individual letter glyphs (so each can animate independently), bold, ~25pt, letter-spacing ~0.14em (i.e. roughly +3.5pt tracking at this size — use SwiftUI `.kerning()` here), color `AppColors.textPrimary`.
3. **Tagline** — "Understand your money." — ~13.5pt, letter-spacing ~0.04em, color `AppColors.textSecondary` at ~55% opacity (or `AppColors.textSecondary.opacity(0.55)`).
4. **Glow** — soft radial highlight behind the glyph, ~180×180pt circle, `AppColors.accent` at low opacity (~0.3 at core, fading to 0), pulsing gently and continuously (scale 1↔1.12, opacity 0.55↔0.9, 3.2s ease-in-out, looping) — gives the mark a soft "alive" glow rather than a flat icon.

### Layout
- Background: full-bleed `AppColors.background`.
- The glyph + wordmark form one horizontal group, gap ~16pt between them, and this whole group is **horizontally and vertically centered** on screen while merged.
- Before merging, the glyph alone sits centered on screen (both axes); the wordmark is hidden/invisible until the merge.
- Tagline sits ~24pt below the glyph/wordmark row, horizontally centered.

### Sequence & timing (total ≈ 3.7s, then settles)
| Time | Event |
|---|---|
| 150ms | Glyph fades in (opacity 0→1) and scales up slightly (0.82→1), centered on screen. Duration ~1s, ease-out. |
| 1700ms | Glyph begins gliding from center to its final left-of-wordmark position. Duration **1.35s**, easing curve `cubic-bezier(0.16, 0.84, 0.24, 1)` (a slow-starting, confident glide — in SwiftUI use `Animation.timingCurve(0.16, 0.84, 0.24, 1, duration: 1.35)`, iOS 17+, or approximate with `.easeOut(duration: 1.35)` if targeting earlier). The glow circle moves in lockstep with the glyph's center, same duration/curve. |
| 1880ms | Letters start revealing **one at a time**, in this exact order: **A, R, E, M, U, N** (i.e. the word spelled backwards — last letter appears first, first letter appears last, in sync with the glyph sliding past each letter's position). |
| +120ms per letter | Each subsequent letter reveals 120ms after the previous (so all 6 are done within 600ms of the first). Each letter individually animates opacity 0→1 + translateY 10pt→0, duration 0.6s, easing `cubic-bezier(0.2, 0.9, 0.3, 1)`. |
| +350ms after last letter | Tagline fades in (opacity 0→1) + translateY 8pt→0, duration 0.9s, ease-out. |

After the tagline settles (~4.6s total from launch), transition into the app's normal launch/home flow.

### Reveal order detail (important)
Word = N-U-M-E-R-A (positions 1–6 left to right). The reveal is **not** left-to-right — it's reverse order: the **last** letter (A) appears first, then R, E, M, U, and finally N (the first letter) appears last. Each letter is positioned in its correct final left-to-right slot the whole time; only its opacity/offset animate — there's no letter reordering or movement other than that fade+rise.

### Color mapping (use existing tokens — do not hardcode new hex)
The HTML reference uses placeholder colors since it didn't have access to the real design system. Map them to `Numera/DesignSystem/AppColors.swift` tokens:
- Screen background `#0A0D10` → **`AppColors.background`** (`#101419`)
- Wordmark text `#F7F9F8` → **`AppColors.textPrimary`** (`#F8FAFC`)
- Tagline text `rgba(247,249,248,0.55)` → **`AppColors.textSecondary`** (`#9AA6B2`), or `AppColors.textPrimary.opacity(0.55)` if you want to stay closer to the reference's "dimmed primary" look — designer's call, both read fine.
- Glow accent `rgba(126,230,150,…)` (a placeholder mint) → **`AppColors.accent`** (`#B8F36A`, mint-volt) at the same opacity curve (0.3 core / 0.55–0.9 pulse).

### Interaction
No user interaction required — it's a one-time, non-skippable intro (or skippable-on-tap if that matches how the rest of the app handles loading states; use your judgment / existing app conventions, this wasn't specified).

---

## Assets
- `app-icons/` — full icon set + two `Contents.json` variants (see above).
- `numera-mark.png` — transparent-background monogram glyph, used both inside the icon (already composited) and standalone for the launch animation.
- Source: cropped and cleaned from the user's original brand sheet (`logo.png`, not included in this bundle — ask the user if you need the original vector/source art for higher-res re-export later; this PNG is a raster crop).

## Files
- `reference_design.dc.html` — the interactive HTML reference. Open in a browser to see the icon at all sizes and play/replay the exact launch animation timing. All values above were read directly from this file's logic.
