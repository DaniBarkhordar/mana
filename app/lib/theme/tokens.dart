/// Mananu's design system.
///
/// The product is an instrument, and the interface should feel like one:
/// quiet surfaces, one accent used sparingly, and numbers set in tabular
/// figures so a weight does not jitter horizontally as it climbs.
///
/// The category is saturated with mint-green and lilac wellness apps. Mananu is
/// deliberately warm graphite and brass — closer to a set of kitchen scales or a
/// measuring tool than to a meditation app.
///
/// One colour rule carries real product meaning: [MananuColors.measured] is used
/// ONLY for values that came off the scale, and [MananuColors.estimated] ONLY for
/// values that were guessed. That distinction is the whole proposition, so it
/// gets its own visual language rather than a footnote.
library;

import 'package:flutter/material.dart';

class MananuColors {
  const MananuColors._();

  // Neutrals — light
  static const ink = Color(0xFF0D1012);
  static const slate = Color(0xFF3B4247);
  /// 4.6:1 on [paper], so captions pass WCAG AA; the old 0xFF858D93 was 3.2:1.
  static const mist = Color(0xFF6B7378);
  static const line = Color(0xFFE4E2DC);
  static const surface = Color(0xFFFFFFFF);
  static const paper = Color(0xFFFAF9F5);

  // Neutrals — dark
  static const inkDark = Color(0xFF0A0C0D);
  static const surfaceDark = Color(0xFF16191B);
  static const surfaceRaisedDark = Color(0xFF1F2325);
  static const lineDark = Color(0xFF2C3134);
  static const mistDark = Color(0xFF8A9298);
  static const paperOnDark = Color(0xFFF2F1ED);

  /// Brand accent. Brass — an instrument colour, not a wellness colour.
  static const brass = Color(0xFFC8912F);
  static const brassBright = Color(0xFFE0A93F);
  static const brassSoft = Color(0xFFF6EDD8);

  /// Reserved for quantities that were physically weighed.
  static const measured = Color(0xFF1E7A5F);
  static const measuredSoft = Color(0xFFE3F1EC);

  /// Reserved for quantities that were estimated rather than measured.
  static const estimated = Color(0xFF9A7B4F);
  static const estimatedSoft = Color(0xFFF5EFE6);

  static const warning = Color(0xFFB4531E);
  static const danger = Color(0xFFB03A2E);

  // Macro series. Distinguishable in both themes and for the common forms of
  // colour vision deficiency: they differ in lightness as well as hue.
  static const protein = Color(0xFF2F6F8F);
  static const carbs = Color(0xFFC8912F);
  static const fat = Color(0xFF8A5A9B);
}

class MananuSpacing {
  const MananuSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 48;

  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(14));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(22));
}

/// Tabular figures everywhere a number can change.
///
/// Without this, a live weight climbing from 118 g to 119 g visibly shifts the
/// digits sideways, which on a scale readout looks broken.
const _tabular = <FontFeature>[FontFeature.tabularFigures()];

class MananuType {
  const MananuType._();

  /// Instrument Sans (SIL Open Font License; the licence ships in
  /// assets/fonts). Bundled so the type is the same on iOS and Android and
  /// matches the design canvas. Named on every style, not just the theme, so
  /// an app bar title or a button label set from these constants renders in
  /// it too.
  static const family = 'Instrument Sans';

  /// The live weight readout. Large, tabular. Instrument Sans has no light
  /// cut; the regular weight at this size reads as the design intends.
  static const readout = TextStyle(
    fontFamily: family,
    fontSize: 76,
    fontWeight: FontWeight.w400,
    letterSpacing: -2.5,
    height: 1.0,
    fontFeatures: _tabular,
  );

  static const display = TextStyle(
    fontFamily: family,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.0,
    height: 1.05,
    fontFeatures: _tabular,
  );

  static const title = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const heading = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const body = TextStyle(fontFamily: family, fontSize: 15, height: 1.45);

