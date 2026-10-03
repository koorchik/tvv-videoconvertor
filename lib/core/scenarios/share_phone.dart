/// Makes a small video that plays on any phone and in messengers such as
/// Telegram: H.264, 8-bit, at most 1080p, with the index at the front.
///
/// This is the one goal that favours compatibility over everything else, so
/// it uses the oldest widely supported format rather than the most efficient.
library;

import '../ffmpeg/capabilities.dart';
import '../media/media_info.dart';
import 'blocks.dart';
import 'scenario.dart';

const sharePhoneScenario = Scenario(id: 'share', presets: [SharePhonePreset()]);

class SharePhonePreset implements Preset {
  const SharePhonePreset();

  @override
  String get id => 'share.phone';

  static const size = 'size';

  @override
  List<PresetOption> get options => const [
    PresetOption(
      id: size,
      choices: ['small', 'standard'],
      defaultChoice: 'standard',
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
    final small = choice(values, size) == 'small';
    final longSide = small ? 1280 : 1920;
    // A ceiling on the bitrate keeps busy scenes from producing a file too
    // large to send; quiet scenes stay well below it.
    final (maxRate, buffer) = small ? ('4M', '8M') : ('8M', '16M');

    final canToneMap =
        capabilities.hasFilter('zscale') && capabilities.hasFilter('tonemap');
    final sourceLongSide = video.width > video.height
        ? video.width
        : video.height;

    return ConversionPlan(
      kind: PlanKind.encode,
      video: VideoEncode(
        encoder: 'libx264',
        pixFmt: 'yuv420p',
        args: [
          '-preset',
          'slow',
          '-crf',
          '23',
          '-profile:v',
          'high',
          '-maxrate',
          maxRate,
          '-bufsize',
          buffer,
        ],
        filters: [
          if (video.color.isHdr && canToneMap) ..._toneMapToSdr,
          if (sourceLongSide > longSide)
            // Fits inside a square of the long side, so landscape and
            // portrait videos are both limited correctly. Never enlarges.
            'scale=$longSide:$longSide:force_original_aspect_ratio=decrease:'
                'force_divisible_by=2:flags=lanczos',
        ],
      ),
      audio: _audio(input),
      muxer: 'mp4',
      extension: 'mp4',
      nameSuffix: small ? '_phone-720p' : '_phone-1080p',
      outputArgs: [
        if (video.isVariableFrameRate) ...constantFrameRateArgs(video),
        '-movflags',
        '+faststart',
      ],
      notes: [
        if (video.color.isHdr)
          canToneMap ? PlanNote.hdrToneMapped : PlanNote.hdrNotConverted,
      ],
      cost: const ResourceCost(cpuThreads: 10),
    );
  }

  /// HDR shown as ordinary video looks grey and washed out, so brightness and
  /// colour are mapped into the standard range first.
  static const _toneMapToSdr = [
    'zscale=t=linear:npl=100',
    'format=gbrpf32le',
    'zscale=p=bt709',
    'tonemap=tonemap=hable:desat=0',
    'zscale=t=bt709:m=bt709:r=tv',
  ];

  AudioAction _audio(MediaInfo input) {
    if (input.audio.isEmpty) return const AudioCopy();
    final keep = input.audio.every(
      (a) => a.codec == 'aac' && a.channels <= 2 && (a.bitRate ?? 0) <= 192000,
    );
    if (keep) return const AudioCopy();
    return const AudioEncode(codec: 'aac', args: ['-b:a', '160k', '-ac', '2']);
  }
}
