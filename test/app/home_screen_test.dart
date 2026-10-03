import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tvv_videoconvertor/app/app.dart';
import 'package:tvv_videoconvertor/app/home/technical_text.dart';
import 'package:tvv_videoconvertor/app/providers.dart';
import 'package:tvv_videoconvertor/core/settings/settings_store.dart';

import '../support/fake_media.dart';
import '../support/fakes.dart';
import '../support/pump_app.dart';

/// Words a non-technical person should never have to read on the main screen.
const jargon = [
  'H.264',
  'H.265',
  'HEVC',
  'AV1',
  'AAC',
  'PCM',
  'ProRes',
  'DNxHR',
  'CRF',
  'codec',
  'bitrate',
  '10-bit',
  'FFmpeg',
  'remux',
  'MOV',
  'MP4',
];

void main() {
  late FakeEnvironment env;

  setUp(() {
    env = FakeEnvironment();
    env.ffprobe.add('/videos/holiday.mp4');
    env.ffprobe.add(
      '/videos/nikon.mov',
      like: clip(video: 'hevc', audio: [track('pcm_s24le')]),
    );
  });

  FilledButton startButton(WidgetTester tester) =>
      tester.widget(find.widgetWithText(FilledButton, 'Start'));

  testWidgets('an empty window invites dropping videos; Start is disabled', (
    tester,
  ) async {
    await pumpApp(tester, env);

    expect(find.text('Drop videos or folders here'), findsOneWidget);
    expect(find.text('Your original files are never changed.'), findsOneWidget);
    expect(startButton(tester).onPressed, isNull);
  });

  testWidgets('"Make it small" is already chosen: add videos, press Start', (
    tester,
  ) async {
    final queue = await pumpApp(tester, env);
    await addVideos(tester, queue, ['/videos/holiday.mp4']);

    expect(find.text('holiday.mp4'), findsOneWidget);
    expect(find.textContaining('4K · 1:00 · 750 MB'), findsOneWidget);
    expect(find.text('1 video to convert'), findsOneWidget);
    expect(startButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Start'));
    await tester.pump();

    expect(env.executor.started, hasLength(1));
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
  });

  testWidgets('the expected size is shown per video and for the batch', (
    tester,
  ) async {
    final queue = await pumpApp(tester, env);
    await addVideos(tester, queue, ['/videos/holiday.mp4']);
    await tester.pump();

    expect(
      find.textContaining('Will be converted  → about 150 MB'),
      findsOneWidget,
    );
    expect(
      find.text('750 MB → about 150 MB  ·  80% smaller  ·  takes about 1 min'),
      findsOneWidget,
    );
  });

  testWidgets('each file says in plain words what will happen to it', (
    tester,
  ) async {
    final queue = await pumpApp(tester, env);
    await addVideos(tester, queue, [
      '/videos/holiday.mp4',
      '/videos/nikon.mov',
    ]);

    await tester.tap(find.text('Edit in DaVinci Resolve'));
    await tester.pump();

    expect(
      find.textContaining('Quick, the picture stays untouched'),
      findsOneWidget,
    );
    expect(find.textContaining('Ready as is'), findsOneWidget);
    expect(find.textContaining('1 video to convert'), findsOneWidget);
  });

  testWidgets('progress, time left and expected size show while converting', (
    tester,
  ) async {
    final queue = await pumpApp(tester, env);
    await addVideos(tester, queue, ['/videos/holiday.mp4']);
    await tester.tap(find.text('Start'));
    await tester.pump();

    env.executor.last.report(0.5);
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.textContaining('15 s left'), findsWidgets);
    expect(find.text('Converting 1 of 1  ·  15 s left'), findsOneWidget);
  });

  testWidgets('finishing shows how much space was saved', (tester) async {
    final queue = await pumpApp(tester, env);
    await addVideos(tester, queue, ['/videos/holiday.mp4']);
    await tester.tap(find.text('Start'));
    await tester.pump();

    env.executor.last.finish(bytes: 150000000);
    await tester.pump();
    await tester.pump();

    expect(find.text('All done'), findsOneWidget);
    expect(find.text('750 MB became 150 MB, 80% smaller'), findsOneWidget);
    expect(find.textContaining('Done: 150 MB, 80% smaller'), findsOneWidget);
  });

  testWidgets('a waiting file can be removed while another converts', (
    tester,
  ) async {
    final queue = await pumpApp(tester, env);
    env.ffprobe.add('/videos/second.mp4');
    await addVideos(tester, queue, [
      '/videos/holiday.mp4',
      '/videos/second.mp4',
    ]);
    await tester.tap(find.text('Start'));
    await tester.pump();

    await tester.tap(find.byTooltip('Remove'));
    await tester.pump();

    expect(find.text('second.mp4'), findsNothing);
    expect(find.text('holiday.mp4'), findsOneWidget);
  });

  testWidgets('"Fastest" is offered only with a usable graphics card', (
    tester,
  ) async {
    await pumpApp(tester, env);
    expect(find.text('Fastest'), findsNothing);

    final withCard = FakeEnvironment(capabilities: withGpu({'av1_nvenc'}));
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, withCard);

    expect(find.text('Fastest'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('uk')]) {
    testWidgets(
      'technical terms appear only as secondary detail (${locale.languageCode})',
      (tester) async {
        final queue = await pumpApp(tester, env, locale: locale);
        await addVideos(tester, queue, [
          '/videos/holiday.mp4',
          '/videos/nikon.mov',
        ]);

        final seen = <String>[...plainTexts(tester)];
        // The second goal's texts count too.
        await tester.tap(find.byIcon(Icons.movie_edit));
        await tester.pump();
        seen.addAll(plainTexts(tester));

        // File names are the user's own and may look like anything.
        seen.removeWhere(
          (text) => text.startsWith(RegExp(r'(holiday|nikon)\.')),
        );

        for (final term in jargon) {
          // Whole words only: "Remove" is not a mention of the MOV file type.
          final word = RegExp(
            '(?<![A-Za-z0-9])${RegExp.escape(term)}(?![A-Za-z0-9])',
            caseSensitive: false,
          );
          expect(
            seen.where(word.hasMatch),
            isEmpty,
            reason: '"$term" should not appear on the main screen',
          );
        }
      },
    );
  }

  testWidgets('the screen is translated to Ukrainian', (tester) async {
    await pumpApp(tester, env, locale: const Locale('uk'));

    expect(find.text('Перетягніть сюди відео або папки'), findsOneWidget);
    expect(find.text('Зменшити розмір'), findsOneWidget);
    expect(find.text('Почати'), findsOneWidget);
  });

  testWidgets(
    'a missing video engine is explained, not shown as an error dump',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            environmentProvider.overrideWith(
              (ref) async => throw const FfmpegMissing(),
            ),
          ],
          child: const VideoConverterApp(locale: Locale('en')),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('The video engine is missing'), findsOneWidget);
    },
  );

  testWidgets('clicking a video lets it have a goal of its own', (
    tester,
  ) async {
    final queue = await pumpApp(tester, env);
    env.ffprobe.add('/videos/second.mp4');
    await addVideos(tester, queue, [
      '/videos/holiday.mp4',
      '/videos/second.mp4',
    ]);
    expect(find.textContaining('Applies to all videos'), findsOneWidget);

    await tester.tap(find.text('second.mp4'));
    await tester.pump();
    expect(find.text('What to do with the selected video?'), findsOneWidget);

    await tester.tap(find.text('Send to a phone'));
    await tester.pump();
    await tester.tap(find.text('Back to all videos'));
    await tester.pump();

    expect(find.text('What do you want to do?'), findsOneWidget);
    // Only the video with its own goal is labelled with it.
    expect(find.text('Send to a phone'), findsNWidgets(2));
  });

  group('for people who want more', () {
    testWidgets('each video can show its command, one line or explained', (
      tester,
    ) async {
      final queue = await pumpApp(tester, env);
      await addVideos(tester, queue, ['/videos/holiday.mp4']);

      await tester.tap(find.byTooltip('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show the command'));
      await tester.pumpAndSettle();

      final oneLine = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      expect(oneLine, startsWith('ffmpeg -hide_banner -i '));
      expect(oneLine, contains('holiday_hevc.mp4'));
      expect(oneLine, isNot(contains('\n')));
      expect(oneLine, isNot(contains('-progress')));

      await tester.tap(find.text('Explained'));
      await tester.pumpAndSettle();

      final explained = tester
          .widget<SelectableText>(find.byType(SelectableText))
          .data!;
      expect(explained, contains('# The video to convert'));
      expect(explained, contains('# Where the result is written'));
      expect(explained.split('\n').length, greaterThan(10));
    });

    testWidgets('extra options stay folded away until asked for', (
      tester,
    ) async {
      await pumpApp(tester, env);
      await tester.tap(find.text('Edit in DaVinci Resolve'));
      await tester.pump();
      await tester.tap(find.text('Free Resolve'));
      await tester.pump();

      expect(find.text('More options'), findsOneWidget);
      expect(find.text('DNxHR'), findsNothing);

      await tester.ensureVisible(find.text('More options'));
      await tester.tap(find.text('More options'));
      await tester.pumpAndSettle();

      expect(find.text('DNxHR'), findsOneWidget);
    });
  });

  group('details for those who want them', () {
    testWidgets('the format is named beside each plain choice', (tester) async {
      await pumpApp(tester, env);

      expect(find.widgetWithText(TechnicalText, 'HEVC'), findsOneWidget);
      expect(find.widgetWithText(TechnicalText, 'AV1'), findsOneWidget);
      expect(find.widgetWithText(TechnicalText, 'CRF 20'), findsOneWidget);
      expect(
        find.widgetWithText(
          TechnicalText,
          'HEVC 10-bit, CRF 20 · sound copied as is · MP4',
        ),
        findsOneWidget,
      );
    });

    testWidgets('each video shows what format it is', (tester) async {
      final queue = await pumpApp(tester, env);
      await addVideos(tester, queue, ['/videos/nikon.mov']);

      expect(find.widgetWithText(TechnicalText, 'H.265'), findsOneWidget);
    });
  });

  testWidgets('the two buttons of the empty screen are the same height', (
    tester,
  ) async {
    await pumpApp(tester, env);
    double height(String label) => tester
        .getSize(
          find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ),
        )
        .height;

    expect(height('Add videos'), height('Add folder'));
  });

  testWidgets('the language can be switched and is remembered', (tester) async {
    final settings = MemorySettingsStore();
    await pumpApp(tester, env, locale: null, settings: settings);
    expect(find.text('Start'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.translate_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Українська'));
    await tester.pumpAndSettle();

    expect(find.text('Почати'), findsOneWidget);

    // Started again with the same settings.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, FakeEnvironment(), locale: null, settings: settings);
    expect(find.text('Почати'), findsOneWidget);
  });
}
