/// Removes the information a video file carries about where, when, with what
/// and by whom it was made, before the file is given to someone else.
///
/// Quick: picture and sound are copied untouched into a clean container. This
/// removes every tag, the timecode and data tracks (which hold camera and GPS
/// telemetry) and chapters. Text that an encoder wrote inside the picture or
/// sound data itself survives a copy.
///
/// Thorough: picture and sound are re-encoded, so nothing of the original
/// data is carried over at all.
///
/// Neither changes what is visible or audible in the video.
library;

import '../ffmpeg/capabilities.dart';
import '../media/media_info.dart';
import 'blocks.dart';
import 'scenario.dart';

const stripMetadataScenario = Scenario(
  id: 'privacy',
  presets: [StripMetadataPreset()],
);

class StripMetadataPreset implements Preset {
  const StripMetadataPreset();

  @override
  String get id => 'privacy.clean';

  static const mode = 'mode';

  @override
  List<PresetOption> get options => const [
    PresetOption(
      id: mode,
      choices: ['quick', 'thorough'],
      defaultChoice: 'quick',
    ),
  ];

  /// Stops FFmpeg from writing its own name and version into the file.
  static const _noEncoderSignature = [
    '-fflags',
    '+bitexact',
    '-flags:v',
    '+bitexact',
    '-flags:a',
    '+bitexact',
  ];

  /// MP4 and MOV only: no timecode track, and blank track names instead of
  /// the "VideoHandler" default.
  static const _blankMovTracks = ['-write_tmcd', '0', '-empty_hdlr_name', '1'];

  @override
  ConversionPlan plan(
    MediaInfo input,
    OptionValues values,
    Capabilities capabilities,
  ) {
    final video = input.video;
    if (video == null && input.audio.isEmpty) {
      return const ConversionPlan.unsupported([PlanNote.noVideoStream]);
    }
    final thorough = choice(values, mode) == 'thorough';

    // The container type is kept where possible, so the cleaned file is the
    // same kind of file as the original.
    final (muxer, extension) = thorough
        ? ('mp4', 'mp4')
        : input.isMovFamily
        ? (input.path.toLowerCase().endsWith('.mov')
              ? ('mov', 'mov')
              : ('mp4', 'mp4'))
        : ('matroska', 'mkv');

    final VideoAction videoAction;
    if (video == null) {
      videoAction = const VideoNone();
    } else if (!thorough) {
      videoAction = const VideoCopy();
    } else if (video.bitDepth > 8) {
      videoAction = const VideoEncode(
        encoder: 'libx265',
        pixFmt: 'yuv420p10le',
        args: [
          '-preset',
          'slow',
          '-crf',
          '18',
          '-x265-params',
          'log-level=error:info=0',
          '-tag:v',
          'hvc1',
        ],
      );
    } else {
      videoAction = const VideoEncode(
        encoder: 'libx264',
        pixFmt: 'yuv420p',
        args: ['-preset', 'slow', '-crf', '17'],
      );
    }

    return ConversionPlan(
      kind: thorough ? PlanKind.encode : PlanKind.remux,
      video: videoAction,
      audio: thorough ? highQualityAac(input) : const AudioCopy(),
      muxer: muxer,
      extension: extension,
      nameSuffix: thorough ? '_clean-reencoded' : '_clean',
      keepMetadata: false,
      // The file's date says when the video was shot.
      keepFileDate: false,
      outputArgs: [
        '-map_metadata:s',
        '-1',
        '-map_chapters',
        '-1',
        ..._noEncoderSignature,
        if (muxer != 'matroska') ..._blankMovTracks,
        if (muxer == 'mp4') ...['-movflags', '+faststart'],
      ],
      cost: thorough ? const ResourceCost(cpuThreads: 14) : ResourceCost.copy,
    );
  }
}
