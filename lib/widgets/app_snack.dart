import 'package:material_ui/material_ui.dart';

/// Atajos para SnackBars.
class AppSnack {
  const AppSnack._();

  /// Mensaje de éxito.
  static void success(BuildContext context, String message) =>
      _show(context, message, Icons.check_circle_outline, isError: false);

  /// Mensaje de error.
  static void error(BuildContext context, String message) =>
      _show(context, message, Icons.error_outline, isError: true);

  /// Mensaje con acción (p. ej. "Deshacer").
  static void action(
    BuildContext context,
    String message, {
    required String label,
    required VoidCallback onPressed,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(label: label, onPressed: onPressed),
        ),
      );
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon, {
    required bool isError,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final fg = isError ? scheme.onErrorContainer : scheme.onPrimaryContainer;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError
              ? scheme.errorContainer
              : scheme.primaryContainer,
          content: Row(
            children: [
              Icon(icon, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: fg)),
              ),
            ],
          ),
        ),
      );
  }
}
