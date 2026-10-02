import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/open_external.dart';
import '../../core/queue/job_executor.dart';
import '../../l10n/app_localizations.dart';
import '../format.dart';
import '../providers.dart';
import '../queue/queue_controller.dart';
import '../queue/queue_state.dart';
import 'widgets/files_pane.dart';
import 'widgets/task_pane.dart';

/// The whole app on one screen: videos on the left, what to do with them on
/// the right.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Below this width the two panes are stacked instead of side by side.
  static const _wideLayout = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final environment = ref.watch(environmentProvider);

    return Scaffold(
      body: SafeArea(
        child: environment.when(
          loading: () => _Message(
            icon: const CircularProgressIndicator(),
            title: l10n.startingUp,
          ),
          error: (_, _) => _Message(
            icon: Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            title: l10n.engineMissingTitle,
            body: l10n.engineMissingBody,
          ),
          data: (_) => const _Workspace(),
        ),
      ),
    );
  }
}

class _Workspace extends ConsumerWidget {
  const _Workspace();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(queueControllerProvider.select((s) => s.sample), (_, sample) {
      if (sample != null && !sample.isRunning) {
        _showSample(context, ref, sample);
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= HomeScreen._wideLayout;
        return Padding(
          padding: const EdgeInsets.all(20),
          child: wide
              ? const Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: FilesPane()),
                    SizedBox(width: 20),
                    SizedBox(width: 400, child: TaskPane()),
                  ],
                )
              : const Column(
                  children: [
                    Expanded(flex: 5, child: FilesPane()),
                    SizedBox(height: 20),
                    Expanded(flex: 6, child: TaskPane()),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _showSample(
    BuildContext context,
    WidgetRef ref,
    SampleOutcome sample,
  ) async {
    final controller = ref.read(queueControllerProvider.notifier);
    final result = sample.result!;
    if (result.status == ConversionStatus.cancelled) {
      controller.dismissSample();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final format = Formatter(l10n);
    final ok = result.status == ConversionStatus.done;
    final original = ref
        .read(queueControllerProvider)
        .items
        .where((i) => i.id == sample.itemId)
        .firstOrNull;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          ok ? Icons.visibility_outlined : Icons.error_outline_rounded,
          size: 32,
        ),
        title: Text(ok ? l10n.sampleReadyTitle : l10n.sampleFailed),
        content: ok
            ? Text(
                l10n.sampleReadyBody(
                  format.bytes(sample.estimatedFullBytes ?? 0),
                  format.wait(sample.estimatedFullTime ?? Duration.zero),
                ),
              )
            : null,
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        actions: [
          if (ok)
            FilledButton.tonalIcon(
              onPressed: () => openWithDefaultApp(result.outputPath!),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.playSample),
            ),
          if (ok && original != null)
            OutlinedButton(
              onPressed: () => openWithDefaultApp(original.path),
              child: Text(l10n.playOriginal),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
    controller.dismissSample();
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.body});

  final Widget icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
