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
import '../../queue/queue_state.dart';
import '../../theme.dart';
import '../scenario_texts.dart';

/// The right-hand panel: what to do with the videos, where to save them, and
/// the button that starts it. While converting it shows overall progress and
/// the controls to pause or stop.
class TaskPane extends ConsumerWidget {
  const TaskPane({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(queueControllerProvider);
    final controller = ref.read(queueControllerProvider.notifier);
    final capabilities = ref
        .watch(environmentProvider)
        .requireValue
        .capabilities;

    final selected = findPreset(state.selection.presetId)!;
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
                    Text(
                      l10n.goalTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
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
                      if (optionVisible(
                        selected,
                        option,
                        state.selection.values,
                      ))
                        _OptionControl(
                          preset: selected,
                          option: option,
                          value: selected.choice(
                            state.selection.values,
                            option.id,
                          ),
                          onChanged: (value) =>
                              controller.setOption(option.id, value),
                        ),
                    if (selected.options.any(
                      (o) => advancedOptionVisible(
                        selected,
                        o,
                        state.selection.values,
                      ),
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
                                state.selection.values,
                              ))
                                _OptionControl(
                                  preset: selected,
                                  option: option,
                                  value: selected.choice(
                                    state.selection.values,
                                    option.id,
                                  ),
                                  onChanged: (value) =>
                                      controller.setOption(option.id, value),
                                ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    _SaveLocation(output: state.output),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (state.isRunning)
              _RunningControls(state: state)
            else
              _StartControls(state: state),
          ],
        ),
      ),
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
    required this.value,
    required this.onChanged,
  });

  final Preset preset;
  final PresetOption option;
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
                  label: _SegmentLabel(choiceLabel(l10n, preset.id, choice)),
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
    final controller = ref.read(queueControllerProvider.notifier);
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

class _StartControls extends ConsumerWidget {
  const _StartControls({required this.state});

  final QueueState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final format = Formatter(l10n);
    final controller = ref.read(queueControllerProvider.notifier);
    final pending = state.pending.toList();
    final sampleRunning = state.sample?.isRunning ?? false;

    final done = state.items.where((i) => i.status == ItemStatus.done);
    final before = done.fold<int>(0, (s, i) => s + (i.info?.sizeBytes ?? 0));
    final after = done.fold<int>(0, (s, i) => s + (i.result?.outputBytes ?? 0));
    final finished = pending.isEmpty && done.isNotEmpty;

    // A size can be promised up front only when every file's is known.
    final estimates = pending.map((i) => i.plan?.estimatedBytes).toList();
    final estimate = estimates.isNotEmpty && !estimates.contains(null)
        ? estimates.fold<int>(0, (s, bytes) => s + bytes!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (finished)
          _Summary(
            icon: Icons.celebration_rounded,
            title: l10n.allDone,
            detail:
                '${l10n.savedSummary(format.bytes(before), format.bytes(after))}'
                ', ${format.sizeChange(before, after)}',
          )
        else if (state.items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 4),
            child: Text(
              [
                l10n.toConvertCount(pending.length),
                if (estimate != null) l10n.aboutSize(format.bytes(estimate)),
              ].join('  ·  '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        FilledButton.icon(
          onPressed: pending.isEmpty || sampleRunning ? null : controller.start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(l10n.start),
        ),
        const SizedBox(height: 10),
        if (sampleRunning)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Flexible(child: Text(l10n.sampleMaking)),
              TextButton(
                onPressed: controller.cancelActive,
                child: Text(l10n.cancel),
              ),
            ],
          )
        else
          MenuAnchor(
            builder: (context, menu, _) => OutlinedButton.icon(
              onPressed: pending.isEmpty
                  ? null
                  : () => menu.isOpen ? menu.close() : menu.open(),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.trySample),
            ),
            menuChildren: [
              MenuItemButton(
                onPressed: pending.isEmpty
                    ? null
                    : () => controller.runSample(pending.first.id),
                child: Text(l10n.sampleFromStart),
              ),
              MenuItemButton(
                onPressed: pending.isEmpty
                    ? null
                    : () => controller.runSample(
                        pending.first.id,
                        fromMiddle: true,
                      ),
                child: Text(l10n.sampleFromMiddle),
              ),
            ],
          ),
      ],
    );
  }
}

class _RunningControls extends ConsumerWidget {
  const _RunningControls({required this.state});

  final QueueState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final format = Formatter(l10n);
    final controller = ref.read(queueControllerProvider.notifier);
    final active = state.activeItem;
    final paused = active?.status == ItemStatus.paused;

    // Progress across the batch, weighted by video length: a two-hour video
    // counts for more than a ten-second clip.
    double seconds(QueueItem i) =>
        (i.info?.duration.inMilliseconds ?? 0) / 1000;
    final finishedItems = state.items.where(
      (i) => i.status == ItemStatus.done && i.plan != null,
    );
    final waiting = state.pending.toList();
    final doneSeconds = finishedItems.fold<double>(0, (s, i) => s + seconds(i));
    final activeSeconds = active == null
        ? 0.0
        : seconds(active) * (active.progress?.fraction ?? 0);
    final totalSeconds =
        doneSeconds +
        (active == null ? 0 : seconds(active)) +
        waiting.fold<double>(0, (s, i) => s + seconds(i));
    final fraction = totalSeconds > 0
        ? (doneSeconds + activeSeconds) / totalSeconds
        : 0.0;

    // The waiting files are assumed to convert at the speed of the current
    // one. Quick fixes take seconds and are not counted.
    final speed = active?.progress?.speed;
    final remaining = active?.progress?.remaining;
    Duration? left;
    if (remaining != null && speed != null && speed > 0) {
      final waitingEncodes = waiting
          .where((i) => i.plan?.kind == PlanKind.encode)
          .fold<double>(0, (s, i) => s + seconds(i));
      left =
          remaining +
          Duration(milliseconds: (waitingEncodes / speed * 1000).round());
    }
    final position = finishedItems.length + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          [
            l10n.convertingCount(position, position + waiting.length),
            if (left != null) l10n.progressLeft(format.wait(left)),
          ].join('  ·  '),
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(value: fraction > 0 ? fraction : null),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: active == null ? null : controller.togglePause,
                icon: Icon(
                  paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(paused ? l10n.resume : l10n.pause),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.stopAll,
                icon: const Icon(Icons.stop_rounded),
                label: Text(l10n.stop),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = SuccessColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: success.container,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: success.onContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: success.onContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: success.onContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A segmented-button label that shrinks slightly rather than wrapping when
/// a translation is longer than its segment.
class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );
}
