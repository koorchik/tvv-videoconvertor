import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tvv_videoconvertor/app/providers.dart';
import 'package:tvv_videoconvertor/app/queue/queue_controller.dart';
import 'package:tvv_videoconvertor/app/queue/queue_state.dart';
import 'package:tvv_videoconvertor/app/settings.dart';
import 'package:tvv_videoconvertor/core/settings/settings_store.dart';
import 'package:tvv_videoconvertor/core/output/output_namer.dart';
import 'package:tvv_videoconvertor/core/scenarios/scenario.dart';

import '../support/fake_media.dart';
import '../support/fakes.dart';

void main() {
  late FakeEnvironment env;
  late ProviderContainer container;
  late QueueController queue;

  QueueState state() => container.read(queueControllerProvider);
  QueueItem item(String name) =>
      state().items.firstWhere((i) => i.path.endsWith(name));
  List<ItemStatus> statuses() => [for (final i in state().items) i.status];

  /// Lets queued-up asynchronous work run.
  Future<void> settle() => pumpEventQueue();

  setUp(() async {
    env = FakeEnvironment();
    container = ProviderContainer(overrides: env.overrides);
    addTearDown(container.dispose);
    await container.read(environmentProvider.future);
    queue = container.read(queueControllerProvider.notifier);
    for (final name in ['a.mp4', 'b.mp4', 'c.mp4']) {
      env.ffprobe.add('/videos/$name');
    }
  });

  group('adding files', () {
    test('the first goal offered is "make it small, works everywhere"', () {
      expect(state().selection.presetId, 'compress.hevc');
    });

    test('a video is inspected and planned for the current goal', () async {
      await queue.addPaths(['/videos/a.mp4']);

      expect(item('a.mp4').status, ItemStatus.waiting);
      expect(item('a.mp4').plan!.kind, PlanKind.encode);
    });

    test('something that is not a video is marked, not dropped', () async {
      await queue.addPaths(['/videos/notes.txt']);

      expect(item('notes.txt').status, ItemStatus.unreadable);
    });

    test(
      'the same file can be added again, to convert it another way',
      () async {
        await queue.addPaths(['/videos/a.mp4']);
        await queue.addPaths(['/videos/a.mp4']);

        expect(state().items.map((i) => i.path), [
          '/videos/a.mp4',
          '/videos/a.mp4',
        ]);
      },
    );
  });

  group('choosing the goal', () {
    test('waiting files are re-planned for the new goal', () async {
      await queue.addPaths(['/videos/a.mp4']);

      queue.selectPreset('resolve.studio');

      expect(item('a.mp4').plan!.kind, PlanKind.audioOnly);
    });

    test('an option change re-plans too', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.selectPreset('resolve.studio');

      queue.setOption('convertVideo', 'yes');

      expect(item('a.mp4').plan!.kind, PlanKind.encode);
    });

    test('a file already being converted keeps its plan', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);
      queue.start();
      await settle();

      queue.selectPreset('resolve.studio');

      expect(item('a.mp4').plan!.kind, PlanKind.encode);
      expect(item('b.mp4').plan!.kind, PlanKind.audioOnly);
    });
  });

  group('converting', () {
    test('files are converted one after another, in list order', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);
      final run = queue.start();
      await settle();

      expect(statuses(), [ItemStatus.running, ItemStatus.waiting]);
      env.executor.last.finish();
      await settle();
      expect(statuses(), [ItemStatus.done, ItemStatus.running]);
      env.executor.last.finish();
      await run;

      expect(statuses(), [ItemStatus.done, ItemStatus.done]);
      expect(env.executor.startedNames, ['a.mp4', 'b.mp4']);
      expect(state().isRunning, isFalse);
    });

    test('progress reaches the list as it is reported', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.start();
      await settle();

      env.executor.last.report(0.4);
      await settle();

      expect(item('a.mp4').progress!.fraction, 0.4);
    });

    test('the computer is kept awake only while converting', () async {
      await queue.addPaths(['/videos/a.mp4']);
      final run = queue.start();
      await settle();
      expect(env.inhibitor.isActive, isTrue);

      env.executor.last.finish();
      await run;

      expect(env.inhibitor.isActive, isFalse);
    });

    test('a file that is ready as is is not converted', () async {
      env.ffprobe.add(
        '/videos/nikon.mov',
        like: clip(video: 'hevc', audio: [track('pcm_s24le')]),
      );
      await queue.addPaths(['/videos/nikon.mov']);
      queue.selectPreset('resolve.studio');

      await queue.start();

      expect(item('nikon.mov').status, ItemStatus.skipped);
      expect(env.executor.started, isEmpty);
    });

    test('outputs go to a "Converted" folder next to each original', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.start();
      await settle();

      expect(
        env.executor.last.job.outputPath,
        p.join('/videos', 'Converted', 'a_hevc.mp4'),
      );
    });

    test('a chosen folder is used instead', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.setOutput(
        const OutputSettings(
          mode: OutputMode.customFolder,
          customDir: '/exports',
        ),
      );
      queue.start();
      await settle();

      expect(
        env.executor.last.job.outputPath,
        p.join('/exports', 'a_hevc.mp4'),
      );
    });

    test('sources with the same name do not collide', () async {
      env.ffprobe.add('/videos/a.mov');
      await queue.addPaths(['/videos/a.mp4', '/videos/a.mov']);
      queue.start();
      await settle();
      env.executor.last.finish();
      await settle();

      expect(
        env.executor.last.job.outputPath,
        p.join('/videos', 'Converted', 'a_hevc (2).mp4'),
      );
    });

    test('a failure is recorded and the next file still converts', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);
      final run = queue.start();
      await settle();

      env.executor.last.fail();
      await settle();
      env.executor.last.finish();
      await run;

      expect(statuses(), [ItemStatus.failed, ItemStatus.done]);
      expect(item('a.mp4').result!.errorLines, isNotEmpty);
    });
  });

  group('changing the list while converting', () {
    test('a file added during the run is converted too', () async {
      await queue.addPaths(['/videos/a.mp4']);
      final run = queue.start();
      await settle();

      await queue.addPaths(['/videos/b.mp4']);
      env.executor.last.finish();
      await settle();
      env.executor.last.finish();
      await run;

      expect(env.executor.startedNames, ['a.mp4', 'b.mp4']);
    });

    test('a waiting file that is removed is never converted', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4', '/videos/c.mp4']);
      final run = queue.start();
      await settle();

      await queue.remove(item('b.mp4').id);
      env.executor.last.finish();
      await settle();
      env.executor.last.finish();
      await run;

      expect(env.executor.startedNames, ['a.mp4', 'c.mp4']);
    });

    test('waiting files can be put in a different order', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4', '/videos/c.mp4']);
      final run = queue.start();
      await settle();

      queue.reorder(2, 1);
      for (var i = 0; i < 3; i++) {
        env.executor.last.finish();
        await settle();
      }
      await run;

      expect(env.executor.startedNames, ['a.mp4', 'c.mp4', 'b.mp4']);
    });

    test('cancelling the current file moves on to the next', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);
      final run = queue.start();
      await settle();

      await queue.cancelActive();
      await settle();
      expect(statuses(), [ItemStatus.cancelled, ItemStatus.running]);
      env.executor.last.finish();
      await run;

      expect(statuses(), [ItemStatus.cancelled, ItemStatus.done]);
    });

    test('removing the file being converted cancels it', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);
      final run = queue.start();
      await settle();

      await queue.remove(item('a.mp4').id);
      await settle();
      env.executor.last.finish();
      await run;

      expect(state().items.map((i) => i.path), ['/videos/b.mp4']);
      expect(statuses(), [ItemStatus.done]);
    });

    test('Stop ends the run and leaves the rest waiting', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);
      final run = queue.start();
      await settle();

      await queue.stopAll();
      await run;

      expect(statuses(), [ItemStatus.cancelled, ItemStatus.waiting]);
      expect(state().isRunning, isFalse);
      expect(env.inhibitor.isActive, isFalse);
    });

    test('pausing and continuing is reflected on the file', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.start();
      await settle();

      queue.togglePause();
      expect(item('a.mp4').status, ItemStatus.paused);
      expect(env.executor.last.paused, isTrue);

      queue.togglePause();
      expect(item('a.mp4').status, ItemStatus.running);
    });
  });

  group('afterwards', () {
    test('a cancelled file can be tried again', () async {
      await queue.addPaths(['/videos/a.mp4']);
      final run = queue.start();
      await settle();
      await queue.cancelActive();
      await run;

      queue.retry(item('a.mp4').id);

      expect(item('a.mp4').status, ItemStatus.waiting);
      expect(item('a.mp4').progress, isNull);
    });

    test('"clear finished" keeps what still needs attention', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4', '/videos/x.txt']);
      final run = queue.start();
      await settle();
      env.executor.last.finish();
      await settle();
      env.executor.last.fail();
      await run;

      queue.clearFinished();

      expect(state().items.map((i) => i.path), ['/videos/b.mp4']);
    });
  });

  group('sample', () {
    test(
      'converts ten seconds and scales the result to the whole video',
      () async {
        // The default clip is one minute long: six times the sample.
        await queue.addPaths(['/videos/a.mp4']);
        final sample = queue.runSample(item('a.mp4').id);
        await settle();
        final job = env.executor.last.job;

        expect(job.sample!.length, const Duration(seconds: 10));
        expect(job.sample!.start, Duration.zero);
        expect(state().sample!.isRunning, isTrue);

        env.executor.last.finish(
          bytes: 5000000,
          elapsed: const Duration(seconds: 4),
        );
        await sample;

        expect(state().sample!.estimatedFullBytes, 30000000);
        expect(state().sample!.estimatedFullTime, const Duration(seconds: 24));
        expect(item('a.mp4').status, ItemStatus.waiting);
      },
    );

    test('can be taken from the middle of the video', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.runSample(item('a.mp4').id, fromMiddle: true);
      await settle();

      expect(env.executor.last.job.sample!.start, const Duration(seconds: 25));
    });

    test('is not written next to the originals', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.runSample(item('a.mp4').id);
      await settle();

      expect(env.executor.last.job.outputPath, isNot(startsWith('/videos')));
      expect(env.executor.last.job.outputPath, endsWith('a_hevc_sample.mp4'));
    });
  });

  group('expected size', () {
    test('a re-encode is measured in the background', () async {
      await queue.addPaths(['/videos/a.mp4']);
      await settle();

      expect(item('a.mp4').estimate!.bytes, 150000000);
      expect(env.estimator.measured, ['/videos/a.mp4']);
    });

    test('a quick fix is calculated, not measured', () async {
      await queue.addPaths(['/videos/a.mp4']);
      await settle();

      queue.selectPreset('resolve.studio');
      await settle();

      expect(item('a.mp4').estimate!.measured, isFalse);
      expect(env.estimator.measured, hasLength(1));
    });

    test('going back to a goal reuses its measurement', () async {
      await queue.addPaths(['/videos/a.mp4']);
      await settle();

      queue.selectPreset('resolve.studio');
      queue.selectPreset('compress.hevc');
      await settle();

      expect(item('a.mp4').estimate!.bytes, 150000000);
      expect(env.estimator.measured, hasLength(1));
    });

    test('measuring stops when converting starts', () async {
      env.estimator.hold = true;
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);
      await settle();
      expect(item('a.mp4').estimating, isTrue);

      queue.start();
      await settle();

      expect(env.estimator.cancels, 1);
      expect(state().items.where((i) => i.estimating), isEmpty);
    });

    test('a file that cannot be measured is not tried again', () async {
      env.estimator.fail = true;
      await queue.addPaths(['/videos/a.mp4']);
      await settle();

      expect(item('a.mp4').estimate, isNull);
      expect(item('a.mp4').estimateFailed, isTrue);
      expect(env.estimator.measured, hasLength(1));
    });

    test('a ten-second sample gives the file a better estimate', () async {
      await queue.addPaths(['/videos/a.mp4']);
      await settle();
      final sample = queue.runSample(item('a.mp4').id);
      await settle();

      env.executor.last.finish(bytes: 4000000);
      await sample;

      expect(item('a.mp4').estimate!.bytes, 24000000);
    });
  });

  group('a goal per video', () {
    test(
      'a selected video gets its own goal; the others keep theirs',
      () async {
        await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);

        queue.toggleSelected(item('b.mp4').id);
        queue.selectPreset('share.phone');

        expect(item('a.mp4').plan!.nameSuffix, '_hevc');
        expect(item('b.mp4').plan!.nameSuffix, '_phone');
        expect(item('b.mp4').customGoal, isTrue);
        expect(state().selection.presetId, 'compress.hevc');
      },
    );

    test('the shared goal does not override a video given its own', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);
      queue.toggleSelected(item('b.mp4').id);
      queue.selectPreset('share.phone');
      queue.clearSelection();

      queue.selectPreset('compress.av1');

      expect(item('a.mp4').plan!.nameSuffix, '_av1');
      expect(item('b.mp4').plan!.nameSuffix, '_phone');
    });

    test('the panel shows the goal of the selected video', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.toggleSelected(item('a.mp4').id);
      queue.selectPreset('compress.av1');
      queue.setOption('quality', 'maximum');

      expect(state().editedGoal.presetId, 'compress.av1');
      expect(state().editedGoal.values, {'quality': 'maximum'});
      queue.clearSelection();
      expect(state().editedGoal.presetId, 'compress.hevc');
    });

    test('clicking the selected video again deselects it', () async {
      await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);

      queue.toggleSelected(item('a.mp4').id);
      queue.toggleSelected(item('a.mp4').id);
      expect(state().selectedIds, isEmpty);

      queue.toggleSelected(item('a.mp4').id);
      queue.toggleSelected(item('b.mp4').id, additive: true);
      expect(state().selectedIds, hasLength(2));
    });

    test(
      '"add again" puts a copy below and selects it for a new goal',
      () async {
        await queue.addPaths(['/videos/a.mp4', '/videos/b.mp4']);

        queue.duplicate(item('a.mp4').id);
        queue.selectPreset('audio.extract');

        final paths = state().items.map((i) => i.path).toList();
        expect(paths, ['/videos/a.mp4', '/videos/a.mp4', '/videos/b.mp4']);
        expect(state().items[0].plan!.nameSuffix, '_hevc');
        expect(state().items[1].plan!.extension, 'm4a');
      },
    );

    test('both entries of one file are converted, each its own way', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.duplicate(item('a.mp4').id);
      queue.selectPreset('share.phone');
      final run = queue.start();
      await settle();
      env.executor.last.finish();
      await settle();
      env.executor.last.finish();
      await run;

      expect(env.executor.started.map((h) => h.job.outputPath), [
        p.join('/videos', 'Converted', 'a_hevc.mp4'),
        p.join('/videos', 'Converted', 'a_phone.mp4'),
      ]);
    });

    test('a video leaves the selection when it starts converting', () async {
      await queue.addPaths(['/videos/a.mp4']);
      queue.toggleSelected(item('a.mp4').id);

      queue.start();
      await settle();

      expect(state().selectedIds, isEmpty);
    });
  });

  group('remembered between runs', () {
    Future<QueueController> restart(MemorySettingsStore settings) async {
      final next = ProviderContainer(
        overrides: [
          ...env.overrides,
          settingsStoreProvider.overrideWithValue(settings),
        ],
      );
      addTearDown(next.dispose);
      await next.read(environmentProvider.future);
      container = next;
      return next.read(queueControllerProvider.notifier);
    }

    test('the last goal and its options are chosen again', () async {
      final settings = MemorySettingsStore();
      final first = await restart(settings);
      first.selectPreset('resolve.free');
      first.setOption('quality', 'best');

      await restart(settings);

      expect(state().selection.presetId, 'resolve.free');
      expect(state().selection.values, {'quality': 'best'});
    });

    test('a goal given to one video only is not remembered', () async {
      final settings = MemorySettingsStore();
      final first = await restart(settings);
      await first.addPaths(['/videos/a.mp4']);
      first.toggleSelected(
        container.read(queueControllerProvider).items.single.id,
      );
      first.selectPreset('share.phone');

      await restart(settings);

      expect(state().selection.presetId, 'compress.hevc');
    });

    test('the chosen output folder is used again', () async {
      final settings = MemorySettingsStore();
      final first = await restart(settings);
      first.setOutput(
        const OutputSettings(
          mode: OutputMode.customFolder,
          customDir: '/exports',
        ),
      );

      await restart(settings);

      expect(state().output.customDir, '/exports');
    });
  });
}
