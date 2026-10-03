import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/output/output_namer.dart';
import '../../../core/scenarios/registry.dart';
import '../../../core/scenarios/scenario.dart';
import '../../../l10n/app_localizations.dart';
import '../../format.dart';
import '../../providers.dart';
import '../../queue/queue_controller.dart';
import '../../recipe/recipe.dart';
import '../../recipe/recipe_controller.dart';
import '../../sources/preview_controller.dart';
import '../../sources/sources_controller.dart';
import '../../../core/ffmpeg/capabilities.dart';
import '../scenario_texts.dart';
import '../technical_text.dart';
import 'command_dialog.dart';
import 'language_button.dart';

/// The right-hand panel: what to do with the selected videos, and the
/// buttons that queue them.
class RecipePane extends ConsumerWidget {
  const RecipePane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final settings = ref.watch(recipeProvider);
    final recipe = settings.recipe;
    final controller = ref.read(recipeProvider.notifier);
    final selectedVideos = ref.watch(
      sourcesProvider.select((s) => s.selectedReady),
    );
    final capabilities = ref
        .watch(environmentProvider)
        .requireValue
        .capabilities;

    final selected = findPreset(recipe.presetId)!;
    final scenario = scenarios.firstWhere((s) => s.presets.contains(selected));
    final presets = scenario.presets
        .where((preset) => presetAvailable(preset, capabilities))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            selectedVideos.isEmpty
                                ? l10n.recipeTitleNone
                                : l10n.recipeTitleSelected(
                                    selectedVideos.length,
                                  ),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const LanguageButton(),
                      ],
                    ),
                    if (selectedVideos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.selectVideosHint,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: 14),
                    _ScenarioGrid(
                      selected: scenario,
                      onSelect: (s) => controller.selectPreset(
                        s.presets
                            .firstWhere(
                              (preset) => presetAvailable(preset, capabilities),
                            )
                            .id,
                      ),
                    ),
                    _Hint(scenarioHint(l10n, scenario.id)),
                    const SizedBox(height: 14),
                    if (presets.length > 1) ...[
                      SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: [
                          for (final preset in presets)
                            ButtonSegment(
                              value: preset.id,
                              label: _SegmentLabel(
                                presetTitle(l10n, preset.id),
                                caption: presetCaption(
                                  l10n,
                                  preset,
                                  recipe.values,
                                  capabilities,
                                ),
                              ),
                            ),
                        ],
                        selected: {selected.id},
                        onSelectionChanged: (ids) =>
                            controller.selectPreset(ids.first),
                      ),
                      _Hint(presetHint(l10n, selected.id)),
                    ],
                    for (final option in selected.options)
                      if (optionVisible(selected, option, recipe.values))
                        _OptionControl(
                          preset: selected,
                          option: option,
                          values: recipe.values,
                          capabilities: capabilities,
                          value: selected.choice(recipe.values, option.id),
                          onChanged: (value) =>
                              controller.setOption(option.id, value),
                        ),
                    _ConvertChoice(
                      sample: recipe.sample,
                      onChanged: controller.setSample,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, left: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TechnicalText(
                              technicalSummary(
                                l10n,
                                typicalPlan(
                                  selected,
                                  recipe.values,
                                  capabilities,
                                ),
                              ),
                            ),
                          ),
                          if (selectedVideos.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                final args = ref
                                    .read(queueProvider.notifier)
                                    .commandForVideo(selectedVideos.first);
                                if (args == null) return;
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => CommandDialog(args: args),
                                );
                              },
                              child: Text(l10n.showCommand),
                            ),
                        ],
                      ),
                    ),
                    if (selected.options.any(
                      (o) => advancedOptionVisible(selected, o, recipe.values),
                    ))
                      Theme(
                        // An expansion tile draws divider lines by default.
                        data: theme.copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          title: Text(
                            l10n.moreOptions,
                            style: theme.textTheme.titleSmall,
                          ),
                          children: [
                            for (final option in selected.options)
                              if (advancedOptionVisible(
                                selected,
                                option,
                                recipe.values,
                              ))
                                _OptionControl(
                                  preset: selected,
                                  option: option,
                                  values: recipe.values,
                                  capabilities: capabilities,
                                  value: selected.choice(
                                    recipe.values,
                                    option.id,
                                  ),
                                  onChanged: (value) =>
                                      controller.setOption(option.id, value),
                                ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    _SaveLocation(output: settings.output),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _AddControls(),
          ],
        ),
      ),
    );
  }
}

