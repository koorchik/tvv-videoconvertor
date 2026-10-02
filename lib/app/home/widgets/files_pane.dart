import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/media/video_files.dart';
import '../../../l10n/app_localizations.dart';
import '../../format.dart';
import '../../queue/queue_controller.dart';
import 'file_tile.dart';

/// The list of videos. The whole pane accepts dropped files and folders, at
/// any time, including while conversions are running.
class FilesPane extends ConsumerStatefulWidget {
  const FilesPane({super.key});

  @override
  ConsumerState<FilesPane> createState() => _FilesPaneState();
}

class _FilesPaneState extends ConsumerState<FilesPane> {
  bool _dragging = false;

  QueueController get _controller => ref.read(queueControllerProvider.notifier);

  Future<void> _pickFiles() async {
    final files = await openFiles(
      acceptedTypeGroups: [
        XTypeGroup(
          label: 'Video',
          extensions: [for (final e in videoExtensions) e.substring(1)],
        ),
      ],
    );
    await _controller.addPaths(files.map((f) => f.path));
  }

  Future<void> _pickFolder() async {
    final folder = await getDirectoryPath();
    if (folder != null) await _controller.addPaths([folder]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = ref.watch(queueControllerProvider.select((s) => s.items));

    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) {
        setState(() => _dragging = false);
        _controller.addPaths(details.files.map((f) => f.path));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _dragging
              ? scheme.primaryContainer.withValues(alpha: 0.5)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _dragging ? scheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: items.isEmpty
            ? _EmptyState(onAddFiles: _pickFiles, onAddFolder: _pickFolder)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(onAddFiles: _pickFiles, onAddFolder: _pickFolder),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: items.length,
                      onReorderItem: _controller.reorder,
                      itemBuilder: (context, index) => FileTile(
                        key: ValueKey(items[index].id),
                        item: items[index],
                        index: index,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddFiles, required this.onAddFolder});

  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library_rounded,
              size: 44,
              color: scheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.dropZoneTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dropZoneHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                onPressed: onAddFiles,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.addVideos),
              ),
              OutlinedButton.icon(
                onPressed: onAddFolder,
                icon: const Icon(Icons.folder_outlined),
                label: Text(l10n.addFolder),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.onAddFiles, required this.onAddFolder});

  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(queueControllerProvider);
    final format = Formatter(l10n);
    final totalBytes = state.items.fold<int>(
      0,
      (sum, item) => sum + (item.info?.sizeBytes ?? 0),
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.yourVideos,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${l10n.videoCount(state.items.length)}  ·  '
              '${format.bytes(totalBytes)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (state.hasFinished)
              TextButton(
                onPressed: ref
                    .read(queueControllerProvider.notifier)
                    .clearFinished,
                child: Text(l10n.clearFinished),
              ),
            TextButton.icon(
              onPressed: onAddFiles,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addVideos),
            ),
            TextButton.icon(
              onPressed: onAddFolder,
              icon: const Icon(Icons.folder_outlined),
              label: Text(l10n.addFolder),
            ),
          ],
        ),
      ],
    );
  }
}
