import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings_store.dart';

/// Where choices are remembered. `main` replaces this with a file-backed
/// store; tests get one that forgets.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => MemorySettingsStore(),
);

/// Languages the app is translated into, by code, with their own names.
const appLanguages = {'en': 'English', 'uk': 'Українська'};

final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

/// The language the user picked, or null to follow the computer's.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'language';

  @override
  Locale? build() {
    final code = ref.read(settingsStoreProvider).read(_key);
    return code is String && appLanguages.containsKey(code)
        ? Locale(code)
        : null;
  }

  /// [code] is a key of [appLanguages], or null for the computer's language.
  Future<void> select(String? code) async {
    state = code == null ? null : Locale(code);
    await ref.read(settingsStoreProvider).write(_key, code);
  }
}
