import 'package:flutter/material.dart';

const _seed = Color(0xFF4F46E5);

/// Colours for "this went well": finished files, files that need no work.
/// Material's colour scheme has no success role, so the app adds one.
class SuccessColors extends ThemeExtension<SuccessColors> {
  const SuccessColors({
    required this.text,
    required this.container,
    required this.onContainer,
  });

  static const light = SuccessColors(
    text: Color(0xFF17703A),
    container: Color(0xFFD3F3DC),
    onContainer: Color(0xFF0B4A24),
  );
  static const dark = SuccessColors(
    text: Color(0xFF7FDB9B),
    container: Color(0xFF14522C),
    onContainer: Color(0xFFC8F3D4),
  );

  /// For success text on an ordinary surface.
  final Color text;
  final Color container;
  final Color onContainer;

  static SuccessColors of(BuildContext context) =>
      Theme.of(context).extension<SuccessColors>()!;

  @override
  SuccessColors copyWith({Color? text, Color? container, Color? onContainer}) =>
      SuccessColors(
        text: text ?? this.text,
        container: container ?? this.container,
        onContainer: onContainer ?? this.onContainer,
      );

  @override
  SuccessColors lerp(SuccessColors? other, double t) {
    if (other == null) return this;
    return SuccessColors(
      text: Color.lerp(text, other.text, t)!,
      container: Color.lerp(container, other.container, t)!,
      onContainer: Color.lerp(onContainer, other.onContainer, t)!,
    );
  }
}

/// The app's look: soft rounded surfaces, large controls, one accent colour.
ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  final base = ThemeData(colorScheme: scheme, brightness: brightness);
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );
  // The typeface is taken from the theme's label style, but not its colour:
  // a colour here would override each button's own foreground colour.
  final label = base.textTheme.labelLarge!;
  final buttonText = TextStyle(
    fontFamily: label.fontFamily,
    fontFamilyFallback: label.fontFamilyFallback,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: label.letterSpacing,
  );

  return base.copyWith(
    extensions: [
      brightness == Brightness.dark ? SuccessColors.dark : SuccessColors.light,
    ],
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        shape: rounded,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: rounded,
        textStyle: buttonText.copyWith(fontSize: 15),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: rounded,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.standard,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(8),
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 500),
    ),
  );
}
