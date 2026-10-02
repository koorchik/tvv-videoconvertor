import 'package:flutter_test/flutter_test.dart';
import 'package:tvv_videoconvertor/core/ffmpeg/capabilities.dart';
import 'package:tvv_videoconvertor/core/media/media_info.dart';
import 'package:tvv_videoconvertor/core/scenarios/compress.dart';
import 'package:tvv_videoconvertor/core/scenarios/scenario.dart';

import '../../support/fake_media.dart';

void main() {
  ConversionPlan plan(
    CompressPreset preset,
    MediaInfo input, [
    OptionValues values = const {},
    Capabilities capabilities = softwareOnly,
  ]) => preset.plan(input, values, capabilities);

  VideoEncode video(ConversionPlan plan) => plan.video as VideoEncode;

  group('AV1', () {
    test('encodes 10-bit 4:2:0 into a fast-start MP4', () {
      final result = plan(CompressPreset.av1, clip());

      expect(result.kind, PlanKind.encode);
      expect(video(result).encoder, 'libsvtav1');
      expect(video(result).pixFmt, 'yuv420p10le');
      expect(result.muxer, 'mp4');
      expect(
        result.outputArgs,
        containsAllInOrder(['-movflags', '+faststart']),
      );
      expect(result.nameSuffix, '_av1');
    });

    const crfs = {'compact': '29', 'high': '25', 'maximum': '21'};
    crfs.forEach((quality, crf) {
      test('quality "$quality" encodes at CRF $crf', () {
        final result = plan(CompressPreset.av1, clip(), {'quality': quality});

        expect(video(result).args, containsAllInOrder(['-crf', crf]));
      });
    });

    test('uses the encoder parameters this SVT-AV1 version accepts', () {
      final result = plan(CompressPreset.av1, clip());

      expect(
        video(result).args,
        containsAllInOrder(['-svtav1-params', 'tune=0']),
      );
    });

    test('omits encoder parameters when the library accepts none', () {
      const bare = Capabilities(ffmpegVersion: 'test', encoders: {'libsvtav1'});
      final result = plan(CompressPreset.av1, clip(), const {}, bare);

      expect(video(result).args, isNot(contains('-svtav1-params')));
    });

    test('4:2:2 sources are reduced with an explicit Lanczos step', () {
      final result = plan(CompressPreset.av1, clip(pixFmt: 'yuv422p10le'));

      expect(video(result).filters, [
        'scale=flags=lanczos+accurate_rnd',
        'format=yuv420p10le',
      ]);
      expect(result.notes, contains(PlanNote.chromaReduced));
    });

    test('4:2:0 sources need no filter', () {
      expect(video(plan(CompressPreset.av1, clip())).filters, isEmpty);
    });
  });

  group('HEVC', () {
    test('is tagged so Apple players recognise it', () {
      final result = plan(CompressPreset.hevc, clip());

      expect(video(result).encoder, 'libx265');
      expect(video(result).args, containsAllInOrder(['-profile:v', 'main10']));
      expect(result.outputArgs, containsAllInOrder(['-tag:v', 'hvc1']));
      expect(result.nameSuffix, '_hevc');
    });
  });

  group('graphics card', () {
    test('prefers AV1 over HEVC when the card offers both', () {
      final caps = withGpu({'hevc_nvenc', 'av1_nvenc', 'h264_nvenc'});

      expect(CompressPreset.gpuEncoder(caps), 'av1_nvenc');
      expect(
        video(plan(CompressPreset.gpu, clip(), const {}, caps)).encoder,
        'av1_nvenc',
      );
    });

    test('uses HEVC on a card without AV1 encoding', () {
      final caps = withGpu({'hevc_nvenc', 'h264_nvenc'});
      final result = plan(CompressPreset.gpu, clip(), const {}, caps);

      expect(video(result).encoder, 'hevc_nvenc');
      expect(video(result).pixFmt, 'p010le');
      expect(result.outputArgs, containsAllInOrder(['-tag:v', 'hvc1']));
      expect(result.cost.usesGpuEncoder, isTrue);
    });

    test('is not offered without a working hardware encoder', () {
      expect(CompressPreset.gpuEncoder(softwareOnly), isNull);
    });

    test('Apple hardware gets its 0-100 quality scale', () {
      final caps = withGpu({'hevc_videotoolbox'});
      final result = plan(CompressPreset.gpu, clip(), {
        'quality': 'maximum',
      }, caps);

      expect(video(result).args, containsAllInOrder(['-q:v', '75']));
    });
  });

  group('audio', () {
    test('modest AAC is kept untouched', () {
      final result = plan(CompressPreset.av1, clip());

      expect(result.audio, isA<AudioCopy>());
    });

    test('PCM from an editor export becomes AAC', () {
      final result = plan(
        CompressPreset.av1,
        clip(audio: [track('pcm_s24le', bitRate: 2304000)]),
      );
      final audio = result.audio as AudioEncode;

      expect(audio.codec, 'aac');
      expect(audio.args, ['-b:a', '256k']);
    });

    test('surround sound gets a higher bitrate', () {
      final result = plan(
        CompressPreset.av1,
        clip(audio: [track('pcm_s24le', channels: 6)]),
      );

      expect((result.audio as AudioEncode).args, ['-b:a', '448k']);
    });
  });

  test('a file without a picture is not handled', () {
    final result = plan(CompressPreset.av1, clip(video: null));

    expect(result.kind, PlanKind.unsupported);
  });
}
