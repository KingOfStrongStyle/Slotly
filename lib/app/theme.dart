import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const maxContentWidth = 640.0;
}

@immutable
// Ян: свои цвета поверх Material 3: рейтинг, успех, графики. Палитру графиков
// проверял на дальтонизм, тёмная тема - отдельные оттенки, не инверсия
class SlotlyColors extends ThemeExtension<SlotlyColors> {
  const SlotlyColors({
    required this.rating,
    required this.success,
    required this.onSuccessContainer,
    required this.successContainer,
    required this.warning,
    required this.chart,
  });

  static const light = SlotlyColors(
    rating: Color(0xFFB7791F),
    success: Color(0xFF2E7D4F),
    successContainer: Color(0xFFD6F0DF),
    onSuccessContainer: Color(0xFF0D3B22),
    warning: Color(0xFFB45309),
    chart: [Color(0xFF2A78D6), Color(0xFFEB6834), Color(0xFF1BAF7A)],
  );

  static const dark = SlotlyColors(
    rating: Color(0xFFF2C14E),
    success: Color(0xFF7FD3A0),
    successContainer: Color(0xFF1D4B33),
    onSuccessContainer: Color(0xFFD6F0DF),
    warning: Color(0xFFF5A35C),
    chart: [Color(0xFF3987E5), Color(0xFFD95926), Color(0xFF199E70)],
  );

  final Color rating;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;

  final List<Color> chart;

  static SlotlyColors of(BuildContext context) =>
      Theme.of(context).extension<SlotlyColors>() ?? light;

  @override
  SlotlyColors copyWith({
    Color? rating,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    List<Color>? chart,
  }) => SlotlyColors(
    rating: rating ?? this.rating,
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    chart: chart ?? this.chart,
  );

  @override
  SlotlyColors lerp(SlotlyColors? other, double t) {
    if (other == null) return this;
    return SlotlyColors(
      rating: Color.lerp(rating, other.rating, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      chart: [
        for (var i = 0; i < chart.length; i++)
          Color.lerp(chart[i], other.chart[i], t)!,
      ],
    );
  }
}

abstract final class AppRadii {
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 28.0;
}

abstract final class AppTheme {
  static const seedColor = Color(0xFF0B6E69);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colors = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.m),
    );

    return ThemeData(
      colorScheme: colors,
      extensions: [
        if (brightness == Brightness.dark)
          SlotlyColors.dark
        else
          SlotlyColors.light,
      ],
      scaffoldBackgroundColor: colors.surface,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: colors.surface,
        scrolledUnderElevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.l),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: rounded,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: rounded,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.m),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.s),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: rounded,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.l),
      ),
    );
  }
}
