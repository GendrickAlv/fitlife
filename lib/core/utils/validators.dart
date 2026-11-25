/// Validadores para `TextFormField` (mensajes en español).
class Validators {
  const Validators._();

  /// Convierte texto con coma o punto decimal en número; null si no es válido.
  static double? parseNumber(String? value) {
    if (value == null) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  /// Campo obligatorio.
  static String? required(String? value, [String field = 'Este campo']) {
    if (value == null || value.trim().isEmpty) return '$field es obligatorio';
    return null;
  }

  /// Número estrictamente positivo.
  static String? positiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Introduce un número';
    final n = parseNumber(value);
    if (n == null) return 'Número no válido';
    if (n <= 0) return 'Debe ser mayor que 0';
    return null;
  }

  /// Número dentro de [min]..[max] (ambos incluidos).
  static FormFieldValidatorString numberInRange(double min, double max) {
    return (value) {
      if (value == null || value.trim().isEmpty) return 'Introduce un número';
      final n = parseNumber(value);
      if (n == null) return 'Número no válido';
      if (n < min || n > max) {
        return 'Debe estar entre ${_fmt(min)} y ${_fmt(max)}';
      }
      return null;
    };
  }

  /// Longitud máxima de [max] caracteres.
  static FormFieldValidatorString maxLength(int max) {
    return (value) {
      if (value != null && value.length > max) {
        return 'Máximo $max caracteres';
      }
      return null;
    };
  }

  static String _fmt(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toString().replaceAll('.', ',');
}

/// Firma de validador de texto.
typedef FormFieldValidatorString = String? Function(String? value);
