import '../../core/estimate/progress_estimator.dart';
import '../../core/media/media_info.dart';
import '../../core/output/output_namer.dart';
import '../../core/queue/job_executor.dart';
import '../../core/scenarios/scenario.dart';

enum ItemStatus {
  /// Being inspected; nothing is known about the file yet.
  probing,

  /// Inspected and planned, waiting for its turn (or for Start).
  waiting,
  running,
  paused,
  done,

  /// The file already meets the goal, so nothing was written.
  skipped,
  failed,
  cancelled,

  /// Not a video, or damaged beyond reading.
  unreadable,
}

/// One file in the list.
class QueueItem {
  const QueueItem({
    required this.id,
    required this.path,
    this.status = ItemStatus.probing,
    this.info,
    this.plan,
    this.progress,
    this.result,
  });

  final int id;
  final String path;
  final ItemStatus status;
  final MediaInfo? info;

  /// What the current goal means for this file. Fixed once the file starts.
  final ConversionPlan? plan;
  final JobProgress? progress;
  final ConversionResult? result;

  bool get isActive =>
      status == ItemStatus.running || status == ItemStatus.paused;

  /// Finished one way or another; "Clear finished" removes these.
  bool get isFinished =>
      status == ItemStatus.done ||
      status == ItemStatus.skipped ||
      status == ItemStatus.unreadable;

  bool get canRetry =>
      status == ItemStatus.failed || status == ItemStatus.cancelled;

  QueueItem copyWith({
    ItemStatus? status,
    MediaInfo? info,
    ConversionPlan? plan,
    JobProgress? progress,
    ConversionResult? result,
    bool clearProgress = false,
  }) => QueueItem(
    id: id,
    path: path,
    status: status ?? this.status,
    info: info ?? this.info,
    plan: plan ?? this.plan,
    progress: clearProgress ? null : progress ?? this.progress,
    result: clearProgress ? null : result ?? this.result,
  );
}

/// The goal the user picked: a preset and the options chosen for it.
class TaskSelection {
  const TaskSelection({required this.presetId, this.values = const {}});

  final String presetId;
  final OptionValues values;
}

/// The outcome of a "try a short sample" run.
class SampleOutcome {
  const SampleOutcome({
    required this.itemId,
    this.result,
    this.sampleLength = Duration.zero,
    this.estimatedFullBytes,
    this.estimatedFullTime,
  });

  final int itemId;

  /// Null while the sample is still being made.
  final ConversionResult? result;
  final Duration sampleLength;

  /// What the whole video would come to, scaled up from the sample.
  final int? estimatedFullBytes;
  final Duration? estimatedFullTime;

  bool get isRunning => result == null;
}

class QueueState {
  const QueueState({
    this.items = const [],
    required this.selection,
    this.output = const OutputSettings(),
    this.isRunning = false,
    this.sample,
  });

  final List<QueueItem> items;
  final TaskSelection selection;
  final OutputSettings output;

  /// The queue is being worked through.
  final bool isRunning;
  final SampleOutcome? sample;

  QueueItem? get activeItem {
    for (final item in items) {
      if (item.isActive) return item;
    }
    return null;
  }

  /// Files that Start would actually convert.
  Iterable<QueueItem> get pending => items.where(
    (i) => i.status == ItemStatus.waiting && (i.plan?.producesOutput ?? false),
  );

  bool get hasFinished => items.any((i) => i.isFinished);

  QueueState copyWith({
    List<QueueItem>? items,
    TaskSelection? selection,
    OutputSettings? output,
    bool? isRunning,
    SampleOutcome? sample,
    bool clearSample = false,
  }) => QueueState(
    items: items ?? this.items,
    selection: selection ?? this.selection,
    output: output ?? this.output,
    isRunning: isRunning ?? this.isRunning,
    sample: clearSample ? null : sample ?? this.sample,
  );
}
