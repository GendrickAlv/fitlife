import 'package:material_ui/material_ui.dart';

/// Diálogo de confirmación (p. ej. para eliminar).
class ConfirmDialog {
  const ConfirmDialog._();

  /// Muestra el diálogo y devuelve true si el usuario confirma.
  static Future<bool> show(
    BuildContext context,
    String title,
    String message, {
    String confirmLabel = 'Eliminar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
