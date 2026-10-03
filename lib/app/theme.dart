import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Filled, tonal and outlined buttons share one height, so buttons placed
/// side by side line up.
const buttonHeight = 52.0;

/// The fixed-width font: commands, reports and, in the professional look,
/// technical captions.
const monoFontFamily = 'JetBrains Mono';

/// The looks the app comes in. The user picks one; the choice is remembered.
/// Both have the same layout and the same sizes; they differ in colour,
/// shape and lettering.
enum Look {
  /// Warm, light and rounded. The one the app starts with.
  cozy,

  /// Dark, flat and nearly square: the look of the camctrl app.
  pro,
}

/// A colour of the look together with its pale version: the first for an
/// icon or a line of small text, the second for the fill behind it.
class Hue {
  const Hue(this.deep, this.soft);

  /// Dark enough to read as small text on a row.
  final Color deep;
  final Color soft;

  static Hue lerp(Hue a, Hue b, double t) =>
      Hue(Color.lerp(a.deep, b.deep, t)!, Color.lerp(a.soft, b.soft, t)!);
}

/// The colours a colourful look tells kinds of thing apart with: one goal
/// from another, a picture track from a sound track, one icon from the next.
class Hues {
  const Hues({
    required this.orange,
    required this.violet,
    required this.blue,
    required this.amber,
    required this.green,
    required this.pink,
  });

  final Hue orange;
  final Hue violet;
  final Hue blue;
  final Hue amber;
  final Hue green;
  final Hue pink;

  /// The colour of the [index]th kind of a list, such as the goals in their
  /// order. Kinds beyond the last colour start again from the first.
  Hue at(int index) => [orange, violet, blue, amber, green, pink][index % 6];
}

/// What differs between the looks besides the colour scheme: how round
/// things are, how headings are written, and how much colour there is.
class AppLook extends ThemeExtension<AppLook> {
  const AppLook({
    required this.flat,
    required this.paneRadius,
    required this.panelRadius,
    required this.controlRadius,
    required this.tagRadius,
    required this.barRadius,
    required this.selectedBorderWidth,
    required this.capsHeadings,
    required this.monoCaptions,
    required this.badge,
    required this.waiting,
    required this.selectedRow,
    required this.jobGoal,
    required this.hues,
    required this.backdrop,
  });

  /// Surfaces are told apart by thin lines rather than by shadow and tint.
  final bool flat;

  /// The three panes and the windows that open over them.
  final double paneRadius;

  /// Rows, cards, and boxes of text.
  final double panelRadius;

  /// Buttons, segments, goal tiles, status marks.
  final double controlRadius;

  /// Tags and other small marks.
  final double tagRadius;

  /// Progress bars.
  final double barRadius;

  /// Border of what is selected or running. Everything else has 1.
  final double selectedBorderWidth;

  /// Pane titles and control labels in spaced capitals.
  final bool capsHeadings;

  /// Technical captions in the fixed-width font.
  final bool monoCaptions;

  /// Decorative icon marks where [hues] gives no colour: the empty list's
  /// icon, a missing thumbnail.
  final Hue badge;

  /// The mark of a job that is waiting its turn.
  final Hue waiting;

  /// Fill of a selected video's row.
  final Color selectedRow;

  /// The line of a queued job that names its goal, where [hues] gives the
  /// goal no colour of its own.
  final Color jobGoal;

  /// Null in a look that does not tell kinds apart by colour.
  final Hues? hues;

  /// Painted behind the panes; null leaves the plain window colour.
  final Gradient? backdrop;

  static AppLook of(BuildContext context) =>
      Theme.of(context).extension<AppLook>()!;

  @override
  AppLook copyWith({
    bool? flat,
    double? paneRadius,
    double? panelRadius,
    double? controlRadius,
    double? tagRadius,
    double? barRadius,
    double? selectedBorderWidth,
    bool? capsHeadings,
    bool? monoCaptions,
    Hue? badge,
    Hue? waiting,
    Color? selectedRow,
    Color? jobGoal,
    Hues? hues,
    Gradient? backdrop,
  }) => AppLook(
    flat: flat ?? this.flat,
    paneRadius: paneRadius ?? this.paneRadius,
    panelRadius: panelRadius ?? this.panelRadius,
    controlRadius: controlRadius ?? this.controlRadius,
    tagRadius: tagRadius ?? this.tagRadius,
    barRadius: barRadius ?? this.barRadius,
    selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
    capsHeadings: capsHeadings ?? this.capsHeadings,
    monoCaptions: monoCaptions ?? this.monoCaptions,
    badge: badge ?? this.badge,
    waiting: waiting ?? this.waiting,
    selectedRow: selectedRow ?? this.selectedRow,
    jobGoal: jobGoal ?? this.jobGoal,
    hues: hues ?? this.hues,
    backdrop: backdrop ?? this.backdrop,
  );

