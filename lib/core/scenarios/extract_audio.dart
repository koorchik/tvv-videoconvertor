/// Saves the sound of a video as a file of its own.
///
/// By default the sound track is copied out untouched, into the file type
/// that matches it, so nothing is lost. The other formats convert it.
library;

import '../ffmpeg/capabilities.dart';
import '../media/media_info.dart';
import 'blocks.dart';
import 'scenario.dart';

const extractAudioScenario = Scenario(
  id: 'audio',
  presets: [ExtractAudioPreset()],
);

class ExtractAudioPreset implements Preset {
  const ExtractAudioPreset();

  @override
  String get id => 'audio.extract';

  static const format = 'format';

  @override
  List<PresetOption> get options => const [
    PresetOption(
      id: format,
      choices: ['original', 'mp3', 'm4a', 'wav', 'flac'],
      defaultChoice: 'original',
    ),
  ];

  @override
  ConversionPlan plan(
    MediaInfo input,
    OptionValues values,
    Capabilities capabilities,
  ) {
    if (input.audio.isEmpty) {
      return const ConversionPlan.unsupported([PlanNote.noAudioStream]);
    }
    final track = input.audio.first;
    final target = _target(choice(values, format), track);
    final copies = target.audio is AudioCopy;

    return ConversionPlan(
      // A copy takes seconds and loses nothing; a conversion is real work.
      kind: copies ? PlanKind.remux : PlanKind.encode,
      video: const VideoNone(),
      audio: target.audio,
      muxer: target.muxer,
      extension: target.extension,
      // Audio-only file types hold one track.
      firstAudioOnly: true,
      estimatedBytes: copies && track.bitRate != null
          ? (track.bitRate! * input.duration.inMicroseconds / 8e6).round()
          : null,
    );
  }

  _Target _target(String format, AudioStream track) => switch (format) {
    'mp3' => _copyIf(
      track.codec == 'mp3',
      const AudioEncode(codec: 'libmp3lame', args: ['-q:a', '2']),
      'mp3',
      'mp3',
    ),
    'm4a' => _copyIf(
      track.codec == 'aac',
      const AudioEncode(codec: 'aac', args: ['-b:a', '192k']),
      'ipod',
      'm4a',
    ),
    'flac' => _copyIf(track.codec == 'flac', flacAudio, 'flac', 'flac'),
    'wav' => _Target(_wav(track), 'wav', 'wav'),
    _ => _original(track),
  };

  _Target _copyIf(
    bool alreadyThat,
    AudioAction convert,
    String muxer,
    String extension,
  ) => _Target(alreadyThat ? const AudioCopy() : convert, muxer, extension);

  /// The file type that holds [track] as it is.
  _Target _original(AudioStream track) => switch (track.codec) {
    'aac' || 'alac' => const _Target(AudioCopy(), 'ipod', 'm4a'),
    'mp3' => const _Target(AudioCopy(), 'mp3', 'mp3'),
    'opus' => const _Target(AudioCopy(), 'opus', 'opus'),
    'vorbis' => const _Target(AudioCopy(), 'ogg', 'ogg'),
    'flac' => const _Target(AudioCopy(), 'flac', 'flac'),
    'ac3' => const _Target(AudioCopy(), 'ac3', 'ac3'),
    'eac3' => const _Target(AudioCopy(), 'eac3', 'eac3'),
    _ when track.isPcm => _Target(_wav(track), 'wav', 'wav'),
    // Anything unusual goes into a container that accepts every format.
    _ => const _Target(AudioCopy(), 'matroska', 'mka'),
  };

  /// WAV holds little-endian PCM. Camera MOV files often carry big-endian
  /// PCM, which is rewritten in the other byte order: still lossless.
  AudioAction _wav(AudioStream track) {
    const wavReady = {'pcm_s16le', 'pcm_s24le', 'pcm_s32le', 'pcm_f32le'};
    if (wavReady.contains(track.codec)) return const AudioCopy();
    final deep =
        track.codec.contains('24') ||
        track.codec.contains('32') ||
        track.codec == 'flac';
    return AudioEncode(codec: deep ? 'pcm_s24le' : 'pcm_s16le');
  }
}

class _Target {
  const _Target(this.audio, this.muxer, this.extension);

  final AudioAction audio;
  final String muxer;
  final String extension;
}
