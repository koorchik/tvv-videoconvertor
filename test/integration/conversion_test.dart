@Tags(['ffmpeg'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tvv_videoconvertor/core/ffmpeg/capabilities.dart';
import 'package:tvv_videoconvertor/core/ffmpeg/command_builder.dart';
import 'package:tvv_videoconvertor/core/ffmpeg/runner.dart';
import 'package:tvv_videoconvertor/core/media/ffprobe.dart';
import 'package:tvv_videoconvertor/core/media/media_info.dart';
import 'package:tvv_videoconvertor/core/output/output_namer.dart';
import 'package:tvv_videoconvertor/core/queue/job_executor.dart';
import 'package:tvv_videoconvertor/core/scenarios/compress.dart';
import 'package:tvv_videoconvertor/core/scenarios/extract_audio.dart';
import 'package:tvv_videoconvertor/core/scenarios/remux.dart';
import 'package:tvv_videoconvertor/core/scenarios/resolve_linux.dart';
import 'package:tvv_videoconvertor/core/scenarios/scenario.dart';
import 'package:tvv_videoconvertor/core/scenarios/share_phone.dart';
import 'package:tvv_videoconvertor/core/scenarios/strip_metadata.dart';

import '../support/test_media.dart';

/// Labels a generated clip as HLG, the way a camera in HLG mode does.
const hlgTags =
    'setparams=color_primaries=bt2020:color_trc=arib-std-b67:'
    'colorspace=bt2020nc:range=tv';

/// Real conversions with the installed FFmpeg on generated clips.
void main() {
  TestMedia? media;
  late Capabilities capabilities;
  late Ffprobe ffprobe;
  late JobExecutor executor;

  setUpAll(() async {
    media = await TestMedia.create();
    if (media == null) return;
    capabilities = await CapabilityProbe(media!.paths.ffmpeg).detect();
    ffprobe = Ffprobe(media!.paths.ffprobe);
    executor = JobExecutor(FfmpegRunner(media!.paths.ffmpeg));
  });

  tearDownAll(() async => media?.dispose());

  bool unavailable() {
    if (media != null) return false;
    markTestSkipped('FFmpeg is not installed');
    return true;
  }

  ConversionJob jobFor(
    MediaInfo info,
    ConversionPlan plan, {
    SampleRange? sample,
  }) {
    return ConversionJob(
      input: info,
      plan: plan,
      sample: sample,
      outputPath: planOutputPath(
        sourcePath: info.path,
        settings: const OutputSettings(),
        suffix: plan.nameSuffix,
        extension: plan.extension,
        exists: (path) => File(path).existsSync(),
      ),
    );
  }

  /// Plans and runs [preset] on [source], returning the probed output.
  Future<MediaInfo> convert(
    Preset preset,
    String source, {
    OptionValues values = const {},
  }) async {
    final info = await ffprobe.probe(source);
    final plan = preset.plan(info, values, capabilities);
    expect(plan.producesOutput, isTrue, reason: 'plan was ${plan.kind}');
    final handle = await executor.start(jobFor(info, plan));
    final result = await handle.result;
    expect(
      result.status,
      ConversionStatus.done,
      reason: result.errorLines.join('\n'),
    );
    return ffprobe.probe(result.outputPath!);
  }

  List<String> leftovers() => media!.dir
      .listSync(recursive: true)
      .map((e) => p.basename(e.path))
      .where((name) => name.endsWith('.part'))
      .toList();

  group('Resolve Studio', () {
    test(
      'H.264 with AAC: picture copied bit for bit, audio becomes PCM',
      () async {
        if (unavailable()) return;
        final source = await media!.clip(
          'camera_h264.mp4',
          extra: ['-timecode', '01:00:00:00'],
        );

        final output = await convert(ResolveLinuxPreset.studio, source);

        expect(output.isMovFamily, isTrue);
        expect(p.extension(output.path), '.mov');
        expect(output.video!.codec, 'h264');
        expect(output.audio.single.codec, 'pcm_s24le');
        expect(
          await media!.videoFingerprint(output.path),
          await media!.videoFingerprint(source),
        );
        expect(output.duration.inMilliseconds, closeTo(2000, 60));
      },
    );

    test('timecode survives the move to MOV', () async {
      if (unavailable()) return;
      final source = await media!.clip(
        'timecode.mp4',
        extra: ['-timecode', '01:02:03:04'],
      );

      final output = await convert(ResolveLinuxPreset.studio, source);

      expect(
        await media!.streams(output.path, 'codec_tag_string'),
        contains('tmcd'),
      );
    });

    test('H.265 10-bit with PCM in a MOV is left alone', () async {
      if (unavailable()) return;
      final source = await media!.clip(
        'nikon_like.mov',
        video: [
          '-c:v',
          'libx265',
          '-preset',
          'ultrafast',
          '-x265-params',
          'log-level=error',
        ],
        pixFmt: 'yuv420p10le',
        audio: ['-c:a', 'pcm_s24le'],
      );
      final info = await ffprobe.probe(source);

      final plan = ResolveLinuxPreset.studio.plan(info, const {}, capabilities);

      expect(info.video!.bitDepth, 10);
      expect(plan.kind, PlanKind.skip);
    });

    test('AV1 with AAC lands in an MP4 with lossless audio', () async {
      if (unavailable()) return;
      final source = await media!.clip(
        'av1_aac.mp4',
        video: ['-c:v', 'libsvtav1', '-preset', '12'],
      );

      final output = await convert(ResolveLinuxPreset.studio, source);

      expect(p.extension(output.path), '.mp4');
      expect(output.video!.codec, 'av1');
      expect(output.audio.single.codec, 'flac');
    });
  });

  group('Resolve Free', () {
    test('H.264 becomes 10-bit ProRes 422 with PCM', () async {
      if (unavailable()) return;
      final source = await media!.clip('free_h264.mp4');

      final output = await convert(ResolveLinuxPreset.free, source);

      expect(output.video!.codec, 'prores');
      expect(output.video!.profile, 'Standard');
      expect(output.video!.pixFmt, 'yuv422p10le');
      expect(output.audio.single.codec, 'pcm_s24le');
    });

    test('DNxHR keeps a 10-bit source in 10-bit', () async {
      if (unavailable()) return;
      // DNxHR needs at least 256x120; HQX is the 10-bit 4:2:2 profile.
      final source = await media!.clip(
        'free_hevc10.mov',
        video: [
          '-c:v',
          'libx265',
          '-preset',
          'ultrafast',
          '-x265-params',
          'log-level=error',
        ],
        pixFmt: 'yuv420p10le',
        size: '1280x720',
      );

      final output = await convert(
        ResolveLinuxPreset.free,
        source,
        values: {'codec': 'dnxhr'},
      );

      expect(output.video!.codec, 'dnxhd');
      expect(output.video!.profile, 'DNXHR HQX');
      expect(output.video!.bitDepth, 10);
    });

    test('irregular frame timing becomes a constant rate', () async {
      if (unavailable()) return;
      // Dropping frames at random gives the uneven timing phones produce.
      final source = await media!.clip(
        'phone_vfr.mp4',
        rate: '30',
        seconds: 4,
        filters: [r"select='gt(random(0)\,0.35)'"],
        extra: ['-fps_mode', 'vfr'],
      );
      final info = await ffprobe.probe(source);
      expect(info.video!.isVariableFrameRate, isTrue);

      final output = await convert(ResolveLinuxPreset.free, source);

      expect(output.video!.isVariableFrameRate, isFalse);
      expect(output.video!.frameRate, closeTo(30, 0.1));
    });
  });

  group('Compress', () {
    test('AV1 output is 10-bit 4:2:0 in MP4 with AAC audio', () async {
      if (unavailable()) return;
      final source = await media!.clip(
        'export_422.mov',
        video: ['-c:v', 'prores_ks', '-profile:v', '2'],
        pixFmt: 'yuv422p10le',
        audio: ['-c:a', 'pcm_s24le'],
      );

      final output = await convert(CompressPreset.av1, source);

      expect(output.video!.codec, 'av1');
      expect(output.video!.pixFmt, 'yuv420p10le');
      expect(output.audio.single.codec, 'aac');
      expect(output.sizeBytes, lessThan(File(source).lengthSync()));
    });

    // The presets pass no colour arguments: FFmpeg is relied on to carry the
    // tags through. These tests are what holds it to that.
    for (final preset in <Preset>[
      CompressPreset.av1,
      CompressPreset.hevc,
      ResolveLinuxPreset.free,
    ]) {
      test('${preset.id} keeps the HLG colour tags of the source', () async {
        if (unavailable()) return;
        final source = await media!.clip(
          'hlg_${preset.id}.mov',
          video: [
            '-c:v',
            'libx265',
            '-preset',
            'ultrafast',
            '-x265-params',
            'log-level=error',
          ],
          pixFmt: 'yuv422p10le',
          filters: [hlgTags],
        );
        final input = await ffprobe.probe(source);
        expect(input.video!.color.isHdr, isTrue);

        final color = (await convert(preset, source)).video!.color;

        expect(color.primaries, 'bt2020');
        expect(color.transfer, 'arib-std-b67');
        expect(color.space, 'bt2020nc');
      });
    }

    test('HEVC output carries the tag Apple players need', () async {
      if (unavailable()) return;
      final source = await media!.clip('to_hevc.mp4');

      final output = await convert(CompressPreset.hevc, source);

      expect(output.video!.codec, 'hevc');
      expect(output.video!.bitDepth, 10);
      expect(
        await media!.streams(output.path, 'codec_tag_string'),
        contains('hvc1'),
      );
    });

    test('the graphics card preset works when a card is present', () async {
      if (unavailable()) return;
      if (CompressPreset.gpuEncoder(capabilities) == null) {
        markTestSkipped('no working hardware encoder on this machine');
        return;
      }
      final source = await media!.clip('to_gpu.mp4', size: '1280x720');

      final output = await convert(CompressPreset.gpu, source);

      expect(output.video!.bitDepth, 10);
      expect(output.video!.codec, anyOf('av1', 'hevc'));
    });
  });

  group('Screen recordings', () {
    test('every sound track of a multi-track MKV is converted', () async {
      if (unavailable()) return;
      // OBS records MKV with AAC and can write several sound tracks.
      final source = await media!.clip(
        'obs.mkv',
        extra: ['-map', '0:v', '-map', '1:a', '-map', '1:a'],
      );

      final output = await convert(ResolveLinuxPreset.studio, source);

      expect(output.audio.map((a) => a.codec), ['pcm_s24le', 'pcm_s24le']);
      expect(p.extension(output.path), '.mov');
    });
  });

  group('Send to a phone', () {
    test('a large HDR video becomes ordinary 1080p H.264', () async {
      if (unavailable()) return;
      final source = await media!.clip(
        'hdr_big.mov',
        video: [
          '-c:v',
          'libx265',
          '-preset',
          'ultrafast',
          '-x265-params',
          'log-level=error',
        ],
        pixFmt: 'yuv420p10le',
        size: '2560x1440',
        filters: [hlgTags],
      );

      final output = await convert(const SharePhonePreset(), source);

      expect(output.video!.codec, 'h264');
      expect(output.video!.pixFmt, 'yuv420p');
      expect(output.video!.width, 1920);
      expect(output.video!.height, 1080);
      expect(output.video!.color.transfer, 'bt709');
      expect(output.audio.single.codec, 'aac');
    });

    test('a portrait video keeps its shape', () async {
      if (unavailable()) return;
      final source = await media!.clip('portrait.mp4', size: '1440x2560');

      final output = await convert(const SharePhonePreset(), source);

      expect(output.video!.width, 1080);
      expect(output.video!.height, 1920);
    });
  });

  group('Get the sound', () {
    test('the sound track is copied into a file of its own', () async {
      if (unavailable()) return;
      final source = await media!.clip('with_sound.mp4');

      final output = await convert(const ExtractAudioPreset(), source);

      expect(p.extension(output.path), '.m4a');
      expect(output.video, isNull);
      expect(output.audio.single.codec, 'aac');
    });

    test('MP3 and WAV can be asked for', () async {
      if (unavailable()) return;
      final source = await media!.clip('to_mp3.mp4');

      final mp3 = await convert(
        const ExtractAudioPreset(),
        source,
        values: {'format': 'mp3'},
      );
      final wav = await convert(
        const ExtractAudioPreset(),
        source,
        values: {'format': 'wav'},
      );

      expect(mp3.audio.single.codec, 'mp3');
      expect(wav.audio.single.codec, 'pcm_s16le');
    });
  });

  group('Remove personal details', () {
    Future<String> cameraFile(String name) => media!.clip(
      name,
      extra: [
        '-timecode',
        '01:00:00:00',
        '-metadata',
        'title=Family trip',
        '-metadata',
        'artist=Jane Doe',
        '-metadata',
        'location=+50.4501+030.5234/',
        '-metadata',
        'make=Example Camera Co',
        '-metadata',
        'creation_time=2024-06-01T10:00:00Z',
        '-metadata:s:v',
        'handler_name=Camera Video',
      ],
    );

    test('quick: no details remain and the picture is bit-identical', () async {
      if (unavailable()) return;
      final source = await cameraFile('private.mp4');
      File(source).setLastModifiedSync(DateTime(2024, 6, 1, 12));
      final before = await ffprobe.probe(source);
      expect(before.tags, containsPair('title', 'Family trip'));

      final output = await convert(const StripMetadataPreset(), source);

      expect(
        output.tags.keys,
        everyElement(
          isIn(['major_brand', 'minor_version', 'compatible_brands']),
        ),
      );
      expect(await media!.streams(output.path, 'codec_type'), [
        'video',
        'audio',
      ]);
      final raw = await File(output.path).readAsBytes();
      final text = String.fromCharCodes(raw);
      for (final secret in [
        'Family trip',
        'Jane Doe',
        '50.4501',
        'Example Camera',
      ]) {
        expect(text, isNot(contains(secret)));
      }
      expect(
        await media!.videoFingerprint(output.path),
        await media!.videoFingerprint(source),
      );
      expect(
        File(output.path).lastModifiedSync(),
        isNot(DateTime(2024, 6, 1, 12)),
      );
    });

    test('a sideways phone video stays the right way up', () async {
      if (unavailable()) return;
      final upright = await media!.clip('phone.mp4');
      final rotated = media!.file('phone_rotated.mp4');
      await media!.ffmpeg([
        '-display_rotation',
        '90',
        '-i',
        upright,
        '-c',
        'copy',
        rotated,
      ]);
      final rotation = (await ffprobe.probe(rotated)).video!.rotation;
      expect(rotation, isNot(0));

      final output = await convert(const StripMetadataPreset(), rotated);

      expect(output.video!.rotation, rotation);
    });

    test('thorough: the picture is rebuilt and details are gone', () async {
      if (unavailable()) return;
      final source = await cameraFile('private_thorough.mp4');

      final output = await convert(
        const StripMetadataPreset(),
        source,
        values: {'mode': 'thorough'},
      );

      expect(output.tags.keys, isNot(contains('title')));
      expect(
        await media!.videoFingerprint(output.path),
        isNot(await media!.videoFingerprint(source)),
      );
    });
  });

  group('Change file type', () {
    test('MKV to MP4 moves the picture without re-encoding', () async {
      if (unavailable()) return;
      final source = await media!.clip('recording.mkv');

      final output = await convert(const RemuxPreset(), source);

      expect(p.extension(output.path), '.mp4');
      expect(output.isMovFamily, isTrue);
      expect(
        await media!.videoFingerprint(output.path),
        await media!.videoFingerprint(source),
      );
    });
  });

  group('Job handling', () {
    test('the output takes the date of the original', () async {
      if (unavailable()) return;
      final source = await media!.clip('dated.mp4');
      final shot = DateTime(2024, 6, 1, 12);
      File(source).setLastModifiedSync(shot);

      final output = await convert(ResolveLinuxPreset.studio, source);

      expect(File(output.path).lastModifiedSync(), shot);
    });

    test('progress reaches 100% and reports a size', () async {
      if (unavailable()) return;
      final source = await media!.clip('progress.mp4', seconds: 3);
      final info = await ffprobe.probe(source);
      final plan = ResolveLinuxPreset.free.plan(info, const {}, capabilities);
      final handle = await executor.start(jobFor(info, plan));
      final updates = await handle.progress.toList();
      await handle.result;

      expect(updates, isNotEmpty);
      expect(updates.last.fraction, 1.0);
      expect(updates.last.currentBytes, greaterThan(0));
    });

    test('a sample has the requested length and the real settings', () async {
      if (unavailable()) return;
      final source = await media!.clip('long.mp4', seconds: 6);
      final info = await ffprobe.probe(source);
      final plan = CompressPreset.hevc.plan(info, const {}, capabilities);
      final handle = await executor.start(
        jobFor(
          info,
          plan,
          sample: const SampleRange(
            start: Duration(seconds: 2),
            length: Duration(seconds: 2),
          ),
        ),
      );
      final result = await handle.result;
      final sample = await ffprobe.probe(result.outputPath!);

      expect(sample.duration.inMilliseconds, closeTo(2000, 100));
      expect(sample.video!.codec, 'hevc');
      expect(sample.video!.pixFmt, 'yuv420p10le');
    });

    test('cancelling stops quickly and leaves no file behind', () async {
      if (unavailable()) return;
      final source = await media!.clip(
        'to_cancel.mp4',
        seconds: 30,
        size: '1280x720',
      );
      final info = await ffprobe.probe(source);
      // Software AV1 at this size takes long enough to be interrupted.
      final plan = CompressPreset.av1.plan(info, {
        'quality': 'maximum',
      }, capabilities);
      final job = jobFor(info, plan);
      final handle = await executor.start(job);
      await handle.progress.first;

      final stopwatch = Stopwatch()..start();
      await handle.cancel();
      final result = await handle.result;

      expect(result.status, ConversionStatus.cancelled);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 10)));
      expect(File(job.outputPath).existsSync(), isFalse);
      expect(leftovers(), isEmpty);
    });

    test('a broken input fails with a reason and leaves no file', () async {
      if (unavailable()) return;
      final source = await media!.clip('to_break.mp4');
      final info = await ffprobe.probe(source);
      final plan = ResolveLinuxPreset.free.plan(info, const {}, capabilities);
      final job = jobFor(info, plan);
      // The file is replaced after it was probed, as if a card was pulled out.
      File(source).writeAsStringSync('not a video');

      final handle = await executor.start(job);
      final result = await handle.result;

      expect(result.status, ConversionStatus.failed);
      expect(result.errorLines, isNotEmpty);
      expect(File(job.outputPath).existsSync(), isFalse);
      expect(leftovers(), isEmpty);
    });

    test('pausing halts progress and resuming finishes the job', () async {
      if (unavailable()) return;
      if (Platform.isWindows) {
        markTestSkipped('pause is not implemented on Windows yet');
        return;
      }
      final source = await media!.clip(
        'to_pause.mp4',
        seconds: 20,
        size: '1280x720',
      );
      final info = await ffprobe.probe(source);
      final plan = CompressPreset.hevc.plan(info, const {}, capabilities);
      final handle = await executor.start(jobFor(info, plan));
      var updates = 0;
      handle.progress.listen((_) => updates++);
      await handle.progress.first;

      expect(handle.pause(), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final whilePaused = updates;
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(updates, whilePaused);

      expect(handle.resume(), isTrue);
      final result = await handle.result;
      expect(result.status, ConversionStatus.done);
    });
  });

  group('Capability probe', () {
    test('finds the software encoders the presets rely on', () async {
      if (unavailable()) return;

      expect(
        capabilities.encoders,
        containsAll(['libsvtav1', 'libx265', 'libx264', 'prores_ks', 'dnxhd']),
      );
      expect(capabilities.ffmpegVersion, isNot('unknown'));
    });

    test('settles on SVT-AV1 parameters the library accepts', () async {
      if (unavailable()) return;

      expect(svtAv1ParamCandidates, contains(capabilities.svtAv1Params));
    });
  });
}
