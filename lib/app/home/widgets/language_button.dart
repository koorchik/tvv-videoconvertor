import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings.dart';

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

    return MenuAnchor(
      builder: (context, menu, _) => TextButton.icon(
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        icon: const Icon(Icons.translate_rounded, size: 18),
        // The language currently shown, in its own short form.
        label: Text(_shortNames[l10n.localeName] ?? l10n.localeName),
      ),
      menuChildren: [
        for (final entry in appLanguages.entries)
          _choice(entry.value, chosen == entry.key, () {
            controller.select(entry.key);
          }),
        const Divider(height: 1),
        _choice(l10n.languageSystem, chosen == null, () {
          controller.select(null);
        }),
      ],
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onPressed) =>
      MenuItemButton(
        onPressed: onPressed,
        leadingIcon: Icon(
          Icons.check_rounded,
          size: 18,
          color: selected ? null : Colors.transparent,
        ),
        child: Text(label),
      );
}
