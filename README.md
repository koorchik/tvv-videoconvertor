# TVV Video Converter

A desktop app that converts batches of videos for a few everyday goals, built
for people who do not want to learn what a codec is. It is a friendly front end
for [FFmpeg](https://ffmpeg.org/).

Drop videos in, pick what you want, press **Add to queue**. Converting starts
by itself.

## What it does today

- **Make it small.** Shrinks a video to a fraction of its size while looking
  the same: for storing finished videos and for uploading camera footage to
  services such as Google Photos. Output is 10-bit, in a choice of
  - *Works everywhere* (HEVC, the default),
  - *Smallest file* (AV1),
  - *Fastest* (graphics card, offered only when a working one is found).

  Sound is made compact too: the lossless sound of an editor export (FLAC,
  PCM) becomes AAC at 320 kbit/s, which is a small part of a high-quality
  video. Sound that is already AAC is kept untouched.
- **Edit in DaVinci Resolve (Linux).** Makes camera and screen recordings open
  with both picture and sound in Resolve on Linux, for Resolve Studio and for
  the free edition.
- **Send to a phone.** A small file that plays on any phone and in messengers
  such as Telegram. HDR footage is adjusted to look right on ordinary screens.
- **Get the sound.** Saves the sound track as its own file, untouched by
  default, or as MP3, M4A, WAV or FLAC.
- **Remove personal data.** Strips place, date, camera and author
  information before sharing. Quick (picture and sound copied untouched) or
  thorough (rebuilt from scratch).
- **Change file type.** Moves a video into MP4, MKV or MOV in seconds, without
  re-encoding the picture.

It does the least work that reaches the goal. A file that is already fine is
left alone; a file that only needs its sound converted is done in seconds with
the picture copied untouched; only what must be re-encoded is re-encoded.

### How it works

The window has three parts:

- **Your videos** (top left): the files you added, each listed once. Newly
  added videos are selected, so dropping videos and pressing Add to queue is
  all it takes.
- **What to do** (right): the goal and its options, whole video or a
  10-second sample, and where to save. It applies to the selected videos.
  **Add to queue** queues them; **Add all** queues every video.
- **Queue** (bottom left): starts by itself, one conversion at a time. Pause,
  reorder, cancel or retry at any time.

Change the settings and press Add to queue again to get the same video in
another form: each job keeps the settings it was added with, and output names
carry them (`clip_hevc-crf20.mp4`, `clip_av1-crf25.mp4`, `clip_phone-1080p.mp4`).

Also:

- **Samples:** choose "10-second sample" to make a short piece with exactly
  the chosen settings, from the start or the middle. Samples go to a
  `Samples` folder, and their row shows the sample's size and the expected
  size of the whole video. "Convert whole video" then queues the real thing.
- **Expected size before starting:** for each selected video and in total,
  with the time it will take. Where the size depends on the footage, short
  pieces are encoded in the background with the exact settings and scaled up.
- Progress, time left and expected size while converting.
- **Video details:** a frame of the video and its key facts, then every
  detail (codecs, bitrates, colour, HDR, sound tracks, timecode), all
  metadata tags with the personal ones marked, and FFmpeg's full report. For
  the original and, once converted, for the result.
- **Show the command:** the exact FFmpeg command for any video or job, on one
  line or explained option by option, ready to paste into a terminal.
- The computer is kept awake while converting (Linux and macOS).
- Originals are never modified or overwritten. Unfinished outputs are removed.
- Plain words first, with the technical detail beside them in smaller type
  ("Smallest file" with "AV1" underneath).
- English and Ukrainian, switchable in the app; light and dark following the
  system. The language, last goal and output folder are remembered.

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
lib/app/    the Flutter UI: sources/ (videos), recipe/ (what to do),
            queue/, estimates/, home/ (the screen)
lib/l10n/   texts in English and Ukrainian
tool/       developer tools
test/       tests, mirroring lib/
```

Adding a goal means one file in `lib/core/scenarios/`, one line in
`registry.dart`, and its texts; see [CLAUDE.md](CLAUDE.md).

## Licence

Not chosen yet. FFmpeg is a separate program under its own licence (LGPL or
GPL, depending on the build). The bundled fonts are Roboto (Apache License
2.0) and JetBrains Mono (SIL Open Font License); their licence texts are in
`assets/fonts/`.
