import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tvv_videoconvertor/app/app.dart';
import 'package:tvv_videoconvertor/app/home/technical_text.dart';
import 'package:tvv_videoconvertor/app/providers.dart';
import 'package:tvv_videoconvertor/app/settings.dart';
import 'package:tvv_videoconvertor/core/settings/settings_store.dart';
import 'package:tvv_videoconvertor/app/sources/sources_controller.dart';

import 'fakes.dart';

const _screenshotKey = ValueKey('screenshot');

/// Starts the app against a [FakeEnvironment] in a window of [size].
Future<SourcesController> pumpApp(
  WidgetTester tester,
  FakeEnvironment env, {
  Locale? locale = const Locale('en'),
  SettingsStore? settings,
  ThemeMode themeMode = ThemeMode.light,
  Size size = const Size(1180, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      ...env.overrides,
      if (settings != null) settingsStoreProvider.overrideWithValue(settings),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: _screenshotKey,
        child: VideoConverterApp(locale: locale, themeMode: themeMode),
      ),
    ),
  );
  await container.read(environmentProvider.future);
  await tester.pump();
  return container.read(sourcesProvider.notifier);
}

/// Adds files to the list. Checking whether a path is a folder is real disk
/// access, which only completes outside the test's simulated clock.
Future<void> addVideos(
  WidgetTester tester,
  SourcesController sources,
  Iterable<String> paths,
) async {
  await tester.runAsync(() => sources.addPaths(paths));
  await tester.pump();
}

/// Text on screen in the main, plain-language style: everything except the
/// small technical notes beside it.
List<String> plainTexts(WidgetTester tester) {
  final technical = tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(TechnicalText),
          matching: find.byType(Text),
        ),
      )
      .toSet();
  return [
    for (final text in tester.widgetList<Text>(find.byType(Text)))
      if (!technical.contains(text))
        text.data ?? text.textSpan?.toPlainText() ?? '',
  ];
}

/// Every piece of text currently on screen.
List<String> visibleTexts(WidgetTester tester) => [
  for (final text in tester.widgetList<Text>(find.byType(Text)))
    text.data ?? text.textSpan?.toPlainText() ?? '',
];

/// Loads the real Roboto and icon fonts, so rendered images show readable
/// text instead of the test framework's placeholder boxes.
Future<void> loadRealFonts() async {
  final fonts = p.join(
    Platform.environment['FLUTTER_ROOT']!,
    'bin',
    'cache',
    'artifacts',
    'material_fonts',
  );
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File(p.join(fonts, name)).readAsBytes());

  final roboto = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(read('Roboto-$weight.ttf'));
  }
  await roboto.load();
  final mono = FontLoader('JetBrains Mono')
    ..addFont(
      File('assets/fonts/JetBrainsMono-Regular.ttf')
          .readAsBytes()
          .then(ByteData.sublistView),
    );
  await mono.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(read('MaterialIcons-Regular.otf'));
  await icons.load();
}

/// Saves what is on screen to `build/screenshots/<name>.png`.
Future<void> saveScreenshot(WidgetTester tester, String name) async {
  // Lets fades finish (a button going from disabled to enabled, for one), so
  // the image shows the settled state.
  await tester.pump(const Duration(milliseconds: 400));
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_screenshotKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(p.join('build', 'screenshots', '$name.png'));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}
