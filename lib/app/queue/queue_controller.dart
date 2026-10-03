import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/estimate/size_estimator.dart';
import '../../core/ffmpeg/command_builder.dart';
import '../../core/media/ffprobe.dart';
import '../../core/media/video_files.dart';
import '../../core/output/output_namer.dart';
import '../../core/queue/job_executor.dart';
import '../../core/scenarios/compress.dart';
import '../../core/scenarios/registry.dart';
import '../../core/scenarios/scenario.dart';
import '../providers.dart';
import '../settings.dart';
import 'queue_state.dart';

final queueControllerProvider = NotifierProvider<QueueController, QueueState>(
  QueueController.new,
);

/// The list of files and what happens to them.
///
/// The list stays editable while conversions run: files can be added, waiting
/// ones removed or reordered, the running one cancelled on its own, and the
/// goal changed for everything that has not started yet.
class QueueController extends Notifier<QueueState> {
  late AppEnvironment _env;
  int _nextId = 0;
  ConversionHandle? _activeHandle;
  bool _stopRequested = false;
  final _probes = <Future<void>>{};

  /// Estimates already measured, by file and goal, so switching goals back
  /// and forth does not measure the same thing twice.
  final _estimateCache = <String, OutputEstimate>{};
  var _estimatesInFlight = 0;

  /// Raised to discard estimates that were under way when they were stopped.
  var _estimateGeneration = 0;

  /// How many files are inspected at once when a folder is added.
  static const _probeConcurrency = 4;
  static const sampleLength = Duration(seconds: 10);

  @override
  QueueState build() {
    _env = ref.watch(environmentProvider).requireValue;
    ref.onDispose(_env.estimator.cancelAll);
    final store = ref.read(settingsStoreProvider);
    return QueueState(
      selection:
          _restoreGoal(store.read(_goalKey)) ??
          TaskSelection(presetId: compressScenario.presets.first.id),
      output: _restoreOutput(store.read(_outputKey)),
    );
  }

  static const _goalKey = 'goal';
  static const _outputKey = 'output';

  /// The goal used last time, if it still exists and works on this computer.
  TaskSelection? _restoreGoal(Object? saved) {
    if (saved is! Map) return null;
    final preset = findPreset('${saved['preset']}');
    if (preset == null) return null;
    if (preset.id == CompressPreset.gpu.id &&
        CompressPreset.gpuEncoder(_env.capabilities) == null) {
      return null;
    }
    final values = saved['values'];
    return TaskSelection(
      presetId: preset.id,
      values: values is Map
          ? {for (final e in values.entries) '${e.key}': '${e.value}'}
          : const {},
    );
  }

  OutputSettings _restoreOutput(Object? saved) {
    if (saved is Map && saved['folder'] is String) {
      return OutputSettings(
        mode: OutputMode.customFolder,
        customDir: saved['folder'] as String,
      );
    }
    return const OutputSettings();
  }

  // ---- Editing the list -------------------------------------------------

