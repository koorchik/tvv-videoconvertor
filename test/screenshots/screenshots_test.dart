@Tags(['screenshots'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvv_videoconvertor/app/window.dart';
import 'package:tvv_videoconvertor/core/media/ffprobe.dart';

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
    final report = jsonDecode(
      File('test/fixtures/hlg_clip_ffprobe.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    env.ffprobe.add(
      '/videos/birthday final export.mov',
      like: parseFfprobeJson('/videos/birthday final export.mov', report),
    );
    return env;
  }

  const files = [
    '/videos/DSC_0412.MOV',
    '/videos/DSC_0413.MOV',
    '/videos/Z5_0007.MOV',
    '/videos/birthday final export.mov',
  ];

  Future<void> addToQueue(WidgetTester tester) async {
    await tester.tap(find.text('Add to queue'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('empty', (tester) async {
    await pumpApp(tester, environment());
    await saveScreenshot(tester, '1_empty');
  });

  testWidgets('videos added', (tester) async {
    final sources = await pumpApp(tester, environment());
    await addVideos(tester, sources, files);
    await tester.pump();
    await saveScreenshot(tester, '2_videos_added');
  });

  testWidgets('queue with a finished sample', (tester) async {
    final env = environment();
    final sources = await pumpApp(tester, env);
    await addVideos(tester, sources, files);
    await tester.tap(find.text('DSC_0412.MOV'));
    await tester.pump();
    await tester.tap(find.text('first 10 s'));
    await tester.pump();
    await addToQueue(tester);
    env.executor.last.finish(
      bytes: 2600000,
      elapsed: const Duration(seconds: 6),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.text('Whole video'));
    await tester.pump();
    await tester.tap(find.text('DSC_0413.MOV'));
    await tester.pump();
    await addToQueue(tester);
    env.executor.last.report(0.42);
    await tester.pump();
    await tester.tap(find.text('Z5_0007.MOV'));
    await tester.pump();
    await addToQueue(tester);
    await saveScreenshot(tester, '3_queue');
  });

  testWidgets('details', (tester) async {
    final sources = await pumpApp(tester, environment());
    await addVideos(tester, sources, files);
    await tester.tap(find.byTooltip('More').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Video details'));
    await tester.pumpAndSettle();
    await saveScreenshot(tester, '4_details');
  });

  testWidgets('dark, Ukrainian', (tester) async {
    final env = environment();
    final sources = await pumpApp(
      tester,
      env,
      locale: const Locale('uk'),
      themeMode: ThemeMode.dark,
    );
    await addVideos(tester, sources, files);
    await tester.tap(find.text('Додати в чергу'));
    await tester.pump();
    await tester.pump();
    env.executor.last.report(0.6);
    await tester.pump();
    await saveScreenshot(tester, '5_dark_ukrainian');
  });

  testWidgets('smallest window, the tallest settings', (tester) async {
    final env = environment();
    final sources = await pumpApp(tester, env, size: minimumWindowSize);
    await addVideos(tester, sources, files.take(2));
    await tester.tap(find.byIcon(Icons.movie_edit));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await saveScreenshot(tester, '6_smallest_window');
  });
}
