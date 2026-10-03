import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'home/home_screen.dart';
import 'settings.dart';
import 'theme.dart';

class VideoConverterApp extends ConsumerWidget {
  const VideoConverterApp({
    super.key,
    this.locale,
    this.home = const HomeScreen(),
  });

  final Widget home;

  /// Forces a language, for tests. Otherwise the remembered choice is used,
  /// and without one the computer's language.
  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale ?? ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(ref.watch(lookProvider)),
      home: home,
    );
  }
}
