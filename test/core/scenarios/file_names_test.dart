import 'package:flutter_test/flutter_test.dart';
import 'package:tvv_videoconvertor/core/ffmpeg/capabilities.dart';
import 'package:tvv_videoconvertor/core/scenarios/registry.dart';

import '../../support/fake_media.dart';

/// Output names carry the settings that matter, so results made from one
/// video with different settings can be told apart.
void main() {
  const cases = [
    ('compress.hevc', <String, String>{}, '_hevc-crf20'),
    ('compress.hevc', {'quality': 'maximum'}, '_hevc-crf18'),
    ('compress.av1', {'quality': 'compact'}, '_av1-crf29'),
    ('compress.gpu', <String, String>{}, '_av1-nvenc-cq28'),
    ('resolve.studio', <String, String>{}, '_resolve'),
    ('resolve.studio', {'convertVideo': 'yes'}, '_prores422'),
    ('resolve.free', <String, String>{}, '_prores422'),
    ('resolve.free', {'quality': 'best'}, '_prores-hq'),
    ('resolve.free', {'quality': 'smaller'}, '_prores-lt'),
    ('resolve.free', {'codec': 'dnxhr'}, '_dnxhr-hq'),
    ('resolve.free', {'quality': 'smallest'}, '_av1-nvenc-cq24'),
    ('share.phone', <String, String>{}, '_phone-1080p'),
    ('share.phone', {'size': 'small'}, '_phone-720p'),
    ('privacy.clean', <String, String>{}, '_clean'),
    ('privacy.clean', {'mode': 'thorough'}, '_clean-reencoded'),
    ('audio.extract', <String, String>{}, ''),
  ];
  final Capabilities capabilities = withGpu({'av1_nvenc'});

  for (final (presetId, values, suffix) in cases) {
    test('$presetId $values → "$suffix"', () {
      final plan = findPreset(presetId)!.plan(clip(), values, capabilities);

      expect(plan.nameSuffix, suffix);
    });
  }

  test('names are safe in any file system', () {
    for (final (presetId, values, _) in cases) {
      final suffix = findPreset(presetId)!
          .plan(clip(), values, capabilities)
          .nameSuffix;
      expect(suffix, matches(RegExp(r'^(_[a-z0-9-]+)?$')));
    }
  });

  test('HEVC on an Apple graphics chip names its quality scale', () {
    final plan = findPreset('compress.gpu')!
        .plan(clip(), const {}, withGpu({'hevc_videotoolbox'}));

    expect(plan.nameSuffix, '_hevc-videotoolbox-q65');
  });
}
