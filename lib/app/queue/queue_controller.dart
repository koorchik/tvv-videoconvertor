import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/estimate/size_estimator.dart';
import '../../core/ffmpeg/command_builder.dart';
import '../../core/media/media_info.dart';
import '../../core/output/output_namer.dart';
import '../../core/queue/job_executor.dart';
import '../../core/scenarios/registry.dart';
import '../../core/scenarios/scenario.dart';
import '../estimates/estimate_cache.dart';
import '../providers.dart';
import '../recipe/recipe.dart';
import '../recipe/recipe_controller.dart';
import '../sources/sources_controller.dart';
import 'queue_state.dart';

final queueProvider = NotifierProvider<QueueController, QueueState>(
  QueueController.new,
);

/// The conversions to do, in order. Adding a job starts the queue if it is
/// not already running; the list stays editable throughout.
class QueueController extends Notifier<QueueState> {
  late AppEnvironment _env;
  var _nextId = 0;
  ConversionHandle? _activeHandle;

  @override
  QueueState build() {
    _env = ref.watch(environmentProvider).requireValue;
    return const QueueState();
  }

  // ---- Adding -----------------------------------------------------------

  /// Queues the selected videos with the panel's current settings.
  void addSelected() => _add(ref.read(sourcesProvider).selectedReady);

  /// Queues every video in the list with the panel's current settings.
  void addAll() => _add(ref.read(sourcesProvider).ready);

  /// How many of [videos] Add would actually queue: a video that already has
  /// an identical job waiting or under way is not queued twice.
  int addable(List<SourceVideo> videos) {
    final settings = ref.read(recipeProvider);
    return videos
        .where((v) => !_alreadyQueued(v.id, settings.recipe, settings.output))
        .length;
  }

  void _add(List<SourceVideo> videos) {
    final settings = ref.read(recipeProvider);
    final reserved = _reservedOutputs();
    final added = <QueueJob>[];
    for (final video in videos) {
      if (_alreadyQueued(video.id, settings.recipe, settings.output)) continue;
      final job = _makeJob(
        sourceId: video.id,
        info: video.info!,
        recipe: settings.recipe,
        output: settings.output,
        reserved: reserved,
      );
      reserved.add(job.outputPath);
      added.add(job);
    }
    if (added.isEmpty) return;
    state = state.copyWith(jobs: [...state.jobs, ...added]);
    _ensureRunning();
  }

  bool _alreadyQueued(int sourceId, Recipe recipe, OutputSettings output) =>
      state.jobs.any(
        (job) =>
            job.isPending &&
            job.sourceId == sourceId &&
            job.recipe == recipe &&
            sameOutput(job.output, output),
      );

  QueueJob _makeJob({
    required int sourceId,
    required MediaInfo info,
    required Recipe recipe,
    required OutputSettings output,
    required Set<String> reserved,
    int? id,
  }) {
    final plan = findPreset(recipe.presetId)!
        .plan(info, recipe.values, _env.capabilities);
    return QueueJob(
      id: id ?? _nextId++,
      sourceId: sourceId,
      info: info,
      recipe: recipe,
      plan: plan,
      output: output,
      sample: sampleRangeFor(recipe.sample, info.duration),
      outputPath: plan.producesOutput
          ? _outputPath(info, plan, recipe, output, reserved)
          : '',
    );
  }

  /// `<folder>/<name><settings tag>.<ext>`; samples go to a `Samples`
  /// folder inside the output folder and are marked as samples.
  String _outputPath(
    MediaInfo info,
    ConversionPlan plan,
    Recipe recipe,
    OutputSettings output,
    Set<String> reserved,
  ) {
    var settings = output;
    var suffix = plan.nameSuffix;
    if (recipe.isSample) {
      final customDir = output.customDir;
      final base = output.mode == OutputMode.customFolder && customDir != null
          ? customDir
          : p.join(p.dirname(info.path), output.subfolderName);
      settings = OutputSettings(
        mode: OutputMode.customFolder,
        customDir: p.join(base, 'Samples'),
      );
      suffix += sampleSuffix(recipe.sample);
    }
    return planOutputPath(
      sourcePath: info.path,
      settings: settings,
      suffix: suffix,
      extension: plan.extension,
      exists: (path) => File(path).existsSync(),
      reserved: reserved,
    );
  }