  /// Adds files, and the videos inside any folders, to the end of the list,
  /// with the shared goal. The same file may be added more than once, to
  /// convert it in more than one way.
  Future<void> addPaths(Iterable<String> paths) async {
    final files = await expandDroppedPaths(paths);
    final added = [
      for (final path in files)
        QueueItem(id: _nextId++, path: path, goal: state.selection),
    ];
    if (added.isEmpty) return;
    state = state.copyWith(items: [...state.items, ...added]);

    final queue = [...added];
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        await _probe(queue.removeAt(0));
      }
    }

    final probing = Future.wait([
      for (var i = 0; i < _probeConcurrency; i++) worker(),
    ]);
    _probes.add(probing);
    await probing;
    _probes.remove(probing);
  }

  Future<void> _probe(QueueItem item) async {
    try {
      final info = await _env.ffprobe.probe(item.path);
      _update(
        item.id,
        (i) => _withPlan(
          i.copyWith(status: ItemStatus.waiting, info: info),
          i.goal ?? state.selection,
        ),
      );
      _scheduleEstimates();
    } on FfprobeException {
      _update(item.id, (i) => i.copyWith(status: ItemStatus.unreadable));
    }
  }

  /// Takes a file off the list. A file that is being converted is cancelled
  /// first; its unfinished output is discarded.
  Future<void> remove(int id) async {
    final item = _find(id);
    if (item == null) return;
    if (item.isActive) await _activeHandle?.cancel();
    state = state.copyWith(
      items: state.items.where((i) => i.id != id).toList(),
      selectedIds: {...state.selectedIds}..remove(id),
    );
  }

  /// Puts a second entry for the same file right below it and selects it,
  /// so a different goal can be chosen for it straight away.
  void duplicate(int id) {
    final index = state.items.indexWhere((i) => i.id == id);
    if (index < 0) return;
    final original = state.items[index];
    final info = original.info;
    final copy = QueueItem(
      id: _nextId++,
      path: original.path,
      status: info == null ? ItemStatus.probing : ItemStatus.waiting,
      info: info,
      goal: original.goal ?? state.selection,
    );
    final planned = info == null ? copy : _withPlan(copy, copy.goal!);
    state = state.copyWith(
      items: [...state.items]..insert(index + 1, planned),
      selectedIds: {planned.id},
    );
    if (info == null) unawaited(_probe(planned));
    _scheduleEstimates();
  }

  // ---- Selecting videos -------------------------------------------------

  /// Selects a video so the goal panel applies to it alone. With [additive]
  /// (Ctrl or Cmd held) it is added to or removed from the selection.
  /// Clicking the only selected video deselects it.
  void toggleSelected(int id, {bool additive = false}) {
    final item = _find(id);
    if (item == null || !_canChangeGoal(item)) return;
    final selected = {...state.selectedIds};
    if (additive) {
      if (!selected.remove(id)) selected.add(id);
    } else if (selected.length == 1 && selected.contains(id)) {
      selected.clear();
    } else {
      selected
        ..clear()
        ..add(id);
    }
    state = state.copyWith(selectedIds: selected);
  }

  void clearSelection() => state = state.copyWith(selectedIds: const {});

  /// A video's goal can change until it starts converting.
  bool _canChangeGoal(QueueItem item) =>
      item.status == ItemStatus.waiting ||
      item.status == ItemStatus.probing ||
      item.canRetry;

  void clearFinished() {
    state = state.copyWith(
      items: state.items.where((i) => !i.isFinished).toList(),
    );
  }

  /// Moves the file at [oldIndex] so that it ends up at [newIndex].
  void reorder(int oldIndex, int newIndex) {
    final items = [...state.items];
    items.insert(newIndex, items.removeAt(oldIndex));
    state = state.copyWith(items: items);
  }

  void retry(int id) {
    _update(id, (i) {
      if (!i.canRetry || i.info == null) return i;
      return _withPlan(
        i.copyWith(status: ItemStatus.waiting, clearProgress: true),
        i.goal ?? state.selection,
      );
    });
    _scheduleEstimates();
  }

  // ---- Choosing the goal ------------------------------------------------

  void selectPreset(String presetId) {
    if (findPreset(presetId) == null) return;
    _applyGoal(TaskSelection(presetId: presetId));
  }

  void setOption(String optionId, String value) {
    final goal = state.editedGoal;
    _applyGoal(
      TaskSelection(
        presetId: goal.presetId,
        values: {...goal.values, optionId: value},
      ),
    );
  }

  /// With videos selected, [goal] applies to them alone. Otherwise it becomes
  /// the shared goal: for files added from now on, and for every waiting file
  /// that has not been given a goal of its own. Files already converting or
  /// finished keep the goal they were converted with.
  void _applyGoal(TaskSelection goal) {
    _cancelEstimates();
    final selected = state.selectedIds;
    final shared = selected.isEmpty ? goal : state.selection;
    bool affected(QueueItem item) =>
        selected.isEmpty ? !item.customGoal : selected.contains(item.id);
    if (selected.isEmpty) {
      unawaited(
        ref.read(settingsStoreProvider).write(_goalKey, {
          'preset': goal.presetId,
          'values': goal.values,
        }),
      );
    }
    state = state.copyWith(
      selection: shared,
      items: [
        for (final item in state.items)
          if (!affected(item) || !_canChangeGoal(item))
            item
          else if (item.info == null || item.status != ItemStatus.waiting)
            item.copyWith(goal: goal, customGoal: goal != shared)
          else
            _withPlan(item, goal).copyWith(customGoal: goal != shared),
      ],
    );
    _scheduleEstimates();
  }

  void setOutput(OutputSettings output) {
    state = state.copyWith(output: output);
    unawaited(
      ref
          .read(settingsStoreProvider)
          .write(
            _outputKey,
            output.mode == OutputMode.customFolder
                ? {'folder': output.customDir}
                : null,
          ),
    );
  }

  // ---- Running ----------------------------------------------------------

  /// Works through the waiting files in list order until none are left,
  /// including files added while it runs.
  Future<void> start() async {
    if (state.isRunning) return;
    _stopRequested = false;
    // Measuring competes with converting for the processor; the file being
    // converted reports its own expected size as it goes.
    _cancelEstimates();
    state = state.copyWith(isRunning: true, clearSample: true);
    await _env.sleepInhibitor.acquire();
    final reserved = <String>{};
    try {
      while (!_stopRequested) {
        final next = _nextWaiting();
        if (next != null) {
          await _convert(next, reserved);
        } else if (_probes.isNotEmpty) {
          // Files are still being inspected; they may need converting too.
          await Future.wait(_probes.toList());
        } else {
          break;
        }
      }
    } finally {
      await _env.sleepInhibitor.release();
      state = state.copyWith(isRunning: false);
      _scheduleEstimates();
    }
  }

  QueueItem? _nextWaiting() {
    for (final item in state.items) {
      if (item.status == ItemStatus.waiting && item.plan != null) return item;
    }
    return null;
  }

  Future<void> _convert(QueueItem item, Set<String> reserved) async {
    final plan = item.plan!;
    if (!plan.producesOutput) {
      _update(item.id, (i) => i.copyWith(status: ItemStatus.skipped));
      return;
    }
    final outputPath = planOutputPath(
      sourcePath: item.path,
      settings: state.output,
      suffix: plan.nameSuffix,
      extension: plan.extension,
      exists: (path) => File(path).existsSync(),
      reserved: reserved,
    );
    reserved.add(outputPath);

    _update(item.id, (i) => i.copyWith(status: ItemStatus.running));
    if (state.selectedIds.contains(item.id)) {
      state = state.copyWith(
        selectedIds: {...state.selectedIds}..remove(item.id),
      );
    }
    final ConversionResult result;
    try {
      final handle = await _env.executor.start(
        ConversionJob(input: item.info!, plan: plan, outputPath: outputPath),
      );
      _activeHandle = handle;
      final updates = handle.progress.listen(
        (progress) => _update(item.id, (i) => i.copyWith(progress: progress)),
      );
      result = await handle.result;
      unawaited(updates.cancel());
    } on Object catch (error) {
      // The conversion could not even be started (FFmpeg vanished, the
      // output folder is not writable).
      _update(
        item.id,
        (i) => i.copyWith(
          status: ItemStatus.failed,
          result: ConversionResult(
            status: ConversionStatus.failed,
            elapsed: Duration.zero,
            errorLines: ['$error'],
          ),
        ),
      );
      return;
    } finally {
      _activeHandle = null;
    }
    _update(
      item.id,
      (i) => i.copyWith(
        status: switch (result.status) {
          ConversionStatus.done => ItemStatus.done,
          ConversionStatus.failed => ItemStatus.failed,
          ConversionStatus.cancelled => ItemStatus.cancelled,
        },
        result: result,
      ),
    );
  }

  /// Cancels the file being converted. The rest of the list carries on.
  Future<void> cancelActive() async => _activeHandle?.cancel();

  /// Stops after cancelling the file being converted. Waiting files stay in
  /// the list, ready for another Start.
  Future<void> stopAll() async {
    _stopRequested = true;
    await _activeHandle?.cancel();
  }

  void togglePause() {
    final item = state.activeItem;
    final handle = _activeHandle;
    if (item == null || handle == null) return;
    if (item.status == ItemStatus.paused) {
      if (handle.resume()) {
        _update(item.id, (i) => i.copyWith(status: ItemStatus.running));
      }
    } else if (handle.pause()) {
      _update(item.id, (i) => i.copyWith(status: ItemStatus.paused));
    }
  }

  // ---- Trying a sample --------------------------------------------------

  /// Converts a short piece of one file with the real settings, so the result
  /// can be looked at before committing to the whole list. The sample goes
  /// to the system's temporary folder, not next to the originals.
  Future<void> runSample(int id, {bool fromMiddle = false}) async {
    final item = _find(id);
    final info = item?.info;
    final plan = item?.plan;
    if (info == null || plan == null || !plan.producesOutput) return;
    if (state.isRunning || (state.sample?.isRunning ?? false)) return;

    final length = info.duration < sampleLength ? info.duration : sampleLength;
    final start = fromMiddle ? (info.duration - length) * 0.5 : Duration.zero;
    state = state.copyWith(sample: SampleOutcome(itemId: id));

    final dir = p.join(Directory.systemTemp.path, 'tvv_videoconvertor_samples');
    final outputPath = planOutputPath(
      sourcePath: info.path,
      settings: OutputSettings(mode: OutputMode.customFolder, customDir: dir),
      suffix: '${plan.nameSuffix}_sample',
      extension: plan.extension,
      exists: (path) => File(path).existsSync(),
    );
    final handle = await _env.executor.start(
      ConversionJob(
        input: info,
        plan: plan,
        outputPath: outputPath,
        sample: SampleRange(start: start, length: length),
      ),
    );
    _activeHandle = handle;
    final result = await handle.result;
    _activeHandle = null;

    final scale = length > Duration.zero
        ? info.duration.inMicroseconds / length.inMicroseconds
        : 1.0;
    state = state.copyWith(
      sample: SampleOutcome(
        itemId: id,
        result: result,
        sampleLength: length,
        estimatedFullBytes: result.outputBytes == null
            ? null
            : (result.outputBytes! * scale).round(),
        estimatedFullTime: result.elapsed * scale,
      ),
    );
    // Ten seconds measure better than the automatic three-second pieces.
    if (result.outputBytes != null) {
      _update(
        id,
        (i) => identical(i.plan, plan)
            ? i.copyWith(
                estimate: OutputEstimate(
                  bytes: (result.outputBytes! * scale).round(),
                  time: result.elapsed * scale,
                  measured: true,
                ),
              )
            : i,
      );
    }
  }

  void dismissSample() => state = state.copyWith(clearSample: true);

  /// The FFmpeg arguments for [item] as shown to people: the conversion the
  /// app runs, without the options it adds for its own use. Null when there
  /// is nothing to run for the file.
  List<String>? commandFor(QueueItem item) {
    final info = item.info;
    final plan = item.plan;
    if (info == null || plan == null || !plan.producesOutput) return null;
    return buildFfmpegArgs(
      input: info.path,
      output:
          item.result?.outputPath ??
          planOutputPath(
            sourcePath: info.path,
            settings: state.output,
            suffix: plan.nameSuffix,
            extension: plan.extension,
            exists: (path) => File(path).existsSync(),
          ),
      plan: plan,
      forDisplay: true,
    );
  }

  // ---- Estimating sizes -------------------------------------------------

  /// [item] planned for [selection], with whatever is already known about
  /// its output size.
  QueueItem _withPlan(QueueItem item, TaskSelection selection) {
    final info = item.info!;
    final plan = findPreset(selection.presetId)!
        .plan(info, selection.values, _env.capabilities);
    final known =
        estimateWithoutEncoding(info, plan) ??
        _estimateCache[_estimateKey(item.path, selection)];
    return item.copyWith(
      goal: selection,
      plan: plan,
      estimate: known,
      clearEstimate: known == null,
      estimating: false,
      estimateFailed: false,
    );
  }

  String _estimateKey(String path, TaskSelection selection) {
    final values = selection.values.entries.map((e) => '${e.key}=${e.value}');
    return '$path|${selection.presetId}|${(values.toList()..sort()).join(',')}';
  }

  bool _needsEstimate(QueueItem item) =>
      item.status == ItemStatus.waiting &&
      item.info != null &&
      (item.plan?.producesOutput ?? false) &&
      item.plan!.video is VideoEncode &&
      item.estimate == null &&
      !item.estimating &&
      !item.estimateFailed;

  /// Starts measuring files that need it, in list order, as many at once as
  /// the processor has room for.
  void _scheduleEstimates() {
    if (state.isRunning) return;
    while (true) {
      QueueItem? next;
      for (final item in state.items) {
        if (_needsEstimate(item)) {
          next = item;
          break;
        }
      }
      if (next == null) return;
      final room = (Platform.numberOfProcessors / next.plan!.cost.cpuThreads)
          .floor()
          .clamp(1, 3);
      if (_estimatesInFlight >= room) return;
      unawaited(_estimate(next));
    }
  }

  Future<void> _estimate(QueueItem item) async {
    final plan = item.plan!;
    final key = _estimateKey(item.path, item.goal ?? state.selection);
    final generation = _estimateGeneration;
    _estimatesInFlight++;
    _update(item.id, (i) => i.copyWith(estimating: true));
    OutputEstimate? estimate;
    try {
      estimate = await _env.estimator.estimate(item.info!, plan);
    } on Object {
      estimate = null;
    }
    _estimatesInFlight--;
    final stopped = generation != _estimateGeneration;
    if (estimate != null) _estimateCache[key] = estimate;
    _update(item.id, (i) {
      if (!identical(i.plan, plan)) return i.copyWith(estimating: false);
      return i.copyWith(
        estimating: false,
        estimate: estimate,
        // A stopped measurement is retried later; a failed one is not.
        estimateFailed: estimate == null && !stopped,
      );
    });
    if (!stopped) _scheduleEstimates();
  }

  void _cancelEstimates() {
    if (_estimatesInFlight == 0) return;
    _estimateGeneration++;
    unawaited(_env.estimator.cancelAll());
  }

  // ---- Helpers ----------------------------------------------------------

  QueueItem? _find(int id) {
    for (final item in state.items) {
      if (item.id == id) return item;
    }
    return null;
  }

  void _update(int id, QueueItem Function(QueueItem) change) {
    state = state.copyWith(
      items: [
        for (final item in state.items) item.id == id ? change(item) : item,
      ],
    );
  }
}