  /// Shapes and colours glide from one look to the other; lettering and the
  /// set of colours change halfway.
  @override
  AppLook lerp(AppLook? other, double t) {
    if (other == null) return this;
    final nearer = t < 0.5 ? this : other;
    return AppLook(
      flat: nearer.flat,
      paneRadius: lerpDouble(paneRadius, other.paneRadius, t)!,
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t)!,
      controlRadius: lerpDouble(controlRadius, other.controlRadius, t)!,
      tagRadius: lerpDouble(tagRadius, other.tagRadius, t)!,
      barRadius: lerpDouble(barRadius, other.barRadius, t)!,
      selectedBorderWidth: lerpDouble(
        selectedBorderWidth,
        other.selectedBorderWidth,
        t,
      )!,
      capsHeadings: nearer.capsHeadings,
      monoCaptions: nearer.monoCaptions,
      badge: Hue.lerp(badge, other.badge, t),
      waiting: Hue.lerp(waiting, other.waiting, t),
      selectedRow: Color.lerp(selectedRow, other.selectedRow, t)!,
      jobGoal: Color.lerp(jobGoal, other.jobGoal, t)!,
      hues: nearer.hues,
      backdrop: Gradient.lerp(backdrop, other.backdrop, t),
    );
  }
}

/// Colours for "this went well": finished files, files that need no work.
/// Material's colour scheme has no success role, so the app adds one.
class SuccessColors extends ThemeExtension<SuccessColors> {
  const SuccessColors({
    required this.text,
    required this.container,
    required this.onContainer,
  });

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

/// The cozy palette: bright warm surfaces, cocoa text, an orange accent,
/// and a handful of cheerful colours so that every goal, status and icon
/// has one of its own. Each deep colour reads as small text on white.
abstract final class _Cozy {
  static const window = Color(0xFFFFF1E2);
  static const pane = Color(0xFFFFFBF6);
  static const row = Color(0xFFFFFFFF);
  static const sand = Color(0xFFF6E7D6);
  static const line = Color(0xFFF1E0CD);
  static const outline = Color(0xFFD2BEA7);

  static const text = Color(0xFF3A2B22);
  static const textSoft = Color(0xFF7A6757);

  static const orange = Hue(Color(0xFFC84F0A), Color(0xFFFFE0CC));
  static const onOrangeSoft = Color(0xFF5F2100);
  static const violet = Hue(Color(0xFF7C4DDB), Color(0xFFECE3FD));
  static const blue = Hue(Color(0xFF1971C2), Color(0xFFDDEBFC));
  static const amber = Hue(Color(0xFFA66300), Color(0xFFFFEDBD));
  static const onAmberSoft = Color(0xFF4A3500);
  static const green = Hue(Color(0xFF237A35), Color(0xFFDAF2DE));
  static const onGreenSoft = Color(0xFF145224);
  static const pink = Hue(Color(0xFFC2327E), Color(0xFFFCE1EE));

  // For things worth noticing: a sample, HDR, a tag with personal data.
  static const teal = Hue(Color(0xFF0B7285), Color(0xFFD2F0F4));
  static const onTealSoft = Color(0xFF07505E);

  // A pinker red than the accent, so a failure is not taken for a button.
  static const crimson = Hue(Color(0xFFC92A4B), Color(0xFFFFE0E6));
  static const onCrimsonSoft = Color(0xFF7A0F27);

  // Peach to butter to mint, behind the panes.
  static const backdrop = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFE2D4), Color(0xFFFFF2D2), Color(0xFFE2F5E6)],
  );
}

/// The professional palette, the camctrl app's: near-black surfaces told
/// apart by small steps of grey, with one blue accent.
abstract final class _Pro {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF141414);
  static const controlSurface = Color(0xFF1E1E1E);
  static const controlSurfaceLight = Color(0xFF262626);
  static const border = Color(0xFF2A2A2A);
  static const inactive = Color(0xFF4F4F4F);

  static const textPrimary = Color(0xFFD4D4D4);
  static const textSecondary = Color(0xFF999999);

  static const accent = Color(0xFF4A90D9);
  static const accentDim = Color(0xFF2A5A8A);

  static const statusGreen = Color(0xFF2ECC40);
  static const warningAmber = Color(0xFFFF9500);

  // Lighter than a red that fills a shape would be: it is read as small
  // text on a dark surface.
  static const error = Color(0xFFFF5252);
  static const errorContainer = Color(0xFF3D1515);
  static const onErrorContainer = Color(0xFFFFB4AB);

  /// The fill of a tag or status mark in [color]: a little of the colour
  /// over the surface of the row it sits on.
  static Color tint(Color color) =>
      Color.alphaBlend(color.withValues(alpha: 0.15), controlSurface);

  // Grey on grey: this look keeps colour for what is chosen or active.
  static const quiet = Hue(textSecondary, controlSurfaceLight);
}

