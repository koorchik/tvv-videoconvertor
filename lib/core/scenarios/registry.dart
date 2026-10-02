import 'compress.dart';
import 'resolve_linux.dart';
import 'scenario.dart';

/// Every scenario the app offers, in display order. This list is the single
/// place a new scenario has to be added.
const scenarios = <Scenario>[compressScenario, resolveLinuxScenario];

Preset? findPreset(String id) {
  for (final scenario in scenarios) {
    for (final preset in scenario.presets) {
      if (preset.id == id) return preset;
    }
  }
  return null;
}
