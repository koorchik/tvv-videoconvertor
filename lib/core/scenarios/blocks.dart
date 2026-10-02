/// Building blocks shared by presets: frame rates, audio targets and size
/// estimates.
///
/// Colour tags need no block. FFmpeg 8 carries primaries, transfer, matrix and
/// range from the decoded frames to the encoder by itself, and ignores the
/// `-color_primaries` family of output options for encodes. The conversion
/// tests check that tags survive, so a build that behaves differently fails
/// them.
library;

import '../media/media_info.dart';
import 'scenario.dart';

const _standardFrameRates = {
  '24000/1001': 24000 / 1001,
  '24': 24.0,
  '25': 25.0,
  '30000/1001': 30000 / 1001,
  '30': 30.0,
  '50': 50.0,
  '60000/1001': 60000 / 1001,
  '60': 60.0,
  '120': 120.0,
};

/// The standard frame rate closest to [fps], in FFmpeg's `-r` notation.
String nearestStandardFrameRate(double fps) {
  var best = _standardFrameRates.entries.first;
  for (final entry in _standardFrameRates.entries) {
    if ((entry.value - fps).abs() < (best.value - fps).abs()) best = entry;
  }
  return best.key;
}

/// Arguments that turn irregular frame timing into a constant rate.
///
/// A phone that records "30 fps" with dropped frames averages a little under
/// 30, so the declared rate is the better target. Some recorders declare a
/// timebase-like rate far above the real one; then the average is used.
List<String> constantFrameRateArgs(VideoStream video) {
  final average = video.averageFrameRate ?? 30;
  final nominal = video.nominalFrameRate;
  final target = nominal != null && nominal <= average * 1.5
      ? nominal
      : average;
  return ['-fps_mode', 'cfr', '-r', nearestStandardFrameRate(target)];
}

/// Lossless 24-bit PCM: the audio every Resolve edition on Linux decodes.
const pcmAudio = AudioEncode(codec: 'pcm_s24le');

/// Lossless audio for containers that cannot hold PCM.
const flacAudio = AudioEncode(codec: 'flac');

int pcmBytes(MediaInfo info, {int bitsPerSample = 24}) {
  final seconds = info.duration.inMicroseconds / 1e6;
  var bitsPerSecond = 0;
  for (final track in info.audio) {
    bitsPerSecond += track.sampleRate * track.channels * bitsPerSample;
  }
  return (bitsPerSecond * seconds / 8).round();
}

/// Bytes the audio tracks occupy in the source, from their bitrates.
int sourceAudioBytes(MediaInfo info) {
  final seconds = info.duration.inMicroseconds / 1e6;
  var bitsPerSecond = 0;
  for (final track in info.audio) {
    bitsPerSecond += track.bitRate ?? 0;
  }
  return (bitsPerSecond * seconds / 8).round();
}

/// Bytes the video stream occupies in the source.
int sourceVideoBytes(MediaInfo info) {
  final video = info.video;
  if (video == null) return 0;
  final bitRate = video.bitRate;
  if (bitRate != null) {
    return (bitRate * info.duration.inMicroseconds / 1e6 / 8).round();
  }
  final rest = info.sizeBytes - sourceAudioBytes(info);
  return rest > 0 ? rest : info.sizeBytes;
}

/// Size of an intermediate codec whose bitrate is fixed by resolution and
/// frame rate. [megabitsAtUhd30] is the published rate at 3840x2160, 30 fps.
int fixedRateVideoBytes(MediaInfo info, double megabitsAtUhd30) {
  final video = info.video;
  if (video == null) return 0;
  const uhdPixelsPerSecond = 3840 * 2160 * 30;
  final scale = video.pixels * (video.frameRate ?? 30) / uhdPixelsPerSecond;
  final seconds = info.duration.inMicroseconds / 1e6;
  return (megabitsAtUhd30 * 1e6 * scale * seconds / 8).round();
}
