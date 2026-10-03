import 'package:flutter/material.dart';

import '../../core/ffmpeg/capabilities.dart';
import '../../core/scenarios/compress.dart';
import '../../core/scenarios/scenario.dart';
import '../../l10n/app_localizations.dart';

/// The words and icons shown for scenarios, presets and their options.
///
/// The conversion engine knows these only by id. A new scenario needs its
/// texts added here and in the ARB files; no other UI code changes.

IconData scenarioIcon(String scenarioId) => switch (scenarioId) {
  'compress' => Icons.compress_rounded,
  'resolve' => Icons.movie_edit,
  'share' => Icons.smartphone_rounded,
  'audio' => Icons.music_note_rounded,
  'privacy' => Icons.shield_outlined,
  'remux' => Icons.swap_horiz_rounded,
  _ => Icons.auto_awesome_rounded,
};

String scenarioTitle(AppLocalizations l10n, String scenarioId) =>
    switch (scenarioId) {
      'compress' => l10n.scenarioCompressTitle,
      'resolve' => l10n.scenarioResolveTitle,
      'share' => l10n.scenarioShareTitle,
      'audio' => l10n.scenarioAudioTitle,
      'privacy' => l10n.scenarioPrivacyTitle,
      'remux' => l10n.scenarioRemuxTitle,
      _ => scenarioId,
    };

String scenarioHint(AppLocalizations l10n, String scenarioId) =>
    switch (scenarioId) {
      'compress' => l10n.scenarioCompressHint,
      'resolve' => l10n.scenarioResolveHint,
      'share' => l10n.scenarioShareHint,
      'audio' => l10n.scenarioAudioHint,
      'privacy' => l10n.scenarioPrivacyHint,
      'remux' => l10n.scenarioRemuxHint,
      _ => '',
    };

String presetTitle(AppLocalizations l10n, String presetId) =>
    switch (presetId) {
      'compress.hevc' => l10n.presetCompressHevc,
      'compress.av1' => l10n.presetCompressAv1,
      'compress.gpu' => l10n.presetCompressGpu,
      'resolve.studio' => l10n.presetResolveStudio,
      'resolve.free' => l10n.presetResolveFree,
      _ => presetId,
    };

String presetHint(AppLocalizations l10n, String presetId) => switch (presetId) {
  'compress.hevc' => l10n.presetCompressHevcHint,
  'compress.av1' => l10n.presetCompressAv1Hint,
  'compress.gpu' => l10n.presetCompressGpuHint,
  'resolve.studio' => l10n.presetResolveStudioHint,
  'resolve.free' => l10n.presetResolveFreeHint,
  _ => '',
};

String optionTitle(AppLocalizations l10n, String presetId, String optionId) =>
    switch (optionId) {
      'convertVideo' => l10n.convertVideoTitle,
      'codec' => l10n.optionCodecTitle,
      'size' => l10n.optionSizeTitle,
      'format' => l10n.optionFormatTitle,
      'mode' => l10n.optionModeTitle,
      'quality' when presetId.startsWith('resolve') => l10n.sizeTitle,
      'quality' => l10n.qualityTitle,
      _ => optionId,
    };

String optionHint(AppLocalizations l10n, String optionId) => switch (optionId) {
  'convertVideo' => l10n.convertVideoHint,
  'mode' => l10n.modeThoroughHint,
  _ => '',
};

String choiceLabel(AppLocalizations l10n, String presetId, String choice) =>
    switch (choice) {
      'compact' => l10n.qualityCompact,
      'high' => l10n.qualityHigh,
      'maximum' => l10n.qualityMaximum,
      'smallest' => l10n.sizeSmallest,
      'smaller' => l10n.sizeSmaller,
      'balanced' => l10n.sizeBalanced,
      'best' => l10n.sizeBest,
      'small' => l10n.shareSmall,
      'standard' => l10n.shareStandard,
      'original' => l10n.formatOriginal,
      'quick' => l10n.modeQuick,
      'thorough' => l10n.modeThorough,
      // File type names are written the same everywhere.
      'mp3' ||
      'm4a' ||
      'wav' ||
      'flac' ||
      'mp4' ||
      'mkv' ||
      'mov' => choice.toUpperCase(),
      // Format names are the same in every language.
      'prores' => 'ProRes',
      'dnxhr' => 'DNxHR',
      _ => choice,
    };

/// Presets that make no sense on this computer are left out, so nobody can
/// pick "use the graphics card" on a machine without a usable one.
bool presetAvailable(Preset preset, Capabilities capabilities) =>
    preset.id != CompressPreset.gpu.id ||
    CompressPreset.gpuEncoder(capabilities) != null;

/// Options that have no effect with the current choices are hidden rather
/// than shown disabled.
bool optionVisible(Preset preset, PresetOption option, OptionValues values) {
  if (option.advanced) return false;
  if (preset.id == 'resolve.studio' && option.id == 'quality') {
    return preset.choice(values, 'convertVideo') == 'yes';
  }
  return true;
}

/// A yes/no option is shown as a switch instead of two buttons.
bool isSwitch(PresetOption option) =>
    option.choices.length == 2 &&
    option.choices.contains('yes') &&
    option.choices.contains('no');

/// Options for people who want more control, shown under "More options".
/// As with the basic ones, an option that would change nothing is hidden.
bool advancedOptionVisible(
  Preset preset,
  PresetOption option,
  OptionValues values,
) {
  if (!option.advanced) return false;
  if (option.id == 'codec') {
    final convertsPicture =
        preset.id == 'resolve.free' ||
        preset.choice(values, 'convertVideo') == 'yes';
    return convertsPicture && preset.choice(values, 'quality') != 'smallest';
  }
  return true;
}

/// The options chosen for a job, in the words the panel uses: "Quality: Best
/// quality", "Also convert the picture". Options that had no effect are left
/// out, as the panel hides them; expert options are left to the technical
/// line, where their names belong.
List<String> chosenOptions(
  AppLocalizations l10n,
  Preset preset,
  OptionValues values,
) {
  final chosen = <String>[];
  for (final option in preset.options) {
    if (!optionVisible(preset, option, values)) continue;
    final choice = preset.choice(values, option.id);
    final title = optionTitle(l10n, preset.id, option.id);
    if (isSwitch(option)) {
      if (choice == 'yes') chosen.add(title);
    } else {
      chosen.add('$title: ${choiceLabel(l10n, preset.id, choice)}');
    }
  }
  return chosen;
}
