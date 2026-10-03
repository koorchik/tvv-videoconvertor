/// Changes the file type of a video without re-encoding the picture.
///
/// The picture is moved as it is into the new container, which takes seconds
/// and loses nothing. Sound is moved the same way when the container can hold
/// it and converted when it cannot.
library;

import '../ffmpeg/capabilities.dart';
import '../media/media_info.dart';
import 'blocks.dart';
import 'scenario.dart';

const remuxScenario = Scenario(id: 'remux', presets: [RemuxPreset()]);

/// What FFmpeg can write into each container.
const _mp4Video = {'h264', 'hevc', 'av1', 'vp9', 'mpeg4', 'mpeg2video'};
const _movVideo = {
  'h264',
  'hevc',
  'prores',
  'dnxhd',
  'mjpeg',
  'mpeg4',
  'mpeg2video',
  'cfhd',
};
const _mp4Audio = {'aac', 'mp3', 'ac3', 'eac3', 'opus', 'flac', 'alac'};
const _movAudio = {'aac', 'mp3', 'ac3', 'alac'};

class RemuxPreset implements Preset {
  const RemuxPreset();

  @override
  String get id => 'remux.container';

  static const format = 'format';

  @override
  List<PresetOption> get options => const [
    PresetOption(
      id: format,
      choices: ['mp4', 'mkv', 'mov'],
      defaultChoice: 'mp4',
    ),
  ];

  @override
  ConversionPlan plan(
    MediaInfo input,
    OptionValues values,
    Capabilities capabilities,
  ) {
    final video = input.video;
    if (video == null) {
      return const ConversionPlan.unsupported([PlanNote.noVideoStream]);
    }
    final target = choice(values, format);
    final holdsVideo = switch (target) {
      'mp4' => _mp4Video.contains(video.codec),
      'mov' => _movVideo.contains(video.codec),
      _ => true,
    };
    if (!holdsVideo) {
      return const ConversionPlan.unsupported([PlanNote.containerCannotHold]);
    }
    if (_isAlready(target, input)) return const ConversionPlan.skip();

    final holdsAudio = input.audio.every(
      (a) => switch (target) {
        'mp4' => _mp4Audio.contains(a.codec),
        'mov' => _movAudio.contains(a.codec) || a.isPcm,
        _ => true,
      },
    );
    // Lossless sound stays lossless where the container allows it.
    final lossless = input.audio.every((a) => a.isPcm || a.codec == 'flac');
    final AudioAction audio = holdsAudio
        ? const AudioCopy()
        : target == 'mov' && lossless
        ? pcmAudio
        : highQualityAac(input);

    return ConversionPlan(
      kind: holdsAudio ? PlanKind.remux : PlanKind.audioOnly,
      audio: audio,
      muxer: target == 'mkv' ? 'matroska' : target,
      extension: target,
      outputArgs: [
        if (target == 'mp4') ...['-movflags', '+faststart'],
      ],
      notes: [if (!holdsAudio) PlanNote.audioConvertedToFit],
      estimatedBytes: holdsAudio ? input.sizeBytes : null,
    );
  }

  /// MP4 and MOV share one FFmpeg reader, so the file name decides.
  bool _isAlready(String target, MediaInfo input) {
    final name = input.path.toLowerCase();
    return switch (target) {
      'mkv' => input.isMatroska && name.endsWith('.mkv'),
      'mov' => input.isMovFamily && name.endsWith('.mov'),
      _ =>
        input.isMovFamily && (name.endsWith('.mp4') || name.endsWith('.m4v')),
    };
  }
}