  static const bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w600,
  );

  static const caption =
      TextStyle(fontFamily: family, fontSize: 13, height: 1.35);

  /// Small all-caps label used for section headers and state badges.
  static const label = TextStyle(
    fontFamily: family,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.9,
  );

  static const number = TextStyle(
    fontFamily: family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );
}

class MananuTheme {
  const MananuTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? MananuColors.brassBright : MananuColors.brass,
      onPrimary: isDark ? MananuColors.inkDark : Colors.white,
      secondary: MananuColors.measured,
      onSecondary: Colors.white,
      error: MananuColors.danger,
      onError: Colors.white,
      surface: isDark ? MananuColors.surfaceDark : MananuColors.surface,
      onSurface: isDark ? MananuColors.paperOnDark : MananuColors.ink,
      surfaceContainerHighest:
          isDark ? MananuColors.surfaceRaisedDark : MananuColors.paper,
      outline: isDark ? MananuColors.lineDark : MananuColors.line,
      outlineVariant: isDark ? MananuColors.lineDark : MananuColors.line,
    );

    final onSurfaceMuted = isDark ? MananuColors.mistDark : MananuColors.mist;

    return ThemeData(
      useMaterial3: true,
      fontFamily: MananuType.family,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? MananuColors.inkDark : MananuColors.paper,
      splashFactory: InkSparkle.splashFactory,
      textTheme: TextTheme(
        displayLarge: MananuType.display.copyWith(color: scheme.onSurface),
        titleLarge: MananuType.title.copyWith(color: scheme.onSurface),
        titleMedium: MananuType.heading.copyWith(color: scheme.onSurface),
        bodyMedium: MananuType.body.copyWith(color: scheme.onSurface),
        bodySmall: MananuType.caption.copyWith(color: onSurfaceMuted),
        labelSmall: MananuType.label.copyWith(color: onSurfaceMuted),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? MananuColors.inkDark : MananuColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: MananuType.title.copyWith(color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: MananuSpacing.radiusMd,
          side: BorderSide(color: scheme.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: const RoundedRectangleBorder(
            borderRadius: MananuSpacing.radiusMd,
          ),
          textStyle: MananuType.bodyStrong,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: scheme.outline),
          shape: const RoundedRectangleBorder(
            borderRadius: MananuSpacing.radiusMd,
          ),
          textStyle: MananuType.bodyStrong,
        ),
      ),
      dividerTheme:
          DividerThemeData(color: scheme.outline, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor:
            isDark ? MananuColors.surfaceRaisedDark : MananuColors.brassSoft,
        labelTextStyle: WidgetStatePropertyAll(
          MananuType.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        height: 68,
      ),
    );
  }
}

/// Badge showing whether a value was weighed or estimated.
///
/// Used everywhere a quantity appears. Making the distinction visible on every
/// row is what stops the product drifting into the same "confident number of
/// unknown provenance" that the rest of the category ships.
class ProvenanceBadge extends StatelessWidget {
  const ProvenanceBadge({
    super.key,
    required this.weighed,
    this.label,
    this.dense = false,
  });

  final bool weighed;
  final String? label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = weighed ? MananuColors.measured : MananuColors.estimated;
    final bg = isDark
        ? fg.withValues(alpha: 0.18)
        : (weighed ? MananuColors.measuredSoft : MananuColors.estimatedSoft);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration:
          BoxDecoration(color: bg, borderRadius: MananuSpacing.radiusSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            weighed ? Icons.scale_outlined : Icons.blur_on,
            size: dense ? 11 : 13,
            color: isDark ? fg.withValues(alpha: 0.95) : fg,
          ),
          const SizedBox(width: 4),
          // Shrinks rather than overflowing in a narrow column.
          Flexible(
            child: Text(
              label ?? (weighed ? 'Weighed' : 'Estimated'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: MananuType.label.copyWith(
                color: isDark ? fg.withValues(alpha: 0.95) : fg,
                fontSize: dense ? 10 : 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card with a quiet section label above it.
class MananuSection extends StatelessWidget {
  const MananuSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MananuSpacing.xs,
            0,
            MananuSpacing.xs,
            MananuSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: MananuType.label.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        child,
      ],
    );
  }
}