/// Whole video, or a ten-second sample from the start or the middle.
class _ConvertChoice extends StatelessWidget {
  const _ConvertChoice({required this.sample, required this.onChanged});

  final SampleChoice sample;
  final ValueChanged<SampleChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSample = sample != SampleChoice.none;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(l10n.convertTitle, style: theme.textTheme.titleSmall),
          ),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: _SegmentLabel(l10n.convertWhole),
              ),
              ButtonSegment(
                value: true,
                label: _SegmentLabel(l10n.convertSample),
              ),
            ],
            selected: {isSample},
            onSelectionChanged: (value) =>
                onChanged(value.first ? SampleChoice.start : SampleChoice.none),
          ),
          if (isSample) ...[
            const SizedBox(height: 8),
            SegmentedButton<SampleChoice>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: SampleChoice.start,
                  label: _SegmentLabel(l10n.sampleFromStart),
                ),
                ButtonSegment(
                  value: SampleChoice.middle,
                  label: _SegmentLabel(l10n.sampleFromMiddle),
                ),
              ],
              selected: {sample},
              onSelectionChanged: (value) => onChanged(value.first),
            ),
          ],
        ],
      ),
    );
  }
}

/// What Add to queue would do, and the buttons.
class _AddControls extends ConsumerWidget {
  const _AddControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final format = Formatter(l10n);
    final sources = ref.watch(sourcesProvider);
    final recipe = ref.watch(recipeProvider.select((s) => s.recipe));
    final previews = ref.watch(previewProvider);
    // Rebuilt when jobs change, so "already in the queue" stays true.
    ref.watch(queueProvider.select((q) => q.jobs));
    final queue = ref.read(queueProvider.notifier);

    final selected = sources.selectedReady;
    final all = sources.ready;
    final addableSelected = queue.addable(selected);
    final addableAll = queue.addable(all);
    final batch = batchEstimate(selected, previews);
    final measuring = selected.any((v) => previews[v.id]?.measuring ?? false);

    final String? summary;
    if (selected.isEmpty) {
      summary = null;
    } else if (addableSelected == 0) {
      summary = l10n.alreadyQueued;
    } else if (recipe.isSample) {
      summary = l10n.samplesCount(addableSelected);
    } else if (batch != null) {
      summary = [
        '${l10n.videoCount(selected.length)}  ·  ${format.bytes(batch.before)}'
            ' → ${l10n.aboutSize(format.bytes(batch.after))}',
        format.sizeChange(batch.before, batch.after),
        if (batch.time != null) l10n.takesAbout(format.wait(batch.time!)),
      ].join('  ·  ');
    } else {
      summary = [
        l10n.videoCount(selected.length),
        if (measuring) l10n.estimating,
      ].join('  ·  ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(
              summary,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: addableSelected > 0 ? queue.addSelected : null,
                icon: const Icon(Icons.playlist_add_rounded),
                label: Text(l10n.addToQueue),
              ),
            ),
            // Only when it would do something the main button does not.
            if (all.length > selected.length) ...[
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: addableAll > 0 ? queue.addAll : null,
                child: Text(l10n.addAllToQueue(all.length)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// The goals as a two-column grid of compact tiles. Only the chosen goal is
/// explained (below the grid), which keeps six goals on one screen.
class _ScenarioGrid extends StatelessWidget {
  const _ScenarioGrid({required this.selected, required this.onSelect});

  final Scenario selected;
  final ValueChanged<Scenario> onSelect;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - _gap) / 2;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final scenario in scenarios)
              SizedBox(
                width: tileWidth,
                child: _ScenarioTile(
                  scenario: scenario,
                  selected: scenario == selected,
                  onTap: () => onSelect(scenario),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.scenario,
    required this.selected,
    required this.onTap,
  });

  final Scenario scenario;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  scenarioIcon(scenario.id),
                  size: 24,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    scenarioTitle(l10n, scenario.id),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? scheme.onPrimaryContainer : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _OptionControl extends StatelessWidget {
  const _OptionControl({
    required this.preset,
    required this.option,
    required this.values,
    required this.capabilities,
    required this.value,
    required this.onChanged,
  });

  final Preset preset;
  final PresetOption option;
  final OptionValues values;
  final Capabilities capabilities;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final title = optionTitle(l10n, preset.id, option.id);

    if (isSwitch(option)) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(title),
          subtitle: Text(optionHint(l10n, option.id)),
          value: value == 'yes',
          onChanged: (on) => onChanged(on ? 'yes' : 'no'),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: theme.textTheme.titleSmall),
          ),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              for (final choice in option.choices)
                ButtonSegment(
                  value: choice,
                  label: _SegmentLabel(
                    choiceLabel(l10n, preset.id, choice),
                    caption: choiceCaption(
                      l10n,
                      preset,
                      option.id,
                      choice,
                      values,
                      capabilities,
                    ),
                  ),
                ),
            ],
            selected: {value},
            onSelectionChanged: (values) => onChanged(values.first),
          ),
        ],
      ),
    );
  }
}

