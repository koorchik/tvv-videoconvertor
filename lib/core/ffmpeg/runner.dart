import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'capabilities.dart';
import 'progress_parser.dart';

enum RunStatus { completed, failed, cancelled }

class RunResult {
  const RunResult({
    required this.status,
    required this.exitCode,
    required this.errorLines,
  });

  final RunStatus status;
  final int exitCode;

  /// The last lines FFmpeg wrote to stderr. With `-loglevel error` these are
  /// the reasons for a failure.
  final List<String> errorLines;
}

/// Starts FFmpeg processes.
class FfmpegRunner {
  FfmpegRunner(this.ffmpeg);

  final String ffmpeg;

  Future<FfmpegRun> start(List<String> args) async {
    final process = await Process.start(
      ffmpeg,
      args,
      environment: ffmpegEnvironment,
    );
    return FfmpegRun._(process);
  }
}

/// One running FFmpeg process: its progress, its outcome, and the controls to
/// stop or pause it.
class FfmpegRun {
  FfmpegRun._(this._process) {
    _result = _watch();
  }

  /// How long FFmpeg gets to finish the file after being asked to stop,
  /// before it is terminated.
  static const gracePeriod = Duration(seconds: 5);
  static const _keptErrorLines = 40;

  final Process _process;
  final _progress = StreamController<ProgressSnapshot>.broadcast();
  final _errorLines = <String>[];
  late final Future<RunResult> _result;
  bool _cancelRequested = false;
  bool _paused = false;
  Timer? _killTimer;

  Stream<ProgressSnapshot> get progress => _progress.stream;
  Future<RunResult> get result => _result;
  bool get isPaused => _paused;

  Future<RunResult> _watch() async {
    final parser = ProgressParser();
    final stdoutDone = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .forEach((line) {
          final snapshot = parser.addLine(line);
          if (snapshot != null) _progress.add(snapshot);
        });
    // stderr must be drained even when nothing reads it, or FFmpeg blocks
    // once the pipe fills up.
    final stderrDone = _process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .forEach((line) {
          _errorLines.add(line);
          if (_errorLines.length > _keptErrorLines) _errorLines.removeAt(0);
        });

    final exitCode = await _process.exitCode;
    await Future.wait([stdoutDone, stderrDone]);
    _killTimer?.cancel();
    await _progress.close();

    // After a graceful stop FFmpeg exits with 0, so the exit code cannot tell
    // a cancelled run from a finished one.
    final status = _cancelRequested
        ? RunStatus.cancelled
        : (exitCode == 0 ? RunStatus.completed : RunStatus.failed);
    return RunResult(
      status: status,
      exitCode: exitCode,
      errorLines: List.unmodifiable(_errorLines),
    );
  }

  /// Asks FFmpeg to stop. It is first asked politely (`q` on stdin), which
  /// lets it close the file properly; if it has not exited after
  /// [gracePeriod] it is terminated.
  Future<void> cancel() async {
    if (_cancelRequested) return;
    _cancelRequested = true;
    // A suspended process cannot read the request.
    if (_paused) resume();
    try {
      _process.stdin.write('q');
      await _process.stdin.flush();
    } on Object {
      // The process has already gone, or closed stdin: terminate below.
    }
    _killTimer = Timer(gracePeriod, () {
      _process.kill(ProcessSignal.sigterm);
      _killTimer = Timer(const Duration(seconds: 2), () {
        _process.kill(ProcessSignal.sigkill);
      });
    });
  }

  /// Suspends the process. Returns false where that is not supported.
  bool pause() {
    if (_paused || _cancelRequested) return _paused;
    if (Platform.isWindows) return false;
    _paused = Process.killPid(_process.pid, ProcessSignal.sigstop);
    return _paused;
  }

  bool resume() {
    if (!_paused) return true;
    if (Process.killPid(_process.pid, ProcessSignal.sigcont)) _paused = false;
    return !_paused;
  }
}
