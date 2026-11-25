import 'package:material_ui/material_ui.dart';

/// Iconos y textos para la sensación (1–5) de una sesión.
class FeelingStyle {
  const FeelingStyle._();

  /// Icono de la sensación [value] (1–5).
  static IconData icon(int value) => switch (value) {
    1 => Icons.sentiment_very_dissatisfied,
    2 => Icons.sentiment_dissatisfied,
    3 => Icons.sentiment_neutral,
    4 => Icons.sentiment_satisfied,
    _ => Icons.sentiment_very_satisfied,
  };

  /// Descripción en español de la sensación [value].
  static String label(int value) => switch (value) {
    1 => 'Muy mal',
    2 => 'Mal',
    3 => 'Normal',
    4 => 'Bien',
    _ => 'Genial',
  };
}