class _SaveLocation extends ConsumerWidget {
  const _SaveLocation({required this.output});

  final OutputSettings output;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final controller = ref.read(recipeProvider.notifier);
    final custom = output.mode == OutputMode.customFolder
        ? output.customDir
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(l10n.saveTitle, style: theme.textTheme.titleSmall),
        ),
        Row(
          children: [
            Icon(
              Icons.folder_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Tooltip(
                message: custom ?? '',
                child: Text(
                  custom == null
                      ? l10n.saveNextToOriginals
                      : p.basename(custom),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            if (custom != null)
              IconButton(
                tooltip: l10n.saveReset,
                icon: const Icon(Icons.undo_rounded, size: 20),
                onPressed: () => controller.setOutput(const OutputSettings()),
              ),
            TextButton(
              onPressed: () async {
                final folder = await getDirectoryPath();
                if (folder == null) return;
                controller.setOutput(
                  OutputSettings(
                    mode: OutputMode.customFolder,
                    customDir: folder,
                  ),
                );
              },
              child: Text(l10n.saveChooseFolder),
            ),
          ],
        ),
      ],
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text, {this.caption});

  final String text;

  /// Technical name shown small under the label, e.g. "AV1".
  final String? caption;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, maxLines: 1, softWrap: false),
          if (caption != null) TechnicalText(caption!),
        ],
      ),
    ),
  );
}

/// Expected total size and time for [videos], or null while nothing has been
/// worked out yet.
///
/// Videos not measured yet are assumed to shrink like the measured ones, in
/// proportion to their size, and to take time in proportion to their length.
({int before, int after, Duration? time})? batchEstimate(
  List<SourceVideo> videos,
  Map<int, Preview> previews,
) {
  final known = [
    for (final video in videos)
      if (previews[video.id]?.estimate case final estimate?) (video, estimate),
  ];
  if (known.isEmpty) return null;
  int size(SourceVideo v) => v.info?.sizeBytes ?? 0;
  int length(SourceVideo v) => v.info?.duration.inMilliseconds ?? 0;

  final before = videos.fold(0, (sum, v) => sum + size(v));
  final knownBefore = known.fold(0, (sum, k) => sum + size(k.$1));
  final knownAfter = known.fold(0, (sum, k) => sum + k.$2.bytes);
  final after = knownBefore > 0
      ? (knownAfter * before / knownBefore).round()
      : knownAfter;

  // Only re-encodes take noticeable time; quick fixes take seconds.
  final timed = known.where((k) => k.$2.time != null).toList();
  final encodes = videos.where(
    (v) => previews[v.id]?.plan.kind == PlanKind.encode,
  );
  final timedLength = timed.fold(0, (sum, k) => sum + length(k.$1));
  final encodeLength = encodes.fold(0, (sum, v) => sum + length(v));
  final timedSpent = timed.fold(Duration.zero, (sum, k) => sum + k.$2.time!);
  final time = timedLength > 0
      ? timedSpent * (encodeLength / timedLength)
      : null;
  return (before: before, after: after, time: time);
}
