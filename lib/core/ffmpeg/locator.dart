import 'dart:io';

import 'package:path/path.dart' as p;

class FfmpegPaths {
  const FfmpegPaths({required this.ffmpeg, required this.ffprobe});

  final String ffmpeg;
  final String ffprobe;
}

/// Finds the FFmpeg and ffprobe executables to use.
///
/// Order: a folder the user configured, then the copy shipped inside the app
/// bundle, then whatever is on `PATH`. The bundled copy is the supported one;
/// `PATH` is the fallback for development, where nothing is bundled yet.
class FfmpegLocator {
  FfmpegLocator({
    String? executableDir,
    Map<String, String>? environment,
    bool? isWindows,
    bool Function(String path)? exists,
  }) : _executableDir = executableDir ?? p.dirname(Platform.resolvedExecutable),
       _environment = environment ?? Platform.environment,
       _isWindows = isWindows ?? Platform.isWindows,
       _exists = exists ?? ((path) => File(path).existsSync());

  final String _executableDir;
  final Map<String, String> _environment;
  final bool _isWindows;
  final bool Function(String path) _exists;

  FfmpegPaths? locate({String? overrideDir}) {
    final context = _isWindows ? p.windows : p.posix;
    final candidates = [
      ?overrideDir,
      // Linux bundle: <bundle>/lib/ffmpeg next to the app binary.
      context.join(_executableDir, 'lib', 'ffmpeg'),
      // Windows: next to the .exe. macOS: Contents/MacOS.
      _executableDir,
      ...(_environment['PATH'] ?? '')
          .split(_isWindows ? ';' : ':')
          .where((dir) => dir.isNotEmpty),
    ];
    final suffix = _isWindows ? '.exe' : '';
    for (final dir in candidates) {
      final ffmpeg = context.join(dir, 'ffmpeg$suffix');
      final ffprobe = context.join(dir, 'ffprobe$suffix');
      if (_exists(ffmpeg) && _exists(ffprobe)) {
        return FfmpegPaths(ffmpeg: ffmpeg, ffprobe: ffprobe);
      }
    }
    return null;
  }
}
