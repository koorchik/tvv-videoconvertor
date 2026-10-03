import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings.dart';
import 'button_menu.dart';

/// Each language's own short name. "UK" would read as the United Kingdom.
const _shortNames = {'en': 'EN', 'uk': 'УКР'};

/// Switches the interface language. The choice is remembered.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final chosen = ref.watch(localeProvider)?.languageCode;
    final controller = ref.read(localeProvider.notifier);

    // The Builder gives the menu the button's own place on screen.
    return Builder(
      builder: (context) => TextButton.icon(
        onPressed: () => showMenuUnder(context, [
          for (final entry in appLanguages.entries)
            tickedMenuItem(
              label: entry.value,
              ticked: chosen == entry.key,
              onTap: () => controller.select(entry.key),
            ),
          const PopupMenuDivider(height: 1),
          tickedMenuItem(
            label: l10n.languageSystem,
            ticked: chosen == null,
            onTap: () => controller.select(null),
          ),
        ]),
        icon: const Icon(Icons.translate_rounded, size: 18),
        // The language currently shown, in its own short form.
        label: Text(_shortNames[l10n.localeName] ?? l10n.localeName),
      ),
    );
  }
}
