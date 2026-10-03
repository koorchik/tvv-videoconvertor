import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/open_external.dart';
import '../../../core/scenarios/scenario.dart';
import '../../../l10n/app_localizations.dart';
import '../../format.dart';
import '../../queue/queue_controller.dart';
import '../../../core/scenarios/registry.dart';
import '../../queue/queue_state.dart';
import '../../theme.dart';
import '../scenario_texts.dart';
import '../technical_text.dart';
import 'command_dialog.dart';

/// One video in the list: what it is, what will happen to it or how far along
/// it is, and the actions that make sense in its current state.
class FileTile extends ConsumerWidget {
  const FileTile({super.key, required this.item, required this.index});

  final QueueItem item;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final format = Formatter(l10n);
    final controller = ref.read(queueControllerProvider.notifier);
    final (statusText, statusColor) = _status(
      l10n,
      scheme,
      SuccessColors.of(context),
    );
    final info = item.info;
    final selected = ref.watch(
      queueControllerProvider.select((s) => s.selectedIds.contains(item.id)),
    );
    final goal = item.goal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected || item.isActive
                ? scheme.primary
                : scheme.outlineVariant,
            width: selected ? 2 : (item.isActive ? 1.5 : 1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Clicking selects the video, so the goal panel applies to it
          // alone. Ctrl (Cmd on macOS) adds to the selection.
          onTap: () => controller.toggleSelected(
            item.id,
            additive:
                HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                _LeadingIcon(status: item.status),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              format.fileName(item.path),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          if (info?.video != null) ...[
                            const SizedBox(width: 10),
                            TechnicalText(sourceFormat(info!.video!)),
                          ],
                        ],
                      ),
                      if (item.customGoal && goal != null)
                        _GoalLabel(goal: goal),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (info != null) format.summary(info),
                          if (statusText.isNotEmpty) statusText,
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                        ),
                      ),
                      if (item.isActive) ...[
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          // Encoders report nothing for the first seconds; an
                          // animated bar shows the app is working meanwhile.
                          value: (item.progress?.fraction ?? 0) > 0
                              ? item.progress!.fraction
                              : null,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _progressLine(l10n, format),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      for (final note in _notes(l10n))
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            note,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (item.status == ItemStatus.failed)
                  TextButton(
                    onPressed: () => _showError(context, l10n),
                    child: Text(l10n.details),
                  ),
                if (item.canRetry)
                  IconButton(
                    tooltip: l10n.retry,
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => controller.retry(item.id),
                  ),
                if (item.status == ItemStatus.done)
                  IconButton(
                    tooltip: l10n.showInFolder,
                    icon: const Icon(Icons.folder_open_rounded),
                    onPressed: () =>
                        revealInFileManager(item.result!.outputPath!),
                  ),
                if (item.info != null && (item.plan?.producesOutput ?? false))
                  PopupMenuButton<void>(
                    tooltip: l10n.more,
                    icon: const Icon(Icons.more_horiz_rounded),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () {
                          final args = controller.commandFor(item);
                          if (args == null) return;
                          showDialog<void>(
                            context: context,
                            builder: (_) => CommandDialog(args: args),
                          );
                        },
                        child: Text(l10n.showCommand),
                      ),
                      PopupMenuItem(
                        onTap: () => controller.duplicate(item.id),
                        child: Text(l10n.addAgain),
                      ),
                    ],
                  ),
                IconButton(
                  tooltip: item.isActive ? l10n.cancel : l10n.remove,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => item.isActive
                      ? controller.cancelActive()
                      : controller.remove(item.id),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Tooltip(
                    message: l10n.dragToReorder,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: scheme.outline,
                      ),
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

  (String, Color) _status(
    AppLocalizations l10n,
    ColorScheme scheme,
    SuccessColors success,
  ) {
    final muted = scheme.onSurfaceVariant;
    final result = item.result;
    final info = item.info;
    switch (item.status) {
      case ItemStatus.probing:
        return (l10n.statusChecking, muted);
      case ItemStatus.unreadable:
        return (l10n.statusUnreadable, scheme.error);
      case ItemStatus.running:
        return ('', muted);
      case ItemStatus.paused:
        return (l10n.statusPaused, muted);
      case ItemStatus.skipped:
        return (l10n.statusNothingToDo, success.text);
      case ItemStatus.failed:
        return (l10n.statusFailed, scheme.error);
      case ItemStatus.cancelled:
        return (l10n.statusCancelled, muted);
      case ItemStatus.done:
        final bytes = result?.outputBytes;
        if (bytes == null || info == null) return (l10n.statusDone, muted);
        final format = Formatter(l10n);
        return (
          '${l10n.statusDone}: ${format.bytes(bytes)}, '
              '${format.sizeChange(info.sizeBytes, bytes)}',
          success.text,
        );
      case ItemStatus.waiting:
        return switch (item.plan?.kind) {
          PlanKind.skip => (l10n.statusReadyAsIs, success.text),
          PlanKind.remux || PlanKind.audioOnly => (
            [l10n.statusQuickFix, ?_expected(l10n)].join('  '),
            scheme.primary,
          ),
          PlanKind.unsupported => (
            switch (item.plan!.notes.firstOrNull) {
              PlanNote.noAudioStream => l10n.statusNoSound,
              PlanNote.containerCannotHold => l10n.statusCannotHold,
              _ => l10n.statusUnsupported,
            },
            scheme.error,
          ),
          _ => (
            [l10n.statusFullConversion, ?_expected(l10n)].join('  '),
            muted,
          ),
        };
    }
  }

  /// `→ about 210 MB`, or a note that it is being measured.
  String? _expected(AppLocalizations l10n) {
    final estimate = item.estimate;
    if (estimate != null) {
      return '→ ${l10n.aboutSize(Formatter(l10n).bytes(estimate.bytes))}';
    }
    return item.estimating ? '· ${l10n.estimating}' : null;
  }

  String _progressLine(AppLocalizations l10n, Formatter format) {
    final progress = item.progress;
    if (progress == null || progress.fraction <= 0) return l10n.statusStarting;
    return [
      '${(progress.fraction * 100).floor()}%',
      if (progress.remaining != null)
        l10n.progressLeft(format.wait(progress.remaining!)),
      if (progress.predictedBytes != null)
        l10n.aboutSize(format.bytes(progress.predictedBytes!)),
    ].join('  ·  ');
  }

  /// Warnings about a waiting file, in plain words.
  List<String> _notes(AppLocalizations l10n) {
    if (item.status != ItemStatus.waiting) return const [];
    return [
      for (final note in item.plan?.notes ?? const <PlanNote>[])
        ...switch (note) {
          PlanNote.variableFrameRateFixed => [l10n.noteVariableFrameRate],
          PlanNote.hevc422NeedsRecentNvidia => [l10n.noteHevc422],
          PlanNote.experimentalAv1Intermediate => [l10n.noteExperimentalAv1],
          PlanNote.hdrToneMapped => [l10n.noteHdrToneMapped],
          PlanNote.hdrNotConverted => [l10n.noteHdrNotConverted],
          PlanNote.audioConvertedToFit => [l10n.noteAudioConvertedToFit],
          _ => const <String>[],
        },
    ];
  }

  void _showError(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.statusFailed),
        content: SingleChildScrollView(
          child: SelectableText(
            item.result?.errorLines.join('\n') ?? '',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.status});

  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final success = SuccessColors.of(context);
    final (icon, background, foreground) = switch (status) {
      ItemStatus.done || ItemStatus.skipped => (
        Icons.check_rounded,
        success.container,
        success.onContainer,
      ),
      ItemStatus.failed || ItemStatus.unreadable => (
        Icons.error_outline_rounded,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      ItemStatus.running || ItemStatus.paused => (
        Icons.movie_outlined,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      _ => (
        Icons.movie_outlined,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: foreground),
    );
  }
}

/// The goal of a video that was given one of its own, e.g.
/// "Send to a phone" or "Make it small · Smallest file".
class _GoalLabel extends StatelessWidget {
  const _GoalLabel({required this.goal});

  final TaskSelection goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preset = findPreset(goal.presetId);
    if (preset == null) return const SizedBox.shrink();
    final scenario = scenarios.firstWhere((s) => s.presets.contains(preset));
    final text = [
      scenarioTitle(l10n, scenario.id),
      if (scenario.presets.length > 1) presetTitle(l10n, preset.id),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(scenarioIcon(scenario.id), size: 15, color: scheme.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
