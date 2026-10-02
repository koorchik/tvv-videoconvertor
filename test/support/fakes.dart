import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:tvv_videoconvertor/app/providers.dart';
import 'package:tvv_videoconvertor/core/estimate/progress_estimator.dart';
import 'package:tvv_videoconvertor/core/ffmpeg/capabilities.dart';
import 'package:tvv_videoconvertor/core/media/ffprobe.dart';
import 'package:tvv_videoconvertor/core/media/media_info.dart';
import 'package:tvv_videoconvertor/core/platform/sleep_inhibitor.dart';
import 'package:tvv_videoconvertor/core/queue/job_executor.dart';

import 'fake_media.dart';

/// Answers probes from a table instead of running ffprobe. Paths not in the
/// table are reported as unreadable, like a file that is not a video.
class FakeFfprobe implements Ffprobe {
  final files = <String, MediaInfo>{};

  /// Registers a file. [like] supplies everything but the path.
  void add(String path, {MediaInfo? like}) {
    final info = like ?? clip();
    files[path] = MediaInfo(
      path: path,
      formatName: info.formatName,
      duration: info.duration,
      sizeBytes: info.sizeBytes,
      video: info.video,
      audio: info.audio,
    );
  }

  @override
  String get executable => 'ffprobe';

  @override
  Future<MediaInfo> probe(String path) async {
    final info = files[path];
    if (info == null) throw FfprobeException('not a video');
    return info;
  }
}

/// A conversion that finishes only when the test says so.
class FakeHandle implements ConversionHandle {
  FakeHandle(this.job);

  final ConversionJob job;
  final _progress = StreamController<JobProgress>.broadcast();
  final _result = Completer<ConversionResult>();
  bool paused = false;

  @override
  Stream<JobProgress> get progress => _progress.stream;

  @override
  Future<ConversionResult> get result => _result.future;

  void report(double fraction) => _progress.add(
    JobProgress(
      fraction: fraction,
      outTime: job.durationToConvert * fraction,
      speed: 2,
      remaining: job.durationToConvert * ((1 - fraction) / 2),
      currentBytes: 1000,
    ),
  );

  void finish({int bytes = 1000000, Duration elapsed = Duration.zero}) {
    _complete(
      ConversionResult(
        status: ConversionStatus.done,
        elapsed: elapsed,
        outputPath: job.outputPath,
        outputBytes: bytes,
      ),
    );
  }

  void fail() => _complete(
    const ConversionResult(
      status: ConversionStatus.failed,
      elapsed: Duration.zero,
      errorLines: ['Invalid data found when processing input'],
    ),
  );

  @override
  Future<void> cancel() async => _complete(
    const ConversionResult(
      status: ConversionStatus.cancelled,
      elapsed: Duration.zero,
    ),
  );

  void _complete(ConversionResult result) {
    if (_result.isCompleted) return;
    _progress.close();
    _result.complete(result);
  }

  @override
  bool pause() => paused = true;

  @override
  bool resume() {
    paused = false;
    return true;
  }
}

/// Records the conversions that were started and hands out [FakeHandle]s.
class FakeExecutor implements JobExecutor {
  final started = <FakeHandle>[];

  FakeHandle get last => started.last;

  /// Names of the source files converted so far, in order.
  List<String> get startedNames => [
    for (final handle in started) handle.job.input.path.split('/').last,
  ];

  @override
  Future<ConversionHandle> start(ConversionJob job) async {
    final handle = FakeHandle(job);
    started.add(handle);
    return handle;
  }
}

class FakeSleepInhibitor implements SleepInhibitor {
  @override
  bool isActive = false;

  @override
  Future<void> acquire() async => isActive = true;

  @override
  Future<void> release() async => isActive = false;
}

/// A complete stand-in for the machine: no FFmpeg, no real files.
class FakeEnvironment {
  FakeEnvironment({this.capabilities = softwareOnly});

  final Capabilities capabilities;
  final ffprobe = FakeFfprobe();
  final executor = FakeExecutor();
  final inhibitor = FakeSleepInhibitor();

  late final environment = AppEnvironment(
    ffprobe: ffprobe,
    executor: executor,
    capabilities: capabilities,
    sleepInhibitor: inhibitor,
  );

  /// Overrides that make the app use this environment.
  List<Override> get overrides => [
    environmentProvider.overrideWith((ref) async => environment),
  ];
}
