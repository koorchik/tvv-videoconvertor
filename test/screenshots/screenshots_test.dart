@Tags(['screenshots'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_media.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// Renders the main screen in its typical states to `build/screenshots/`, for
/// looking at the design without starting the app:
///
///   flutter test --tags screenshots
void main() {
  setUpAll(loadRealFonts);

  FakeEnvironment environment() {
    final env = FakeEnvironment(capabilities: withGpu({'av1_nvenc'}));
    env.ffprobe.add('/videos/DSC_0412.MOV');
    env.ffprobe.add(
      '/videos/DSC_0413.MOV',
      like: clip(duration: const Duration(minutes: 4, seconds: 12)),
    );
    env.ffprobe.add(
      '/videos/Z5_0007.MOV',
      like: clip(video: 'hevc', audio: [track('pcm_s24le')]),
    );
    env.ffprobe.add(
      '/videos/birthday final export.mov',
      like: clip(
        width: 1920,
        height: 1080,
        duration: const Duration(minutes: 12, seconds: 40),
      ),
    );
    return env;
  }

  const files = [
    '/videos/DSC_0412.MOV',
    '/videos/DSC_0413.MOV',
    '/videos/Z5_0007.MOV',
    '/videos/birthday final export.mov',
  ];

  testWidgets('empty', (tester) async {
    await pumpApp(tester, environment());
    await saveScreenshot(tester, '1_empty');
  });

  testWidgets('files added', (tester) async {
    final queue = await pumpApp(tester, environment());
    await addVideos(tester, queue, files);
    await saveScreenshot(tester, '2_files_added');
  });

  testWidgets('resolve goal', (tester) async {
    final queue = await pumpApp(tester, environment());
    await addVideos(tester, queue, files);
    await tester.tap(find.byIcon(Icons.movie_edit));
    await tester.pump();
    await saveScreenshot(tester, '3_resolve_goal');
  });

  testWidgets('converting', (tester) async {
    final env = environment();
    final queue = await pumpApp(tester, env);
    await addVideos(tester, queue, files);
    await tester.tap(find.text('Start'));
    await tester.pump();
    env.executor.last.finish(bytes: 140000000);
    await tester.pump();
    await tester.pump();
    env.executor.last.report(0.37);
    await tester.pump();
    await tester.pump();
    await saveScreenshot(tester, '4_converting');
  });

  testWidgets('finished', (tester) async {
    final env = environment();
    final queue = await pumpApp(tester, env);
    await addVideos(tester, queue, files);
    await tester.tap(find.text('Start'));
    await tester.pump();
    for (final bytes in [140000000, 190000000, 120000000, 160000000]) {
      env.executor.last.finish(bytes: bytes);
      await tester.pump();
      await tester.pump();
    }
    await saveScreenshot(tester, '5_finished');
  });

  testWidgets('dark, Ukrainian', (tester) async {
    final queue = await pumpApp(
      tester,
      environment(),
      locale: const Locale('uk'),
      themeMode: ThemeMode.dark,
    );
    await addVideos(tester, queue, files);
    await saveScreenshot(tester, '6_dark_ukrainian');
  });

  testWidgets('narrow window', (tester) async {
    final queue = await pumpApp(
      tester,
      environment(),
      size: const Size(620, 900),
    );
    await addVideos(tester, queue, files.take(2));
    await saveScreenshot(tester, '7_narrow');
  });

  testWidgets('command, explained', (tester) async {
    final queue = await pumpApp(tester, environment());
    await addVideos(tester, queue, ['/videos/birthday final export.mov']);
    await tester.tap(find.byTooltip('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show the command'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explained'));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, '8_command');
  });

  testWidgets('own goal for one video', (tester) async {
    final queue = await pumpApp(tester, environment());
    await addVideos(tester, queue, files);
    await tester.tap(find.text('DSC_0413.MOV'));
    await tester.pump();
    await tester.tap(find.text('Send to a phone'));
    await tester.pump();
    await saveScreenshot(tester, '9_own_goal');
  });
}
