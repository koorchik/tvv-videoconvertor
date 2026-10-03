import '../../core/estimate/progress_estimator.dart';
import '../../core/estimate/size_estimator.dart';
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
    this.estimate,
    this.estimating = false,
    this.estimateFailed = false,
    this.goal,
    this.customGoal = false,
  });

  final int id;
  final String path;
  final ItemStatus status;
  final MediaInfo? info;

  /// What the current goal means for this file. Fixed once the file starts.
  final ConversionPlan? plan;
  final JobProgress? progress;
  final ConversionResult? result;

  /// Expected size (and time) of the output for the current plan.
  final OutputEstimate? estimate;

  /// Samples are being encoded to measure [estimate].
  final bool estimating;

  /// Measuring did not work for this file; it is not tried again until the
  /// plan changes.
  final bool estimateFailed;

  /// What this file is to be converted to.
  final TaskSelection? goal;

  /// The goal was chosen for this file alone. Changing the shared goal then
  /// leaves it alone.
  final bool customGoal;

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
    OutputEstimate? estimate,
    bool clearEstimate = false,
    bool? estimating,
    bool? estimateFailed,
    TaskSelection? goal,
    bool? customGoal,
    int? id,
  }) => QueueItem(
    id: id ?? this.id,
    path: path,
    status: status ?? this.status,
    info: info ?? this.info,
    plan: plan ?? this.plan,
    progress: clearProgress ? null : progress ?? this.progress,
    result: clearProgress ? null : result ?? this.result,
    estimate: clearEstimate ? null : estimate ?? this.estimate,
    estimating: estimating ?? this.estimating,
    estimateFailed: estimateFailed ?? this.estimateFailed,
    goal: goal ?? this.goal,
    customGoal: customGoal ?? this.customGoal,
  );
}

/// The goal the user picked: a preset and the options chosen for it.
class TaskSelection {
  const TaskSelection({required this.presetId, this.values = const {}});

  final String presetId;
  final OptionValues values;

  @override
  bool operator ==(Object other) =>
      other is TaskSelection &&
      other.presetId == presetId &&
      other.values.length == values.length &&
      values.entries.every((e) => other.values[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    presetId,
    Object.hashAllUnordered(
      values.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
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
    this.selectedIds = const {},
  });

  final List<QueueItem> items;
  final TaskSelection selection;
  final OutputSettings output;

  /// The queue is being worked through.
  final bool isRunning;
  final SampleOutcome? sample;

  /// Videos the user clicked. While any are selected, the goal panel changes
  /// only them.
  final Set<int> selectedIds;

  /// The goal the panel shows and edits: the first selected video's, or the
  /// shared one.
  TaskSelection get editedGoal {
    for (final item in items) {
      if (selectedIds.contains(item.id)) return item.goal ?? selection;
    }
    return selection;
  }

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
    Set<int>? selectedIds,
  }) => QueueState(
    items: items ?? this.items,
    selection: selection ?? this.selection,
    output: output ?? this.output,
    isRunning: isRunning ?? this.isRunning,
    sample: clearSample ? null : sample ?? this.sample,
    selectedIds: selectedIds ?? this.selectedIds,
  );
}
