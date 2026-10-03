# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Flutter desktop app (Linux, Windows, macOS) that converts batches of videos
by goal ("Make it small", "Edit in DaVinci Resolve", "Send to a phone", …). It
drives the `ffmpeg` and `ffprobe` executables as separate processes; it does
not link FFmpeg libraries. FFmpeg is not bundled yet: it is found on `PATH`
(FFmpeg 8 or newer, with `libx265`, `libsvtav1`, `prores_ks`, `dnxhd`).

What is built and what is not: `docs/ROADMAP.md`.

## Commands

```sh
flutter pub get
flutter run -d linux                                  # or -d windows, -d macos
flutter build linux --release                         # build/linux/x64/release/bundle

flutter test --exclude-tags "ffmpeg || screenshots"   # fast: logic and widgets
flutter test --tags ffmpeg                            # real conversions, needs ffmpeg + ffprobe
flutter test --tags screenshots                       # writes PNGs to build/screenshots/

flutter test test/app/workspace_test.dart             # one file
flutter test test/app/workspace_test.dart --plain-name "pause holds the queue"

flutter analyze
dart format lib test tool                             # CI fails on unformatted code
flutter gen-l10n                                      # after editing lib/l10n/*.arb

dart run tool/convert.dart --list                     # the engine without the UI
dart run tool/convert.dart compress.hevc clip.mov --dry-run
```

- Several `--exclude-tags` flags do not combine; use the `"a || b"` form.
- After a UI change, run the screenshots and look at the PNGs.
- CI (`.github/workflows/ci.yml`) runs the format check, `flutter analyze`,
  the fast tests, the `ffmpeg` tests and a release build on Linux, Windows and
  macOS. The `ffmpeg` tests are required on Linux only; they have never been
  run on the other two.

## Architecture

### Two layers

- `lib/core/` is the engine: plain Dart with no Flutter imports, so it runs
  under `dart run` (`tool/convert.dart`) and is tested without widgets.
- `lib/app/` is the Flutter UI and its state (Riverpod notifiers).

### How a conversion is decided (`lib/core`)

A preset holds no command line. `Preset.plan(MediaInfo, options,
Capabilities)` (`scenarios/scenario.dart`) looks at one file and returns a
`ConversionPlan` with a `PlanKind`: `skip` (already fine), `remux`,
`audioOnly`, `encode` or `unsupported`. Re-encoding is the last resort.

- `media/ffprobe.dart` turns a file into `MediaInfo`; the whole ffprobe report
  is kept on `MediaInfo.raw` for the details window.
- `ffmpeg/capabilities.dart` probes what this FFmpeg and machine can really
  do (encoders, working hardware encoders, filters, accepted SVT-AV1
  parameters). Presets consult it; nothing is assumed.
- `ffmpeg/command_builder.dart` turns a plan into arguments. A sample is the
  same arguments plus a time range, so a sample cannot differ from the real
  result. `forDisplay: true` gives the version shown to people.
- `ffmpeg/runner.dart` runs the process (progress, graceful cancel, pause);
  `queue/job_executor.dart` wraps one conversion: temporary file, rename on
  success, cleanup on failure.
- `estimate/size_estimator.dart` predicts output size: calculated for copies
  and fixed-rate formats, measured by encoding short pieces otherwise.
- `scenarios/registry.dart` lists the scenarios in display order.

Sound: lossless or unusual sound (the FLAC or PCM of an editor export) becomes
AAC at 320 kbit/s for stereo (`highQualityAac` in `scenarios/blocks.dart`); AAC
already at or below that is copied untouched. Resolve on Linux is the
exception: it reads no AAC, so those presets write PCM.

### App state (`lib/app`)

Four notifiers, each owning one concern. Data flows left to right:

```
sourcesProvider ─┐
                 ├─> previewProvider ──> (video list, panel summary)
recipeProvider ──┤        │
                 │   estimateCacheProvider <── finished samples
                 └─> queueProvider ──> JobExecutor
```

- **Videos** (`sources/`): files added, each path once. The selection says
  which videos the panel applies to; newly added videos become the selection.
- **Recipe** (`recipe/`): the panel's goal, options, whole video or sample, and
  output folder. Goal and folder are remembered (`settings.dart`); the sample
  choice is not.
- **Preview** (`sources/preview_controller.dart`): plans each selected video
  with the current recipe and has its expected size measured, only while the
  queue is idle.
- **Queue** (`queue/`): a job is a snapshot (video info, recipe, plan, output
  path) made by Add to queue / Add all, so later panel changes do not touch
  it. The queue starts by itself and runs one job at a time. An identical job
  still pending is not added twice.
- **Estimates** (`estimates/`): expected sizes shared by the video list and
  the queue, keyed by file and goal; a finished sample overwrites a
  measurement with its better one.

Output names carry the settings through each preset's `nameSuffix`
(`_hevc-crf20`); samples add `_sample10s` and go to `Samples/`.
`test/core/scenarios/file_names_test.dart` lists them all.

The screen (`home/`) is three panes over those providers: `videos_pane`,
`queue_pane`, `recipe_pane`. `home/scenario_texts.dart` maps scenario, preset
and option ids to words; the engine knows them only by id.

### The seam for tests

