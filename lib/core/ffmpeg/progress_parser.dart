/// One progress report from `ffmpeg -progress`.
class ProgressSnapshot {
  const ProgressSnapshot({
    this.outTime,
    this.totalSize,
    this.frame,
    this.isEnd = false,
  });

  /// Position in the output that has been written so far.
  final Duration? outTime;

  /// Bytes written so far. Null when FFmpeg does not know (reported `N/A`).
  final int? totalSize;
  final int? frame;

  /// The last report: FFmpeg has finished writing.
  final bool isEnd;
}

/// Parses the `key=value` lines of `ffmpeg -progress pipe:1`. Reports arrive
/// as blocks, each closed by a `progress=continue` or `progress=end` line.
///
/// FFmpeg's own `fps` and `speed` fields are averages over the whole run and
/// are ignored; the estimator derives a current rate from [ProgressSnapshot.outTime].
class ProgressParser {
  Duration? _outTime;
  int? _totalSize;
  int? _frame;

  /// Feeds one line. Returns a snapshot when the line completes a block.
  ProgressSnapshot? addLine(String line) {
    final separator = line.indexOf('=');
    if (separator < 0) return null;
    final key = line.substring(0, separator).trim();
    final value = line.substring(separator + 1).trim();
    switch (key) {
      // `out_time_ms` is also microseconds, despite its name; only one of the
      // two is read to avoid confusion.
      case 'out_time_us':
        final micros = int.tryParse(value);
        // The first report can carry a negative or garbage timestamp.
        if (micros != null && micros >= 0) {
          _outTime = Duration(microseconds: micros);
        }
      case 'total_size':
        _totalSize = int.tryParse(value) ?? _totalSize;
      case 'frame':
        _frame = int.tryParse(value) ?? _frame;
      case 'progress':
        return ProgressSnapshot(
          outTime: _outTime,
          totalSize: _totalSize,
          frame: _frame,
          isEnd: value == 'end',
        );
    }
    return null;
  }
}
