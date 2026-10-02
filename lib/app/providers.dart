import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ffmpeg/capabilities.dart';
import '../core/ffmpeg/locator.dart';
import '../core/ffmpeg/runner.dart';
import '../core/media/ffprobe.dart';
import '../core/platform/sleep_inhibitor.dart';
import '../core/queue/job_executor.dart';

/// Everything the app needs from the machine it runs on, found once at
/// startup. Tests replace this with fakes.
class AppEnvironment {
  const AppEnvironment({
    required this.ffprobe,
    required this.executor,
    required this.capabilities,
    required this.sleepInhibitor,
  });

  final Ffprobe ffprobe;
  final JobExecutor executor;
  final Capabilities capabilities;
  final SleepInhibitor sleepInhibitor;
}

/// Thrown at startup when no usable FFmpeg can be found.
class FfmpegMissing implements Exception {
  const FfmpegMissing();
}

final environmentProvider = FutureProvider<AppEnvironment>(
  (ref) async {
    final paths = FfmpegLocator().locate();
    if (paths == null) throw const FfmpegMissing();
    return AppEnvironment(
      ffprobe: Ffprobe(paths.ffprobe),
      executor: JobExecutor(FfmpegRunner(paths.ffmpeg)),
      capabilities: await CapabilityProbe(paths.ffmpeg).detect(),
      sleepInhibitor: SleepInhibitor.forPlatform(),
    );
  },
  // A missing FFmpeg does not appear by waiting; show the message at once.
  retry: (_, _) => null,
);