Everything that touches the machine is reached through `environmentProvider`
(`providers.dart`): ffprobe, the job executor, capabilities, the sleep
inhibitor, the estimator, the thumbnailer. Tests replace it with
`FakeEnvironment` (`test/support/fakes.dart`), whose fake jobs finish only when
the test says so. `test/support/pump_app.dart` is the widget-test harness;
`test/support/test_media.dart` generates real clips for the `ffmpeg` tests, so
no footage is stored in the repository.

## UI rules that tests enforce

The test of every UI decision: a non-technical person drops in large camera
videos and gets small files that look the same, with no help.

- **Plain words lead; technical names follow in smaller type** ("Smallest
  file" with "AV1" underneath). Technical terms on the main screen go only
  through the `TechnicalText` widget (`home/technical_text.dart`).
  `test/app/home_screen_test.dart` checks every other text against a list of
  terms, in both languages.
- **Nothing to scroll in the "What to do" panel.** It shows every control at
  the smallest window size (`window.dart`), in every goal, option and
  language. `test/app/no_scrolling_test.dart` checks every combination at
  three window heights, and also that no label is cut off or broken inside a
  word. So a new control takes one row (label beside the control), and
  anything bigger opens in a small window ("More options…"). If the test
  fails after a change, make the change fit; do not raise the minimum window
  size without a reason.
- **Safe defaults.** "Make it small" with "Works everywhere" is pre-selected:
  drop videos, press Add to queue, done.
- More is available on request only: "More options…", and "Show the command"
  and "Video details" in the ⋯ menus.

## Adding a goal

1. Write `lib/core/scenarios/<name>.dart` with a `Scenario` and its presets.
   Give the plan a `nameSuffix` that names the settings that matter.
2. Add it to `scenarios` in `registry.dart`.
3. Add its texts to both ARB files and to `home/scenario_texts.dart`.
4. Add table-driven plan tests in `test/core/scenarios/`, a row in
   `file_names_test.dart`, and at least one real conversion in
   `test/integration/conversion_test.dart`.

The UI renders presets and options generically; it needs no other change.

## Conventions

- Tests are named for the behaviour they check, and assert what a user would
  observe.
- A user-facing string goes in **both** ARB files (`app_en.arb` is the
  template; the generated `app_localizations*.dart` files are committed).
- FFmpeg arguments are always a list, never a shell string. Paths are passed
  with the `file:` prefix (`inputUrl`).
- Outputs are written to a hidden `.name.part` file and renamed on success.
  Originals are never overwritten.
- No personal information in files: no usernames, home paths, hostnames or
  real names. Use relative paths and placeholders.

## Things that were learned the hard way

- **Colour tags:** FFmpeg 8 carries primaries, transfer, matrix and range from
  source to output by itself and ignores `-color_primaries`, `-color_trc` and
  `-colorspace` for encodes. Presets pass no colour arguments; the HLG tests
  in `conversion_test.dart` are what guards this.
- **SVT-AV1 parameters:** an unknown `-svtav1-params` key only produces a
  warning ("Error parsing option") and exit code 0. `CapabilityProbe` checks
  the warning text, not just the exit code.
- **Hardware encoders:** being listed by `ffmpeg -encoders` means compiled in,
  not usable. Each is tested with a real 8-frame encode, in 10-bit.
- **MOV cannot hold AV1 or VP9** when written by FFmpeg; those go to MP4.
- **Muxer-specific options** such as `-write_tmcd` and `-movflags` make
  FFmpeg fail on other containers; add them only for MP4/MOV.
- **MP4 drops unknown tags** such as `make` when writing; MOV keeps them.
  Matters for test fixtures with planted metadata.
- **Tone mapping** needs the `zscale` and `tonemap` filters, which not every
  build has; `Capabilities.hasFilter` is checked first.
- **Cancel:** `q` on stdin makes FFmpeg finish the file and exit with code 0,
  so the runner tracks cancellation itself.
- **Expected size** of a quality-targeted encode cannot be calculated; the
  estimator encodes 3-second pieces spread over the video (picture only; the
  sound is calculated) and scales up. It is stopped when converting starts.
- **Byte counts overflow when multiplied.** Tens of gigabytes times
  gigabytes exceeds 64-bit integers; take the ratio first.
- **Widget tests:**
  - Real disk access never completes inside the test's fake clock; go through
    `addVideos()` in `pump_app.dart`, which uses `tester.runAsync`.
  - Awaiting `StreamSubscription.cancel()` also escapes the fake clock; the
    queue controller does not await it.
  - `pumpAndSettle` never returns while a job runs (its progress bar
    animates); pump fixed times instead.
  - Without `loadRealFonts()` text is laid out in a much wider placeholder
    font; tests about what fits must load the real ones.
- **Fonts:** both fonts are bundled so text takes the same room on every
  computer (the no-scrolling layout depends on it). Roboto is the interface
  font; it has no arrow glyphs, so JetBrains Mono is its fallback. JetBrains
  Mono is also the fixed-width font, because the generic `monospace` family
  does not resolve to one on every Linux desktop.
- **Resolve on Linux** (Blackmagic's codec list for 21.1): no AAC in either
  edition, no H.264/H.265 in the free edition. Details in the header of
  `resolve_linux.dart`.
