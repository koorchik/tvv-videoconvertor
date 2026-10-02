import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/ffmpeg/command_builder.dart';
import '../../core/media/ffprobe.dart';
import '../../core/media/video_files.dart';
import '../../core/output/output_namer.dart';
import '../../core/queue/job_executor.dart';
import '../../core/scenarios/compress.dart';
import '../../core/scenarios/registry.dart';
import '../../core/scenarios/scenario.dart';
import '../providers.dart';
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

  /// How many files are inspected at once when a folder is added.
  static const _probeConcurrency = 4;
  static const sampleLength = Duration(seconds: 10);

  @override
  QueueState build() {
    _env = ref.watch(environmentProvider).requireValue;
    return QueueState(
      selection: TaskSelection(presetId: compressScenario.presets.first.id),
    );
  }

  Preset get _preset => findPreset(state.selection.presetId)!;

  // ---- Editing the list -------------------------------------------------

  /// Adds files, and the videos inside any folders, to the end of the list.
  /// Files already in the list are not added twice.
  Future<void> addPaths(Iterable<String> paths) async {
    final files = await expandDroppedPaths(paths);
    final known = state.items.map((i) => i.path).toSet();
    final added = [
      for (final path in files)
        if (known.add(path)) QueueItem(id: _nextId++, path: path),
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
        (i) => i.copyWith(
          status: ItemStatus.waiting,
          info: info,
          plan: _preset.plan(info, state.selection.values, _env.capabilities),
        ),
      );
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
    );
  }

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
      return i.copyWith(
        status: ItemStatus.waiting,
        plan: _preset.plan(i.info!, state.selection.values, _env.capabilities),
        clearProgress: true,
      );
    });
  }

  // ---- Choosing the goal ------------------------------------------------

  void selectPreset(String presetId) {
    if (findPreset(presetId) == null) return;
    _applySelection(TaskSelection(presetId: presetId));
  }

  void setOption(String optionId, String value) {
    _applySelection(
      TaskSelection(
        presetId: state.selection.presetId,
        values: {...state.selection.values, optionId: value},
      ),
    );
  }

  /// Re-plans every file that has not started. Files already running or
  /// finished keep the plan they were converted with.
  void _applySelection(TaskSelection selection) {
    final preset = findPreset(selection.presetId)!;
    state = state.copyWith(
      selection: selection,
      items: [
        for (final item in state.items)
          if (item.status == ItemStatus.waiting && item.info != null)
            item.copyWith(
              plan: preset.plan(
                item.info!,
                selection.values,
                _env.capabilities,
              ),
            )
          else
            item,
      ],
    );
  }

  void setOutput(OutputSettings output) {
    state = state.copyWith(output: output);
  }

  // ---- Running ----------------------------------------------------------

  /// Works through the waiting files in list order until none are left,
  /// including files added while it runs.
  Future<void> start() async {
    if (state.isRunning) return;
    _stopRequested = false;
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
