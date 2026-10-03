# Roadmap

## Done

- **Engine:** file inspection, per-file plans, FFmpeg runner with progress,
  graceful cancel and pause, safe output handling, capability detection
  (encoders, working hardware encoders, accepted SVT-AV1 parameters).
- **Goals:** "Make it small" (HEVC, AV1, graphics card), "Edit in DaVinci
  Resolve" on Linux (Studio and free), "Send to a phone", "Get the sound",
  "Remove personal details" and "Change file type".
- **UI:** videos, settings and queue as separate parts; the queue starts by
  itself and can be paused, reordered and edited; the same video can be
  queued with different settings, and output names carry the settings;
  samples are an option and report the whole video's expected size; expected
  size and time before starting; video details for originals and results;
  keep-awake on Linux and macOS; "Show the command"; technical names beside
  plain labels; English and Ukrainian with a switcher; light and dark.
  Language, last goal and output folder are remembered.
- **CI:** analysis, tests and release builds for Linux, Windows and macOS.

## Next

1. **Finish the newer goals**
   - Remove personal details: show a report of what was removed, and offer
     neutral file names (a name can give away a place or a date).
   - Send to a phone: "fit into N MB" for services with a size limit.
   - Get the sound: choose which track, or all of them.
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
5. **Disk space.** Warn before starting when the expected output does not fit.
6. **Comfort.** Settings (speed, output naming), finish notification,
   taskbar progress.
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
