import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/media/media_details.dart';
import '../../../l10n/app_localizations.dart';

enum _View { encoding, metadata, report }

/// Everything known about a video file, in three views: how it is encoded,
/// every metadata tag, and FFmpeg's full report.
class MediaDetailsDialog extends StatefulWidget {
  const MediaDetailsDialog({super.key, required this.title, required this.raw});

  /// Usually the file name.
  final String title;

  /// ffprobe's report (`MediaInfo.raw`).
  final Map<String, Object?> raw;

  @override
  State<MediaDetailsDialog> createState() => _MediaDetailsDialogState();
}

class _MediaDetailsDialogState extends State<MediaDetailsDialog> {
  var _view = _View.encoding;
  var _copied = false;

  static const _mono = TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: (MediaQuery.sizeOf(context).width - 120).clamp(320, 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SegmentedButton<_View>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _View.encoding,
                      label: Text(l10n.detailsViewEncoding),
                    ),
                    ButtonSegment(
                      value: _View.metadata,
                      label: Text(l10n.detailsViewMetadata),
                    ),
                    ButtonSegment(
                      value: _View.report,
                      label: Text(l10n.detailsViewReport),
                    ),
                  ],
                  selected: {_view},
                  onSelectionChanged: (value) => setState(() {
                    _view = value.first;
                    _copied = false;
                  }),
                ),
                const Spacer(),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _text(l10n)));
                    if (mounted) setState(() => _copied = true);
                  },
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                  ),
                  label: Text(_copied ? l10n.copied : l10n.copy),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(child: _content(l10n, theme)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _content(AppLocalizations l10n, ThemeData theme) {
    switch (_view) {
      case _View.report:
        return SelectableText(fullReport(widget.raw), style: _mono);
      case _View.encoding:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in encodingDetails(widget.raw))
              _Section(
                title: groupTitle(l10n, section.group, section.number),
                rows: [
                  for (final row in section.rows)
                    (fieldLabel(l10n, row.field), rowValue(l10n, row)),
                ],
              ),
          ],
        );
      case _View.metadata:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in metadataDetails(widget.raw))
              _Section(
                title: section.group == DetailGroup.chapters
                    ? l10n.groupChapter(section.number)
                    : groupTitle(l10n, section.group, section.number),
                rows: [
                  for (final entry in section.tags.entries)
                    (entry.key, entry.value),
                ],
                keysAreTechnical: true,
                empty: l10n.noTags,
              ),
          ],
        );
    }
  }

  /// The current view as plain text, for copying.
  String _text(AppLocalizations l10n) {
    final buffer = StringBuffer();
    void section(String title, Iterable<(String, String)> rows) {
      buffer.writeln(title);
      for (final (label, value) in rows) {
        buffer.writeln('  $label: $value');
      }
      buffer.writeln();
    }

    switch (_view) {
      case _View.report:
        return fullReport(widget.raw);
      case _View.encoding:
        for (final s in encodingDetails(widget.raw)) {
          section(groupTitle(l10n, s.group, s.number), [
            for (final row in s.rows)
              (fieldLabel(l10n, row.field), rowValue(l10n, row)),
          ]);
        }
      case _View.metadata:
        for (final s in metadataDetails(widget.raw)) {
          section(
            s.group == DetailGroup.chapters
                ? l10n.groupChapter(s.number)
                : groupTitle(l10n, s.group, s.number),
            [for (final e in s.tags.entries) (e.key, e.value)],
          );
        }
    }
    return buffer.toString().trimRight();
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.rows,
    this.keysAreTechnical = false,
    this.empty,
  });

  final String title;
  final List<(String, String)> rows;

  /// Tag names are shown as written in the file, in the fixed-width font.
  final bool keysAreTechnical;

  /// Shown when there are no rows.
  final String? empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          if (rows.isEmpty && empty != null)
            Text(
              empty!,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      label,
                      style: keysAreTechnical
                          ? const TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 12.5,
                            ).copyWith(color: muted)
                          : theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      value,
                      style: theme.textTheme.bodyMedium,
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

String groupTitle(AppLocalizations l10n, DetailGroup group, int number) =>
    switch (group) {
      DetailGroup.file => l10n.groupFile,
      DetailGroup.video => l10n.groupVideo(number),
      DetailGroup.audio => l10n.groupAudio(number),
      DetailGroup.subtitle => l10n.groupSubtitle(number),
      DetailGroup.timecode => l10n.groupTimecode,
      DetailGroup.data => l10n.groupData(number),
      DetailGroup.attachment => l10n.groupAttachment(number),
      DetailGroup.chapters => l10n.groupChapters,
    };

String fieldLabel(AppLocalizations l10n, DetailField field) => switch (field) {
  DetailField.container => l10n.fieldContainer,
  DetailField.size => l10n.fieldSize,
  DetailField.duration => l10n.fieldDuration,
  DetailField.bitrate => l10n.fieldBitrate,
  DetailField.tracks => l10n.fieldTracks,
  DetailField.codec => l10n.fieldCodec,
  DetailField.resolution => l10n.fieldResolution,
  DetailField.aspectRatio => l10n.fieldAspectRatio,
  DetailField.frameRate => l10n.fieldFrameRate,
  DetailField.bitDepth => l10n.fieldBitDepth,
  DetailField.chroma => l10n.fieldChroma,
  DetailField.pixelFormat => l10n.fieldPixelFormat,
  DetailField.colorPrimaries => l10n.fieldColorPrimaries,
  DetailField.colorTransfer => l10n.fieldColorTransfer,
  DetailField.colorMatrix => l10n.fieldColorMatrix,
  DetailField.colorRange => l10n.fieldColorRange,
  DetailField.hdr => l10n.fieldHdr,
  DetailField.masteringDisplay => l10n.fieldMasteringDisplay,
  DetailField.lightLevel => l10n.fieldLightLevel,
  DetailField.scanType => l10n.fieldScanType,
  DetailField.rotation => l10n.fieldRotation,
  DetailField.frames => l10n.fieldFrames,
  DetailField.channels => l10n.fieldChannels,
  DetailField.sampleRate => l10n.fieldSampleRate,
  DetailField.sampleFormat => l10n.fieldSampleFormat,
  DetailField.language => l10n.fieldLanguage,
  DetailField.title => l10n.fieldTitle,
  DetailField.defaultTrack => l10n.fieldDefaultTrack,
  DetailField.timecode => l10n.fieldTimecode,
  DetailField.fileName => l10n.fieldFileName,
  DetailField.chapter => l10n.fieldChapter,
};

/// The translated word, if any, followed by the technical value.
String rowValue(AppLocalizations l10n, DetailRow row) {
  final note = switch (row.note) {
    DetailNote.variable => l10n.noteVariable,
    DetailNote.progressive => l10n.noteProgressive,
    DetailNote.interlaced => l10n.noteInterlaced,
    DetailNote.notStated => l10n.noteNotStated,
    DetailNote.yes => l10n.noteYes,
    DetailNote.no => l10n.noteNo,
    null => null,
  };
  return [?note, if (row.value.isNotEmpty) row.value].join(': ');
}
