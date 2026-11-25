import 'package:material_ui/material_ui.dart';

import '../../core/utils/validators.dart';

/// Validadores numéricos compartidos por los formularios de rutinas e historial.
class FormRules {
  const FormRules._();

  /// Entero obligatorio entre [min] y [max].
  static FormFieldValidator<String> intInRange(int min, int max) {
    final range = Validators.numberInRange(min.toDouble(), max.toDouble());
    return (value) {
      final base = range(value);
      if (base != null) return base;
      final n = Validators.parseNumber(value)!;
      if (n != n.roundToDouble()) return 'Debe ser un número entero';
      return null;
    };
  }

  /// Número opcional (vacío válido) entre [min] y [max].
  static FormFieldValidator<String> optionalInRange(double min, double max) {
    final range = Validators.numberInRange(min, max);
    return (value) {
      if (value == null || value.trim().isEmpty) return null;
      return range(value);
    };
  }

  /// Entero opcional (vacío válido) entre [min] y [max].
  static FormFieldValidator<String> optionalIntInRange(int min, int max) {
    final inner = intInRange(min, max);
    return (value) {
      if (value == null || value.trim().isEmpty) return null;
      return inner(value);
    };
  }

  /// Formatea un número sin decimales superfluos (20.0 -> "20").
  static String num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();
}
