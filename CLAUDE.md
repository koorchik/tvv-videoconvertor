# TVV Video Converter

Flutter desktop app (Linux, Windows, macOS) that converts batches of videos by
goal. It drives the `ffmpeg` and `ffprobe` executables as separate processes;
it does not link FFmpeg libraries. Roadmap and what is not built yet:
`docs/ROADMAP.md`.

## Who it is for

The test of every UI decision: a non-technical person drops in large camera
videos and gets small files that look the same, with no help. So:

- The main screen shows no technical terms (codec names, bitrates, CRF).
  `test/app/home_screen_test.dart` enforces this with a list of banned words,
  in both languages.
- Everything has a safe default. "Make it small" with "Works everywhere" is
  pre-selected: drop, Start, done.
- Detail is available on request, never by default: "More options", and
  "Show the command" on each video.

## Commands

```sh
flutter test --exclude-tags "ffmpeg || screenshots"  # fast (about 3 s)
flutter test --tags ffmpeg          # real conversions with the installed FFmpeg (about 30 s)
flutter test --tags screenshots     # writes PNGs of the screen to build/screenshots/
flutter analyze
dart format lib test tool
flutter gen-l10n                    # after editing lib/l10n/*.arb
flutter build linux --release
dart run tool/convert.dart --list   # engine without the UI; see the file header
```

After a UI change, run the screenshots and look at the PNGs. Multiple
`--exclude-tags` flags do not combine; use the `"a || b"` expression.

## Layout

- `lib/core/`: the engine. Plain Dart, no Flutter imports, so it runs under
  `dart run` and is tested without widgets.
  - `media/`: `MediaInfo` and the ffprobe parser.
  - `scenarios/`: goals. `scenario.dart` defines `Preset` and
    `ConversionPlan`; `registry.dart` lists the scenarios in display order.
  - `ffmpeg/`: locating FFmpeg, `Capabilities` (probed, not assumed),
    `command_builder.dart` (plan to arguments), `runner.dart` (process,
    progress, cancel, pause), `command_text.dart` (commands as text for people).
  - `queue/job_executor.dart`: one conversion from plan to finished file.
  - `estimate/`, `output/`, `platform/`.
- `lib/app/`: the UI. `queue/queue_controller.dart` is the Riverpod notifier
  holding the list and running it; `home/` is the single screen;
  `home/scenario_texts.dart` maps scenario, preset and option ids to texts.
- `lib/l10n/`: `app_en.arb` (template) and `app_uk.arb`. The generated
  `app_localizations*.dart` files are committed.
- `test/` mirrors `lib/`. `test/support/` has the fakes (`fakes.dart`), made-up
  inputs (`fake_media.dart`), real clip generation (`test_media.dart`) and the
  widget-test harness (`pump_app.dart`).

## How a conversion is decided

A preset does not hold a command line. `Preset.plan(MediaInfo, options,
Capabilities)` returns a `ConversionPlan` for that one file, with a `PlanKind`:
`skip` (already fine), `remux`, `audioOnly`, `encode` or `unsupported`.
Re-encoding is the last resort. `buildFfmpegArgs` turns a plan into arguments;
a sample run is the same arguments plus a time range, so a sample cannot differ
from the real result.

## Adding a goal

1. Write `lib/core/scenarios/<name>.dart` with a `Scenario` and its presets.
2. Add it to `scenarios` in `registry.dart`.
3. Add its texts to both ARB files and to `home/scenario_texts.dart`.
4. Add table-driven plan tests in `test/core/scenarios/` and at least one real
   conversion in `test/integration/conversion_test.dart`.

The UI renders presets and options generically; it needs no other change.

## Conventions

- Tests are named for the behaviour they check, and assert what a user would
  observe.
- A user-facing string goes in **both** ARB files. Plain words; if a term
  would land on the banned list, it belongs behind "More options" or in the
  command view.
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
- **MOV cannot hold AV1 or VP9** when written by FFmpeg; those go to MP4.
- **Cancel:** `q` on stdin makes FFmpeg finish the file and exit with code 0,
  so the runner tracks cancellation itself.
- **Hardware encoders:** being listed by `ffmpeg -encoders` means compiled in,
  not usable. Each is tested with a real 8-frame encode, in 10-bit.
- **Widget tests:** real disk access never completes inside the test's fake
  clock; go through `addVideos()` in `pump_app.dart` (it uses
  `tester.runAsync`). Awaiting `StreamSubscription.cancel()` also escapes the
  fake clock; the controller does not await it.
- **Resolve on Linux** (Blackmagic's codec list for 21.1): no AAC in either
  edition, no H.264/H.265 in the free edition. Details in the header of
  `resolve_linux.dart`.
