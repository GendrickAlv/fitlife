import 'package:material_ui/material_ui.dart';

/// Colores de marca y semánticos.
class AppColors {
  const AppColors._();

  static const seed = Color(0xFF00BFA6);
  static const water = Color(0xFF29B6F6);
  static const calories = Color(0xFFFF7043);
  static const steps = Color(0xFF66BB6A);
  static const weight = Color(0xFF7E57C2);
  static const minutes = Color(0xFF26A69A);
}

/// Temas claro y oscuro de la aplicación.
class AppTheme {
  const AppTheme._();

  /// Tema claro.
  static ThemeData get light => _build(Brightness.light);

  /// Tema oscuro.
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
