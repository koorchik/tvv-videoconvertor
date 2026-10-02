import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'home/home_screen.dart';
import 'theme.dart';

class VideoConverterApp extends StatelessWidget {
  const VideoConverterApp({
    super.key,
    this.locale,
    this.themeMode,
    this.home = const HomeScreen(),
  });

  final Widget home;

  /// The language chosen in settings. Null follows the system language.
  final Locale? locale;

  /// Null follows the system's light or dark setting.
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode ?? ThemeMode.system,
      home: home,
    );
  }
}
