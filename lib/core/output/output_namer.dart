import 'package:path/path.dart' as p;

enum OutputMode {
  /// A folder next to each original (default "Converted").
  subfolderNextToSource,

  /// One folder the user chose for everything.
  customFolder,
}

class OutputSettings {
  const OutputSettings({
    this.mode = OutputMode.subfolderNextToSource,
    this.subfolderName = 'Converted',
    this.customDir,
  });

  final OutputMode mode;
  final String subfolderName;
  final String? customDir;
}

/// Picks where a converted file goes: `<folder>/<name><suffix>.<extension>`.
///
/// The result never names an existing file, the source itself, or a path in
/// [reserved] (outputs already promised to other files in the batch); a
/// counter is appended instead: `clip_resolve (2).mov`. Originals are
/// therefore never overwritten.
String planOutputPath({
  required String sourcePath,
  required OutputSettings settings,
  required String suffix,
  required String extension,
  required bool Function(String path) exists,
  Set<String> reserved = const {},
  p.Context? pathContext,
}) {
  final context = pathContext ?? p.context;
  final customDir = settings.customDir;
  final dir = settings.mode == OutputMode.customFolder && customDir != null
      ? customDir
      : context.join(context.dirname(sourcePath), settings.subfolderName);
  final stem = '${context.basenameWithoutExtension(sourcePath)}$suffix';

  bool taken(String path) =>
      context.equals(path, sourcePath) ||
      reserved.contains(path) ||
      exists(path);

  var candidate = context.join(dir, '$stem.$extension');
  for (var n = 2; taken(candidate); n++) {
    candidate = context.join(dir, '$stem ($n).$extension');
  }
  return candidate;
}

/// The name a file is written under while it is incomplete. It is renamed to
/// [finalPath] only once FFmpeg finished successfully, so a half-written file
/// can never be mistaken for a finished one.
String temporaryPathFor(String finalPath, {p.Context? pathContext}) {
  final context = pathContext ?? p.context;
  return context.join(
    context.dirname(finalPath),
    '.${context.basename(finalPath)}.part',
  );
}
