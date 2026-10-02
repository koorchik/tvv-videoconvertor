# TVV Video Converter

A desktop app that converts batches of videos for a few everyday goals, built
for people who do not want to learn what a codec is. It is a friendly front end
for [FFmpeg](https://ffmpeg.org/).

Drop videos in, pick what you want, press Start.

## What it does today

- **Make it small.** Shrinks a video to a fraction of its size while looking
  the same: for storing finished videos and for uploading camera footage to
  services such as Google Photos. Output is 10-bit, in a choice of
  - *Works everywhere* (HEVC, the default),
  - *Smallest file* (AV1),
  - *Fastest* (graphics card, offered only when a working one is found).
- **Edit in DaVinci Resolve (Linux).** Makes camera and screen recordings open
  with both picture and sound in Resolve on Linux, for Resolve Studio and for
  the free edition.
- **Send to a phone.** A small file that plays on any phone and in messengers
  such as Telegram. HDR footage is adjusted to look right on ordinary screens.
- **Get the sound.** Saves the sound track as its own file, untouched by
  default, or as MP3, M4A, WAV or FLAC.
- **Remove personal details.** Strips place, date, camera and author
  information before sharing. Quick (picture and sound copied untouched) or
  thorough (rebuilt from scratch).
- **Change file type.** Moves a video into MP4, MKV or MOV in seconds, without
  re-encoding the picture.

It does the least work that reaches the goal. A file that is already fine is
left alone; a file that only needs its sound converted is done in seconds with
the picture copied untouched; only what must be re-encoded is re-encoded.

Also:

- The list stays editable while converting: add, remove, reorder, cancel one
  file or stop everything. Failed or cancelled files can be retried.
- Progress, time left and expected size per file and for the whole batch.
- **Try a 10-second sample** before a long conversion, from the start or the
  middle, and get the expected size and time for the whole video.
- The computer is kept awake while converting (Linux and macOS).
- **Show the command:** every video can show the exact FFmpeg command, on one
  line or explained option by option, ready to paste into a terminal.
- Originals are never modified or overwritten. Unfinished outputs are removed.
- English and Ukrainian, light and dark, following the system.

## Status

Early but working on Linux. Not done yet:

- FFmpeg is **not bundled**; it must be installed (see below).
- Windows and macOS builds compile in CI but have not been tried on real
  machines. Keeping the computer awake and pausing are not implemented on
  Windows.
- Only one video is converted at a time.
- The quality levels are sensible starting values, not yet measured on real
  footage.

See [docs/ROADMAP.md](docs/ROADMAP.md).

## Requirements

- FFmpeg 8 or newer with `ffprobe`, on the `PATH`, built with `libx265`,
  `libsvtav1`, `prores_ks` and `dnxhd`. Distribution packages and the common
  Windows/macOS builds include these.
- To build: [Flutter](https://docs.flutter.dev/get-started/install) 3.47 or
  newer with desktop support. On Linux also `ninja-build` and `libgtk-3-dev`.

## Run and build

```sh
flutter pub get
flutter run -d linux          # or: -d windows, -d macos
flutter build linux --release # result in build/linux/x64/release/bundle
```

## Tests

```sh
flutter test --exclude-tags "ffmpeg || screenshots"  # fast: logic and UI
flutter test --tags ffmpeg                           # real conversions, needs FFmpeg
flutter test --tags screenshots                      # renders the screen to build/screenshots/
```

The conversion tests generate their own small clips; no footage is stored in
the repository.

## Command-line tool for development

The conversion engine can be driven without the UI:

```sh
dart run tool/convert.dart --list                 # goals and their options
dart run tool/convert.dart --caps                 # what this FFmpeg and machine can do
dart run tool/convert.dart compress.hevc clip.mov # convert one file
dart run tool/convert.dart resolve.studio clip.mp4 --dry-run   # only show the plan and command
dart run tool/convert.dart compress.av1 clip.mov --sample 30:10 --opt quality=maximum
```

## How it is organised

```
lib/core/   the conversion engine, plain Dart with no UI code
  media/      reading what a file contains (ffprobe)
  scenarios/  the goals: each looks at a file and plans the least work
  ffmpeg/     finding FFmpeg, what it can do, building and running commands
  queue/      running one conversion safely (temporary file, rename, cleanup)
  estimate/   speed, time left, expected size
lib/app/    the Flutter UI
lib/l10n/   texts in English and Ukrainian
tool/       developer tools
test/       tests, mirroring lib/
```

Adding a goal means one file in `lib/core/scenarios/`, one line in
`registry.dart`, and its texts; see [CLAUDE.md](CLAUDE.md).

## Licence

Not chosen yet. FFmpeg is a separate program under its own licence (LGPL or
GPL, depending on the build).
