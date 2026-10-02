/// Shrinks a finished video to the smallest file that still looks excellent.
///
/// Output is always 10-bit 4:2:0 in MP4: 10-bit avoids banding even for 8-bit
/// sources, at a size cost of a few percent.
library;

import '../ffmpeg/capabilities.dart';
import '../media/media_info.dart';
import 'blocks.dart';
import 'scenario.dart';

/// HEVC comes first and is the default: it plays on practically every device
/// and service, which matters more to most people than AV1's smaller files.
const compressScenario = Scenario(
  id: 'compress',
  presets: [CompressPreset.hevc, CompressPreset.av1, CompressPreset.gpu],
);

enum CompressTarget { av1, hevc, gpu }

/// Hardware encoders for the "fastest" preset, best first. AV1 compresses
/// better than HEVC, so any AV1 encoder beats any HEVC one.
const gpuEncoderPreference = [
  'av1_nvenc',
  'av1_qsv',
  'av1_amf',
  'hevc_nvenc',
  'hevc_qsv',
  'hevc_amf',
  'hevc_videotoolbox',
];

class CompressPreset implements Preset {
  const CompressPreset._(this.id, this.target);

  static const av1 = CompressPreset._('compress.av1', CompressTarget.av1);
  static const hevc = CompressPreset._('compress.hevc', CompressTarget.hevc);
  static const gpu = CompressPreset._('compress.gpu', CompressTarget.gpu);

  @override
  final String id;
  final CompressTarget target;

  static const quality = 'quality';

  @override
  List<PresetOption> get options => const [
    PresetOption(
      id: quality,
      choices: ['compact', 'high', 'maximum'],
      defaultChoice: 'high',
    ),
  ];