// Every role the widgets read is given in both schemes. A role left out
// would take Flutter's default, which belongs to a different palette.
//
// The surfaces, from the back: `surfaceContainerLowest` is the window (and
// boxes of commands and reports), `surfaceContainerLow` the panes and the
// windows over them, `surface` the rows and controls, and
// `surfaceContainerHighest` what sits on a row. `secondaryContainer` is the
// softer kind of filled button. `tertiary` is for things worth noticing: a
// sample, HDR, a tag with personal data.

final _cozyScheme = ColorScheme.light(
  primary: _Cozy.orange.deep,
  onPrimary: Colors.white,
  primaryContainer: _Cozy.orange.soft,
  onPrimaryContainer: _Cozy.onOrangeSoft,
  secondary: _Cozy.textSoft,
  onSecondary: Colors.white,
  secondaryContainer: _Cozy.amber.soft,
  onSecondaryContainer: _Cozy.onAmberSoft,
  tertiary: _Cozy.teal.deep,
  onTertiary: Colors.white,
  tertiaryContainer: _Cozy.teal.soft,
  onTertiaryContainer: _Cozy.onTealSoft,
  error: _Cozy.crimson.deep,
  onError: Colors.white,
  errorContainer: _Cozy.crimson.soft,
  onErrorContainer: _Cozy.onCrimsonSoft,
  surface: _Cozy.row,
  onSurface: _Cozy.text,
  onSurfaceVariant: _Cozy.textSoft,
  surfaceContainerLowest: _Cozy.window,
  surfaceContainerLow: _Cozy.pane,
  surfaceContainer: _Cozy.row,
  surfaceContainerHigh: _Cozy.sand,
  surfaceContainerHighest: _Cozy.sand,
  outline: _Cozy.outline,
  outlineVariant: _Cozy.line,
  surfaceTint: Colors.transparent,
  inverseSurface: _Cozy.text,
  onInverseSurface: _Cozy.pane,
  inversePrimary: _Cozy.orange.soft,
);

final _cozyLook = AppLook(
  flat: false,
  paneRadius: 24,
  panelRadius: 14,
  controlRadius: 14,
  tagRadius: 8,
  barRadius: 4,
  selectedBorderWidth: 1.5,
  capsHeadings: false,
  monoCaptions: false,
  badge: _Cozy.orange,
  waiting: _Cozy.blue,
  selectedRow: Color.alphaBlend(
    _Cozy.orange.soft.withValues(alpha: 0.5),
    _Cozy.row,
  ),
  jobGoal: _Cozy.orange.deep,
  hues: const Hues(
    orange: _Cozy.orange,
    violet: _Cozy.violet,
    blue: _Cozy.blue,
    amber: _Cozy.amber,
    green: _Cozy.green,
    pink: _Cozy.pink,
  ),
  backdrop: _Cozy.backdrop,
);

final _cozySuccess = SuccessColors(
  text: _Cozy.green.deep,
  container: _Cozy.green.soft,
  onContainer: _Cozy.onGreenSoft,
);

final _proScheme = ColorScheme.dark(
  primary: _Pro.accent,
  onPrimary: Colors.white,
  primaryContainer: _Pro.accentDim,
  onPrimaryContainer: Colors.white,
  secondary: _Pro.textSecondary,
  onSecondary: _Pro.background,
  secondaryContainer: _Pro.controlSurfaceLight,
  onSecondaryContainer: _Pro.textPrimary,
  tertiary: _Pro.warningAmber,
  onTertiary: _Pro.background,
  tertiaryContainer: _Pro.tint(_Pro.warningAmber),
  onTertiaryContainer: _Pro.warningAmber,
  error: _Pro.error,
  onError: Colors.white,
  errorContainer: _Pro.errorContainer,
  onErrorContainer: _Pro.onErrorContainer,
  surface: _Pro.controlSurface,
  onSurface: _Pro.textPrimary,
  onSurfaceVariant: _Pro.textSecondary,
  surfaceContainerLowest: _Pro.background,
  surfaceContainerLow: _Pro.surface,
  surfaceContainer: _Pro.controlSurface,
  surfaceContainerHigh: _Pro.controlSurfaceLight,
  surfaceContainerHighest: _Pro.controlSurfaceLight,
  outline: _Pro.inactive,
  outlineVariant: _Pro.border,
  surfaceTint: Colors.transparent,
  inverseSurface: _Pro.textPrimary,
  onInverseSurface: _Pro.surface,
  inversePrimary: _Pro.accentDim,
);