  /// Output names promised to jobs that will still write them, or wrote them.
  Set<String> _reservedOutputs() => {
    for (final job in state.jobs)
      if (job.outputPath.isNotEmpty && !job.canRetry) job.outputPath,
  };

  // ---- Running ----------------------------------------------------------

  void _ensureRunning() {
    if (state.busy || state.paused || state.waiting.isEmpty) return;
    unawaited(_run());
  }

  Future<void> _run() async {
    state = state.copyWith(busy: true);
    // Measuring sizes competes with converting for the processor.
    ref.read(estimateCacheProvider.notifier).stopMeasuring();
    await _env.sleepInhibitor.acquire();
    try {
      while (ref.mounted && !state.paused) {
        final waiting = state.waiting;
        if (waiting.isEmpty) break;
        await _convert(waiting.first);
      }
    } finally {
      await _env.sleepInhibitor.release();
      if (ref.mounted) state = state.copyWith(busy: false);
    }
  }

  Future<void> _convert(QueueJob job) async {
    if (!job.plan.producesOutput) {
      _update(job.id, (j) => j.copyWith(status: JobStatus.skipped));
      return;
    }
    // Something may have appeared under that name since the job was added.
    var outputPath = job.outputPath;
    if (File(outputPath).existsSync()) {
      outputPath = _outputPath(
        job.info,
        job.plan,
        job.recipe,
        job.output,
        _reservedOutputs()..remove(job.outputPath),
      );
    }
    _update(
      job.id,
      (j) => j.copyWith(status: JobStatus.running, outputPath: outputPath),
    );

    final ConversionResult result;
    try {
      final handle = await _env.executor.start(
        ConversionJob(
          input: job.info,
          plan: job.plan,
          outputPath: outputPath,
          sample: job.sample,
        ),
      );
      _activeHandle = handle;
      final updates = handle.progress.listen(
        (progress) => _update(job.id, (j) => j.copyWith(progress: progress)),
      );
      result = await handle.result;
      unawaited(updates.cancel());
    } on Object catch (error) {
      // The conversion could not even be started (FFmpeg vanished, the
      // output folder is not writable).
      _update(
        job.id,
        (j) => j.copyWith(
          status: JobStatus.failed,
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
      job.id,
      (j) => j.copyWith(
        status: switch (result.status) {
          ConversionStatus.done => JobStatus.done,
          ConversionStatus.failed => JobStatus.failed,
          ConversionStatus.cancelled => JobStatus.cancelled,
        },
        result: result,
      ),
    );
    final estimate = wholeVideoEstimate(job, result);
    if (estimate != null && ref.mounted) {
      ref
          .read(estimateCacheProvider.notifier)
          .learn(estimateKey(job.path, job.recipe), estimate);
    }
  }

  // ---- Controls ---------------------------------------------------------

  /// Pauses the queue: the job under way is suspended (where the system
  /// allows; otherwise it finishes) and nothing new starts. Calling again
  /// continues.
  void togglePause() {
    final active = state.activeJob;
    if (state.paused) {
      state = state.copyWith(paused: false);
      if (active != null && (_activeHandle?.resume() ?? false)) {
        _update(active.id, (j) => j.copyWith(status: JobStatus.running));
      }
      _ensureRunning();
    } else {
      state = state.copyWith(paused: true);
      if (active != null && (_activeHandle?.pause() ?? false)) {
        _update(active.id, (j) => j.copyWith(status: JobStatus.paused));
      }
    }
  }

  /// Cancels the job under way; the queue moves on to the next one.
  Future<void> cancelActive() async {
    if (state.activeJob?.status == JobStatus.paused) _activeHandle?.resume();
    await _activeHandle?.cancel();
  }

  /// Takes a job off the list, cancelling it first if it is under way.
  Future<void> remove(int jobId) async {
    final job = _find(jobId);
    if (job == null) return;
    if (job.isActive) await cancelActive();
    state = state.copyWith(
      jobs: [
        for (final j in state.jobs)
          if (j.id != jobId) j,
      ],
    );
  }

  /// Moves the job at [oldIndex] so that it ends up at [newIndex].
  void reorder(int oldIndex, int newIndex) {
    final jobs = [...state.jobs];
    jobs.insert(newIndex, jobs.removeAt(oldIndex));
    state = state.copyWith(jobs: jobs);
  }

  void retry(int jobId) {
    _update(jobId, (j) {
      if (!j.canRetry) return j;
      return j.copyWith(status: JobStatus.waiting, clearProgress: true);
    });
    _ensureRunning();
  }

  void clearFinished() {
    state = state.copyWith(
      jobs: [
        for (final j in state.jobs)
          if (!j.isFinished) j,
      ],
    );
  }

  /// After a sample: queues the whole video with the same settings.
  void convertWhole(int jobId) {
    final job = _find(jobId);
    if (job == null || !job.isSample) return;
    final recipe = job.recipe.withoutSample();
    if (_alreadyQueued(job.sourceId, recipe, job.output)) return;
    state = state.copyWith(
      jobs: [
        ...state.jobs,
        _makeJob(
          sourceId: job.sourceId,
          info: job.info,
          recipe: recipe,
          output: job.output,
          reserved: _reservedOutputs(),
        ),
      ],
    );
    _ensureRunning();
  }

  /// Puts a job's settings back into the panel and selects its video, to
  /// adjust them and queue again.
  void useSettings(int jobId) {
    final job = _find(jobId);
    if (job == null) return;
    ref.read(recipeProvider.notifier).load(job.recipe);
    ref.read(sourcesProvider.notifier).select(job.sourceId);
  }

  // ---- Showing ----------------------------------------------------------

  /// The FFmpeg arguments for [job] as shown to people.
  List<String>? commandFor(QueueJob job) {
    if (!job.plan.producesOutput) return null;
    return buildFfmpegArgs(
      input: job.path,
      output: job.outputPath,
      plan: job.plan,
      sample: job.sample,
      forDisplay: true,
    );
  }

  /// The arguments [video] would get with the panel's current settings.
  List<String>? commandForVideo(SourceVideo video) {
    final info = video.info;
    if (info == null) return null;
    final settings = ref.read(recipeProvider);
    return commandFor(
      _makeJob(
        id: -1,
        sourceId: video.id,
        info: info,
        recipe: settings.recipe,
        output: settings.output,
        reserved: _reservedOutputs(),
      ),
    );
  }

  QueueJob? _find(int id) {
    for (final job in state.jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  void _update(int id, QueueJob Function(QueueJob) change) {
    if (!ref.mounted) return;
    state = state.copyWith(
      jobs: [for (final job in state.jobs) job.id == id ? change(job) : job],
    );
  }
}

/// What a finished sample says about the whole video: its size and the time
/// it took, scaled up by how much of the video the sample covered.
OutputEstimate? wholeVideoEstimate(QueueJob job, ConversionResult result) {
  final sample = job.sample;
  final bytes = result.outputBytes;
  if (sample == null ||
      bytes == null ||
      result.status != ConversionStatus.done ||
      sample.length <= Duration.zero) {
    return null;
  }
  final scale = job.info.duration.inMicroseconds / sample.length.inMicroseconds;
  return OutputEstimate(
    bytes: (bytes * scale).round(),
    time: result.elapsed * scale,
    measured: true,
  );
}
