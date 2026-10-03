import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../l10n/app_localizations.dart';
import 'queue/queue_controller.dart';

/// Asks before closing the window while videos are being converted, so a
/// stray click does not throw away an hour of work.
class WindowCloseGuard extends ConsumerStatefulWidget {
  const WindowCloseGuard({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WindowCloseGuard> createState() => _WindowCloseGuardState();
}

class _WindowCloseGuardState extends ConsumerState<WindowCloseGuard>
    with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    if (!ref.exists(queueProvider) || !ref.read(queueProvider).busy) {
      await windowManager.destroy();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.quitTitle),
        content: Text(l10n.quitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.quit),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.keepConverting),
          ),
        ],
      ),
    );
    if (quit != true) return;
    // Stopping first lets FFmpeg exit and the unfinished file be removed.
    final queue = ref.read(queueProvider.notifier);
    if (!ref.read(queueProvider).paused) queue.togglePause();
    await queue.cancelActive();
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