final _proLook = AppLook(
  flat: true,
  paneRadius: 3,
  panelRadius: 3,
  controlRadius: 2,
  tagRadius: 2,
  barRadius: 1,
  selectedBorderWidth: 1,
  capsHeadings: true,
  monoCaptions: true,
  badge: _Pro.quiet,
  waiting: _Pro.quiet,
  // Tinted rather than filled: often every row is selected, and a list of
  // solid colour would be heavy.
  selectedRow: Color.alphaBlend(
    _Pro.accentDim.withValues(alpha: 0.25),
    _Pro.controlSurface,
  ),
  // Not the accent: that is kept for what is active or can be pressed.
  jobGoal: _Pro.textSecondary,
  hues: null,
  backdrop: null,
);

final _proSuccess = SuccessColors(
  text: _Pro.statusGreen,
  container: _Pro.tint(_Pro.statusGreen),
  onContainer: _Pro.statusGreen,
);

ThemeData buildTheme(Look look) => switch (look) {
  Look.cozy => _theme(_cozyScheme, _cozyLook, _cozySuccess),
  Look.pro => _theme(_proScheme, _proLook, _proSuccess),
};

/// One theme for both looks, so every control has the same size in each:
/// the settings panel is laid out to fit without scrolling.
ThemeData _theme(ColorScheme scheme, AppLook look, SuccessColors success) {
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: 'Roboto',
    // Roboto has no arrow glyphs; the other bundled font does. Listing it
    // here keeps symbols from depending on what each computer has installed.
    fontFamilyFallback: const [monoFontFamily],
  );
  final hairline = BorderSide(color: scheme.outlineVariant);
  RoundedRectangleBorder rounded(double radius, {bool outlined = false}) =>
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: outlined ? hairline : BorderSide.none,
      );
  final control = rounded(look.controlRadius);
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
    extensions: [look, success],
    scaffoldBackgroundColor: scheme.surfaceContainerLowest,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: rounded(look.paneRadius, outlined: look.flat),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, buttonHeight),
        shape: control,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, buttonHeight),
        shape: control,
        side: look.flat ? hairline : null,
        textStyle: buttonText.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: control),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: control,
        side: look.flat ? hairline : BorderSide(color: scheme.outline),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        visualDensity: VisualDensity.compact,
      ),
    ),
    // In the flat look, on is green, as on the equipment that look comes
    // from: the accent is for what is chosen, green for what is switched on.
    switchTheme: look.flat
        ? SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? success.text
                  : scheme.outline,
            ),
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? success.text.withAlpha(80)
                  : scheme.surface,
            ),
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? success.text.withAlpha(40)
                  : scheme.outline,
            ),
          )
        : null,
    progressIndicatorTheme: ProgressIndicatorThemeData(
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(look.barRadius),
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    dialogTheme: DialogThemeData(
      elevation: look.flat ? 0 : null,
      backgroundColor: scheme.surfaceContainerLow,
      shape: rounded(look.paneRadius, outlined: look.flat),
    ),
    // What opens over the rows stands out by a shadow, or in the flat look
    // by being a step lighter than them.
    popupMenuTheme: PopupMenuThemeData(
      elevation: look.flat ? 0 : null,
      color: look.flat ? scheme.surfaceContainerHighest : scheme.surface,
      shape: rounded(
        look.flat ? look.controlRadius : look.panelRadius,
        outlined: look.flat,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: look.flat
            ? scheme.surfaceContainerHighest
            : scheme.inverseSurface,
        borderRadius: BorderRadius.circular(look.tagRadius),
        border: look.flat ? Border.all(color: scheme.outline) : null,
      ),
      textStyle: base.textTheme.bodySmall?.copyWith(
        color: look.flat ? scheme.onSurface : scheme.onInverseSurface,
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    scrollbarTheme: look.flat
        ? ScrollbarThemeData(
            thumbColor: WidgetStatePropertyAll(scheme.outline),
            radius: const Radius.circular(1),
          )
        : null,
  );
}