  /// The hardware encoder the "fastest" preset would use on this machine, or
  /// null when there is none and the preset should not be offered.
  static String? gpuEncoder(Capabilities capabilities) {
    for (final encoder in gpuEncoderPreference) {
      if (capabilities.hasHardwareEncoder(encoder)) return encoder;
    }
    return null;
  }

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
    final level = choice(values, quality);
    final encode = switch (target) {
      CompressTarget.av1 => _svtAv1(video, level, capabilities),
      CompressTarget.hevc => _x265(video, level),
      CompressTarget.gpu => _gpu(video, level, capabilities),
    };
    final isHevc =
        encode.encoder.startsWith('hevc') || encode.encoder == 'libx265';
    return ConversionPlan(
      kind: PlanKind.encode,
      video: encode,
      audio: _audio(input),
      muxer: 'mp4',
      extension: 'mp4',
      nameSuffix: isHevc ? '_hevc' : '_av1',
      outputArgs: [
        if (video.isVariableFrameRate) ...constantFrameRateArgs(video),
        // Apple players only recognise HEVC under this tag.
        if (isHevc) ...['-tag:v', 'hvc1'],
        // Index at the front, so the file starts playing before it has
        // fully downloaded.
        '-movflags', '+faststart',
      ],
      notes: [
        if (video.isVariableFrameRate) PlanNote.variableFrameRateFixed,
        if (video.chroma != ChromaSubsampling.yuv420) PlanNote.chromaReduced,
      ],
      cost: _cost(encode.encoder),
    );
  }

  VideoEncode _svtAv1(
    VideoStream video,
    String level,
    Capabilities capabilities,
  ) {
    final crf = switch (level) {
      'compact' => '29',
      'maximum' => '21',
      _ => '25',
    };
    return VideoEncode(
      encoder: 'libsvtav1',
      pixFmt: 'yuv420p10le',
      filters: _chromaFilters(video, 'yuv420p10le'),
      args: [
        '-preset',
        '5',
        '-crf',
        crf,
        if (capabilities.svtAv1Params.isNotEmpty) ...[
          '-svtav1-params',
          capabilities.svtAv1Params,
        ],
      ],
    );
  }

  VideoEncode _x265(VideoStream video, String level) {
    final crf = switch (level) {
      'compact' => '23',
      'maximum' => '18',
      _ => '20',
    };
    return VideoEncode(
      encoder: 'libx265',
      pixFmt: 'yuv420p10le',
      filters: _chromaFilters(video, 'yuv420p10le'),
      args: [
        '-preset',
        'slow',
        '-crf',
        crf,
        '-profile:v',
        'main10',
        '-x265-params',
        'aq-mode=3:no-sao=1:log-level=error',
      ],
    );
  }

  VideoEncode _gpu(VideoStream video, String level, Capabilities capabilities) {
    final encoder = gpuEncoder(capabilities) ?? 'libx265';
    if (encoder == 'libx265') return _x265(video, level);

    final isAv1 = encoder.startsWith('av1');
    // Hardware quality scales differ from the software CRF scale and from
    // each other; HEVC needs a lower number than AV1 for the same result.
    final q = switch ((isAv1, level)) {
      (true, 'compact') => 32,
      (true, 'maximum') => 24,
      (true, _) => 28,
      (false, 'compact') => 27,
      (false, 'maximum') => 20,
      (false, _) => 24,
    };
    final rateControl = switch (encoder.split('_').last) {
      'nvenc' => [
        '-preset',
        'p7',
        '-tune',
        'hq',
        '-rc',
        'vbr',
        '-cq',
        '$q',
        '-b:v',
        '0',
        '-rc-lookahead',
        '32',
        '-spatial-aq',
        '1',
        '-temporal-aq',
        '1',
        '-b_ref_mode',
        'middle',
      ],
      'qsv' => [
        '-preset',
        'veryslow',
        '-global_quality',
        '$q',
        '-extbrc',
        '1',
        '-look_ahead_depth',
        '40',
      ],
      'amf' => [
        '-usage',
        'transcoding',
        '-quality',
        'high_quality',
        '-rc',
        'qvbr',
        '-qvbr_quality_level',
        '$q',
      ],
      // VideoToolbox quality runs 0-100 and, unlike the others, higher is
      // better.
      _ => [
        '-q:v',
        switch (level) {
          'compact' => '55',
          'maximum' => '75',
          _ => '65',
        },
      ],
    };
    return VideoEncode(
      encoder: encoder,
      pixFmt: 'p010le',
      filters: _chromaFilters(video, 'p010le'),
      args: [
        ...rateControl,
        if (!isAv1) ...['-profile:v', 'main10'],
      ],
    );
  }

  /// A plain `-pix_fmt` would subsample chroma with the default bilinear
  /// scaler; an explicit Lanczos step keeps colour edges cleaner.
  List<String> _chromaFilters(VideoStream video, String pixFmt) {
    if (video.chroma == ChromaSubsampling.yuv420) return const [];
    return ['scale=flags=lanczos+accurate_rnd', 'format=$pixFmt'];
  }

  /// AAC that is already reasonably small is kept as is: re-encoding lossy
  /// audio only loses quality.
  AudioAction _audio(MediaInfo input) {
    if (input.audio.isEmpty) return const AudioCopy();
    final keep = input.audio.every(
      (a) => a.codec == 'aac' && (a.bitRate ?? 0) <= 320000,
    );
    if (keep) return const AudioCopy();
    final channels = input.audio
        .map((a) => a.channels)
        .reduce((a, b) => a > b ? a : b);
    final bitRate = switch (channels) {
      1 => '128k',
      2 => '256k',
      _ => '448k',
    };
    return AudioEncode(codec: 'aac', args: ['-b:a', bitRate]);
  }

  ResourceCost _cost(String encoder) => switch (encoder) {
    'libsvtav1' => const ResourceCost(cpuThreads: 12),
    'libx265' => const ResourceCost(cpuThreads: 16),
    _ => const ResourceCost(cpuThreads: 3, usesGpuEncoder: true),
  };
}
