# Roadmap

## Done

- **Engine:** file inspection, per-file plans, FFmpeg runner with progress,
  graceful cancel and pause, safe output handling, capability detection
  (encoders, working hardware encoders, accepted SVT-AV1 parameters).
- **Goals:** "Make it small" (HEVC, AV1, graphics card) and "Edit in DaVinci
  Resolve" on Linux (Studio and free).
- **UI:** one screen, live-editable queue, progress with time left and expected
  size, 10-second sample, keep-awake on Linux and macOS, "Show the command",
  "More options", English and Ukrainian, light and dark.
- **CI:** analysis, tests and release builds for Linux, Windows and macOS.

## Next

1. **More goals**
   - Phone / Telegram: small H.264 that plays on any phone, with HDR sources
     tone-mapped.
   - Extract audio: original track untouched, or MP3, WAV, FLAC, AAC.
   - Remove personal metadata: quick (no quality loss) and thorough
     (re-encode), with a report of what was removed.
   - Change format without re-encoding.
2. **Quality calibration.** The quality levels are starting values. Measure
   them on real footage (VMAF) and fix the numbers so that "Recommended" and
   "Best quality" mean the same across encoders.
3. **Check in Resolve.** Import converted files into Resolve to confirm picture
   and sound decode. The free edition and the AV1 "Smallest" variant still need
   a test on a machine with the free edition.
4. **Use the whole machine.** One encode often leaves most cores idle.
   Run several conversions at once according to CPU, memory and graphics-card
   capacity; lower process priority so the desktop stays responsive; consider
   splitting a single long video into chunks encoded in parallel.
5. **Estimates before starting.** Learn the typical compression per goal from
   past conversions; check free disk space.
6. **Comfort.** Settings (language, speed, output naming), remembering the
   last-used goal, finish notification, taskbar progress.
7. **Ship.**
   - Bundle a pinned FFmpeg per platform, with licence notices and source.
   - Windows: keep-awake, pause, and ending FFmpeg when the app ends.
   - Installers (AppImage/deb, Windows installer, dmg) and release notes with
     the first-run security prompts explained.
   - Make the conversion tests pass on Windows and macOS and turn them into a
     required check.

## Later

Automatic quality per video, "fit into N MB", user-defined goals, lossless
trimming, an in-app before/after comparison for samples, watch folders,
signing and notarization, automatic updates.

## Open decisions

- Licence for the app code.
- Application identifier (currently the Flutter template default).
